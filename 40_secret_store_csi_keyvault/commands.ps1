# Using Secrets Store CSI driver with Workload Identity

# Use case: AKS Pod wants to access Secret in Key Vault

# create an AKS cluster

$AKS_RG="rg-aks-csi-akv"
$AKS_NAME="aks-cluster"

az group create -n $AKS_RG -l westeurope

az aks create -g $AKS_RG -n $AKS_NAME `
              --kubernetes-version "1.25.2" `
              --enable-managed-identity `
              --node-count 2 `
              --network-plugin azure `
              --enable-addons azure-keyvault-secrets-provider `
              --enable-secret-rotation `
              --rotation-poll-interval 5m `
              --enable-oidc-issuer `
              --enable-workload-identity

az aks get-credentials --name $AKS_NAME -g $AKS_RG --overwrite-existing

# verify connection to the cluster
kubectl get nodes

$AKS_OIDC_ISSUER=$(az aks show -n $AKS_NAME -g $AKS_RG --query "oidcIssuerProfile.issuerUrl" -otsv)
echo $AKS_OIDC_ISSUER

kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver, secrets-store-provider-azure)'

az aks show -n $AKS_NAME -g $AKS_RG --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv
# we won't use this (default) managed identity, we'll use our own

# create Keyvault resource with RBAC mode and assign RBAC role for admin

$AKV_NAME="akv4aks4app0135"
az keyvault create -n $AKV_NAME -g $AKS_RG --enable-rbac-authorization

$AKV_ID=$(az keyvault show -n $AKV_NAME -g $AKS_RG --query id -o tsv)
echo $AKV_ID

$CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)
echo $CURRENT_USER_ID

az role assignment create --assignee $CURRENT_USER_ID `
        --role "Key Vault Administrator" `
        --scope $AKV_ID

# create keyvault secret

$AKV_SECRET_NAME="MySecretPassword"

az keyvault secret set --vault-name $AKV_NAME --name $AKV_SECRET_NAME --value "P@ssw0rd123!"

# create user managed identity resource

$IDENTITY_NAME="user-identity-aks-4-akv"

az identity create -g $AKS_RG -n $IDENTITY_NAME

$IDENTITY_ID=$(az identity show -g $AKS_RG -n $IDENTITY_NAME --query "id" -o tsv)
echo $IDENTITY_ID

$IDENTITY_CLIENT_ID=$(az identity show -g $AKS_RG -n $IDENTITY_NAME --query "clientId" -o tsv)
echo $IDENTITY_CLIENT_ID

# assign RBAC role to user managed identity for Keyvault's secret

az role assignment create --assignee $IDENTITY_CLIENT_ID `
        --role "Key Vault Secrets User" `
        --scope $AKV_ID

sleep 60 # wait for role propagation

# create service account for user managed identity

$NAMESPACE_APP="app-07" # can be changed to namespace of your workload

kubectl create namespace $NAMESPACE_APP

$SERVICE_ACCOUNT_NAME="workload-identity-sa"

@"
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: $IDENTITY_CLIENT_ID
  labels:
    azure.workload.identity/use: "true"
  name: $SERVICE_ACCOUNT_NAME
"@ > service-account.yaml

kubectl apply -f service-account.yaml --namespace $NAMESPACE_APP

# configure identity federation

$FEDERATED_IDENTITY_NAME="aks-federated-identity-app"

az identity federated-credential create -n $FEDERATED_IDENTITY_NAME `
            -g $AKS_RG `
            --identity-name $IDENTITY_NAME `
            --issuer $AKS_OIDC_ISSUER `
            --subject system:serviceaccount:${NAMESPACE_APP}:${SERVICE_ACCOUNT_NAME}

# configure secret provider class to get secret from Keyvault and to use user managed identity

$TENANT_ID=$(az account list --query "[?isDefault].tenantId" -o tsv)
echo $TENANT_ID

$SECRET_PROVIDER_CLASS="akv-spc-app"

@"
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: $SECRET_PROVIDER_CLASS # needs to be unique per namespace
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "false"
    clientID: "${IDENTITY_CLIENT_ID}"  # Setting this to use workload identity
    keyvaultName: ${AKV_NAME}         # Set to the name of your key vault
    cloudName: "AzurePublicCloud"
    objects:  |
      array:
        - |
          objectName: $AKV_SECRET_NAME
          objectType: secret  # object types: secret, key, or cert
          objectVersion: ""   # [OPTIONAL] object versions, default to latest if empty
    tenantId: "${TENANT_ID}"  # The tenant ID of the key vault
"@ > secretProviderClass.yaml

kubectl apply -f secretProviderClass.yaml -n $NAMESPACE_APP

kubectl get secretProviderClass -n $NAMESPACE_APP

# test with sample app

@"
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx-deploy
  name: nginx-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-deploy
  template:
    metadata:
      labels:
        app: nginx-deploy
    spec:
      serviceAccountName: $SERVICE_ACCOUNT_NAME
      containers:
      - image: nginx
        name: nginx
        volumeMounts:
        - name: secrets-store-inline
          mountPath: "/mnt/secrets-store"
          readOnly: true
      volumes:
        - name: secrets-store-inline
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: $SECRET_PROVIDER_CLASS
"@ > nginx-pod.yaml

kubectl apply -f nginx-pod.yaml -n $NAMESPACE_APP

sleep 5

kubectl get pods -n $NAMESPACE_APP

$POD_NAME=$(kubectl get pod -l app=nginx-deploy -o jsonpath="{.items[0].metadata.name}" -n $NAMESPACE_APP)
echo $POD_NAME

# and finally, here we can see the password

kubectl exec -it $POD_NAME -n $NAMESPACE_APP -- ls /mnt/secrets-store

kubectl exec -it $POD_NAME -n $NAMESPACE_APP -- cat /mnt/secrets-store/$AKV_SECRET_NAME