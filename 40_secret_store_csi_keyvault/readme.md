## Using Secrets Store CSI driver with Workload Identity  

## Introduction  

Kubernetes can save secrets into Secret object. But this object is not encrypted. It is just encoded using base64, which is not secure.

The Azure Key Vault Provider for Secrets Store CSI Driver allows for the integration of an Azure key vault as a secret store with an Azure Kubernetes Service (AKS) cluster via a CSI volume.

The Pod will be able to retrieve the secret from the Secret Store CSI volume, which a secure volume.
That volume is mounted to the pod and only that pod can access that volume.

Secret Store CSI driver uses 5 options to connect to keyvault:
1. Service Principal (SPN)
2. System Managed Identity attached to the VMSS (Nodepool)
3. User Managed Identity attached to the VMSS (Nodepool)
4. User Managed Identity attached to the VMSS (Nodepool) with Pod Identity
5. Workload Identity with Service Account

In this lab, we'll do the following:

1. Create an AKS cluster with Secret Store CSI driiver and Workload Identity
2. Verify connection to the cluster
3. Create Keyvault resource with RBAC mode and assign RBAC role for admin
4. Create keyvault secret
5. Create user managed identity resource
6. Assign RBAC role to user managed identity for Keyvault's secret
7. Create service account for user managed identity
8. Configure identity federation
9. Configure secret provider class to get secret from Keyvault and to use user managed identity
10. Test access to Secret in keyvault with sample deployment

<img src="media/Secret Store CSI with Workload Identity.png">

## 1. Create an AKS cluster with Secret Store CSI driiver and Workload Identity

```powershell
$AKS_RG="rg-aks-demo"
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
```

## 2. Verify connection to the cluster

```powershell
kubectl get nodes
# NAME                                STATUS   ROLES   AGE   VERSION
# aks-nodepool1-32570680-vmss000000   Ready    agent   15m   v1.25.2
# aks-nodepool1-32570680-vmss000001   Ready    agent   15m   v1.25.2

$AKS_OIDC_ISSUER=$(az aks show -n $AKS_NAME -g $AKS_RG --query "oidcIssuerProfile.issuerUrl" -otsv)
echo $AKS_OIDC_ISSUER
# https://westeurope.oic.prod-aks.azure.com/16b3c013-d300-468d-ac64-7eda0820b6d3/ecd4fd6e-0e43-4400-80dd-8587bdf47526/

kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver, secrets-store-provider-azure)'
# NAME                                     READY   STATUS    RESTARTS   AGE
# aks-secrets-store-csi-driver-knhnr       3/3     Running   0          24m
# aks-secrets-store-csi-driver-mpd6q       3/3     Running   0          24m
# aks-secrets-store-provider-azure-4ckgq   1/1     Running   0          24m
# aks-secrets-store-provider-azure-88snb   1/1     Running   0          24m

az aks show -n $AKS_NAME -g $AKS_RG --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv
# 36bcdfa5-fcd8-4bfe-b735-2d4e576efc3d
```

Installing the Secret Store CSI driver will create a Managed Identity. We won't use this (default) managed identity, we'll use our own.

## 3. Create Keyvault resource with RBAC mode and assign RBAC role for admin

```powershell
$AKV_NAME="akv4aks4app079"

az keyvault create -n $AKV_NAME -g $AKS_RG --enable-rbac-authorization

$AKV_ID=$(az keyvault show -n $AKV_NAME -g $AKS_RG --query id -o tsv)
echo $AKV_ID
# /subscriptions/82f6d75e-85f4-xxxxx-xxx-5dddd9fa8910/resourceGroups/rg-aks-demo-kv/providers/Microsoft.KeyVault/vaults/akv4aks4app017

$CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)
echo $CURRENT_USER_ID
# 99b281c9-823c-4633-af92-8ac556a19bee

az role assignment create --assignee $CURRENT_USER_ID `
        --role "Key Vault Administrator" `
        --scope $AKV_ID
```

## 4. Create keyvault secret

```powershell
$AKV_SECRET_NAME="MySecretPassword"
az keyvault secret set --vault-name $AKV_NAME --name $AKV_SECRET_NAME --value "P@ssw0rd123!"
# {
#   "attributes": {
#     "created": "2022-12-06T10:39:20+00:00",
#     "enabled": true,
#     "expires": null,
#     "notBefore": null,
#     "recoveryLevel": "Recoverable+Purgeable",
#     "updated": "2022-12-06T10:39:20+00:00"
#   },
#   "contentType": null,
#   "id": "https://akv4aks4app07.vault.azure.net/secrets/MySecretPassword/fcfa3c0c167c4b84a7b90e52bcdb944c",
#   "kid": null,
#   "managed": null,
#   "name": "MySecretPassword",
#   "tags": {
#     "file-encoding": "utf-8"
#   },
#   "value": "P@ssw0rd123!"
# }
```

## 5. Create user managed identity resource

```powershell
$IDENTITY_NAME="user-identity-aks-4-akv"
az identity create -g $AKS_RG -n $IDENTITY_NAME
# {
#   "clientId": "a3df640c-cc14-46e3-a377-cfe31aa323b8",
#   "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourcegroups/rg-aks-demo/providers/Microsoft.ManagedIdentity/userAssignedIdentities/user-identity-aks-4-akv",
#   "location": "westeurope",
#   "name": "user-identity-aks-4-akv",
#   "principalId": "b4e025fe-ffe2-46c0-9f87-229f09f9562b",
#   "resourceGroup": "rg-aks-demo",
#   "tags": {},
#   "tenantId": "16b3c013-d300-468d-ac64-7eda0820b6d3",
#   "type": "Microsoft.ManagedIdentity/userAssignedIdentities"
# }

$IDENTITY_ID=$(az identity show -g $AKS_RG -n $IDENTITY_NAME --query "id" -o tsv)
echo $IDENTITY_ID
# /subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourcegroups/rg-aks-demo/providers/Microsoft.ManagedIdentity/userAssignedIdentities/user-identity-aks-4-akv

$IDENTITY_CLIENT_ID=$(az identity show -g $AKS_RG -n $IDENTITY_NAME --query "clientId" -o tsv)
echo $IDENTITY_CLIENT_ID
# a3df640c-cc14-46e3-a377-cfe31aa323b8
```

## 6. Assign RBAC role to user managed identity for Keyvault's secret

```powershell
$AKV_ID=$(az keyvault show -n $AKV_NAME -g $AKS_RG --query id -o tsv)
echo $AKV_ID
# /subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-demo/providers/Microsoft.KeyVault/vaults/akv4aks4app07

az role assignment create --assignee $IDENTITY_CLIENT_ID `
        --role "Key Vault Secrets User" `
        --scope $AKV_ID
# {
#     "canDelegate": null,
#     "condition": null,
#     "conditionVersion": null,
#     "description": null,
#     "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-demo/providers/Microsoft.KeyVault/vaults/akv4aks4app07/providers/Microsoft.Authorization/roleAssignments/47480365-045d-4464-92d3-b06f1f8906da",
#     "name": "47480365-045d-4464-92d3-b06f1f8906da",
#     "principalId": "b4e025fe-ffe2-46c0-9f87-229f09f9562b",
#     "principalName": "a3df640c-cc14-46e3-a377-cfe31aa323b8",
#     "principalType": "ServicePrincipal",
#     "resourceGroup": "rg-aks-demo",
#     "roleDefinitionId": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6",
#     "roleDefinitionName": "Key Vault Secrets User",
#     "scope": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-demo/providers/Microsoft.KeyVault/vaults/akv4aks4app07",
#     "type": "Microsoft.Authorization/roleAssignments"
#   }

sleep 60 # wait for role propagation
```

## 7. Create service account for user managed identity

```powershell
$NAMESPACE_APP="app-07" # can be changed to namespace of your workload

kubectl create namespace $NAMESPACE_APP
# namespace/app-07 created

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
# serviceaccount/workload-identity-sa created
```

## 8. Configure identity federation

```powershell
$FEDERATED_IDENTITY_NAME="aks-federated-identity-app"

az identity federated-credential create -n $FEDERATED_IDENTITY_NAME `
            -g $AKS_RG `
            --identity-name $IDENTITY_NAME `
            --issuer $AKS_OIDC_ISSUER `
            --subject system:serviceaccount:${NAMESPACE_APP}:${SERVICE_ACCOUNT_NAME}
# {
#   "audiences": [
#     "api://AzureADTokenExchange"
#   ],
#   "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourcegroups/rg-aks-demo/providers/Microsoft.ManagedIdentity/userAssignedIdentities/user-identity-aks-4-akv/federatedIdentityCredentials/aks-federated-identity-app",
#   "issuer": "https://westeurope.oic.prod-aks.azure.com/16b3c013-d300-468d-ac64-7eda0820b6d3/ecd4fd6e-0e43-4400-80dd-8587bdf47526/",
#   "name": "aks-federated-identity-app",
#   "resourceGroup": "rg-aks-demo",
#   "subject": "system:serviceaccount:app-07:workload-identity-sa",
#   "type": "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials"
# }
```

## 9. Configure secret provider class to get secret from Keyvault and to use user managed identity

```powershell
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
# secretproviderclass.secrets-store.csi.x-k8s.io/akv-spc-app created

kubectl get secretProviderClass -n $NAMESPACE_APP
# NAME          AGE
# akv-spc-app   11s
```

## 10. Test access to Secret in keyvault with sample deployment

```powershell
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
# deployment.apps/nginx-deploy created

kubectl get pods -n $NAMESPACE_APP
# NAME                            READY   STATUS    RESTARTS   AGE
# nginx-deploy-78dcb5b6c5-8n2hk   1/1     Running   0          49s
# nginx-deploy-78dcb5b6c5-s5jrz   1/1     Running   0          41s

$POD_NAME=$(kubectl get pod -l app=nginx-deploy -o jsonpath="{.items[0].metadata.name}" -n $NAMESPACE_APP)
echo $POD_NAME
# nginx-deploy-78dcb5b6c5-8n2hk
```

And finally, here we can see the password

```powershell
kubectl exec -it $POD_NAME -n $NAMESPACE_APP -- ls /mnt/secrets-store
# MySecretPassword

kubectl exec -it $POD_NAME -n $NAMESPACE_APP -- cat /mnt/secrets-store/$AKV_SECRET_NAME
# P@ssw0rd123!
```