# https://azure.github.io/secrets-store-csi-driver-provider-azure/docs/configurations/ingress-tls/#deploy-an-ingress-resource-referencing-the-secret-created-by-the-csi-driver

# 1. Create an AKS cluster with Secret Store CSI and Workload Identity enabled

$AKS_RG="rg-aks-cluster"
$AKS_NAME="aks-cluster"

az group create -n $AKS_RG -l westeurope

az aks create -g $AKS_RG -n $AKS_NAME `
              --kubernetes-version "1.25.2" `
              --enable-managed-identity `
              --node-count 2 `
              --network-plugin azure `
              --enable-oidc-issuer `
              --enable-workload-identity `
              --enable-addons azure-keyvault-secrets-provider `
              --rotation-poll-interval 5m `
              --enable-secret-rotation

az aks get-credentials --name $AKS_NAME -g $AKS_RG --overwrite-existing

# 1.1. Verify connection to the cluster

kubectl get nodes

# get issuer URL
$AKS_OIDC_ISSUER=$(az aks show -n $AKS_NAME -g $AKS_RG --query "oidcIssuerProfile.issuerUrl" -otsv)
echo $AKS_OIDC_ISSUER

# Check deloyment success for Secret Store CSI
kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver, secrets-store-provider-azure)'

# Check the created Manageed Identity
az aks show -n $AKS_NAME -g $AKS_RG --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv
# we won't use this (default) managed identity, we'll use our own

# 2. Create tls certificate for ingress

# later on, we'll set a domain name for the load balancer public IP
# we'll use this URL: aks-app-07.westeurope.cloudapp.azure.com

$DNS_NAME="aks-app-07"

$CERT_NAME="aks-ingress-cert"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 `
    -out aks-ingress-tls.crt `
    -keyout aks-ingress-tls.key `
    -subj "/CN=$DNS_NAME.westeurope.cloudapp.azure.com/O=aks-ingress-tls" `
    -addext "subjectAltName = DNS:$DNS_NAME.westeurope.cloudapp.azure.com"

openssl pkcs12 -export -in aks-ingress-tls.crt -inkey aks-ingress-tls.key -out "$CERT_NAME.pfx"

# 3. Create a Keyvault instance

$AKV_NAME="akvaksapp0139"

az keyvault create -n $AKV_NAME -g $AKS_RG --enable-rbac-authorization

$AKV_ID=$(az keyvault show -n $AKV_NAME -g $AKS_RG --query id -o tsv)
echo $AKV_ID

$CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)
echo $CURRENT_USER_ID

# assign admin role to my self

az role assignment create --assignee $CURRENT_USER_ID `
        --role "Key Vault Administrator" `
        --scope $AKV_ID

# 4. Import the TLS certificate into a keyvault certificate

az keyvault certificate import --vault-name $AKV_NAME -n $CERT_NAME -f "$CERT_NAME.pfx"

# 5. Create a user managed Identity

$IDENTITY_NAME="keyvault-identity"

az identity create -g $AKS_RG -n $IDENTITY_NAME

$IDENTITY_ID=$(az identity show -g $AKS_RG -n $IDENTITY_NAME --query "id" -o tsv)
echo $IDENTITY_ID

$IDENTITY_CLIENT_ID=$(az identity show -g $AKS_RG -n $IDENTITY_NAME --query "clientId" -o tsv)
echo $IDENTITY_CLIENT_ID

# assign role "Key Vault Secrets User" on Keyvault to managed identity

az role assignment create --assignee $IDENTITY_CLIENT_ID `
        --role "Key Vault Secrets User" `
        --scope $AKV_ID

# 6. Create Service Account for the app nad federated credential

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

# 7. Configure federated credential

$FEDERATED_IDENTITY_NAME="aksfederatedidentity"

az identity federated-credential create -n $FEDERATED_IDENTITY_NAME -g $AKS_RG `
            --identity-name $IDENTITY_NAME `
            --issuer $AKS_OIDC_ISSUER `
            --subject system:serviceaccount:${NAMESPACE_APP}:${SERVICE_ACCOUNT_NAME}

# 8. Configure SecretProviderClass

$TLS_SECRET="tls-secret-csi-app-07"

$TENANT_ID=$(az account list --query "[?isDefault].tenantId" -o tsv)
echo $TENANT_ID

$SECRET_PROVIDER_CLASS="azure-tls-spc-app-07"

@"
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: $SECRET_PROVIDER_CLASS
spec:
  provider: azure
  secretObjects: # k8s secret
  - secretName: $TLS_SECRET
    type: kubernetes.io/tls
    data: 
    - objectName: $CERT_NAME
      key: tls.key
    - objectName: $CERT_NAME
      key: tls.crt
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "false"
    userAssignedIdentityID: ""
    clientID: $IDENTITY_CLIENT_ID # Setting this to use workload identity
    keyvaultName: $AKV_NAME # the name of the AKV instance
    objects: |
      array:
        - |
          objectName: $CERT_NAME
          objectType: secret
    tenantId: $TENANT_ID # the tenant ID for KV
"@ > secretProviderClass.yaml

kubectl apply -f secretProviderClass.yaml -n $NAMESPACE_APP

kubectl get secretProviderClass -n $NAMESPACE_APP

# 9. Create deployment that uses the service account and secret store CSI driver

@"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-deploy
  template:
    metadata:
      labels:
        app: app-deploy
    spec:
      serviceAccountName: $SERVICE_ACCOUNT_NAME
      containers:
      - name: app-deploy
        image: mcr.microsoft.com/dotnet/samples:aspnetapp
        ports:
        - containerPort: 80
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
---
apiVersion: v1
kind: Service
metadata:
  name: app-svc
spec:
  type: ClusterIP
  ports:
  - port: 80
  selector:
    app: app-deploy
"@ > app-deploy-svc.yaml

kubectl apply -f app-deploy-svc.yaml --namespace $NAMESPACE_APP

sleep 5 # wait for pods to be deployed

kubectl get pods,svc -n $NAMESPACE_APP

# Check the mounted Secret Store CSI volume with the secret file

$POD_NAME=$(kubectl get pods -l app=app-deploy -n $NAMESPACE_APP -o jsonpath='{.items[0].metadata.name}')
echo $POD_NAME

kubectl exec $POD_NAME -n $NAMESPACE_APP -it -- ls /mnt/secrets-store

# the secret should have been deployed
kubectl describe secret $TLS_SECRET -n $NAMESPACE_APP

# 9. Install Nginx Ingress Controller with custom name

$NAMESPACE_INGRESS="ingress-nginx-app-07"

kubectl create namespace $NAMESPACE_INGRESS

# install Nginx ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

$INGRESS_CLASS_NAME="nginx-app-07"

@"
controller:
  ingressClassResource:
    name: $INGRESS_CLASS_NAME # default: nginx
    enabled: true
    default: false
    controllerValue: "k8s.io/ingress-$INGRESS_CLASS_NAME"
"@ > ingress-controller-values.yaml

helm upgrade --install ingress-nginx-app-07 ingress-nginx/ingress-nginx `
     --create-namespace `
     --namespace $NAMESPACE_INGRESS `
     --set controller.replicaCount=2 `
     --set controller.nodeSelector."kubernetes\.io/os"=linux `
     --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux `
     --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz `
     -f ingress-controller-values.yaml

# get the ingress class resources, note we already have one deployed in another demo
kubectl get ingressclass

kubectl get pods,svc -n $NAMESPACE_INGRESS

# capture ingress, public IP (Azure Public IP created)
$INGRESS_PUPLIC_IP=$(kubectl get services ingress-$INGRESS_CLASS_NAME-controller -n $NAMESPACE_INGRESS -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $INGRESS_PUPLIC_IP

# 10. Configure Ingress' Public IP with DNS Name

# 10.1. Option 1: Name to associate with Azure Public IP address

# Get the resource-id of the public IP
$NODE_RG=$(az aks show -g $AKS_RG -n $AKS_NAME --query nodeResourceGroup -o tsv)
echo $NODE_RG

$AZURE_PUBLIC_IP_ID=$(az network public-ip list -g $NODE_RG --query "[?ipAddress!=null]|[?contains(ipAddress, '$INGRESS_PUPLIC_IP')].[id]" -o tsv)
echo $AZURE_PUBLIC_IP_ID

# Update public IP address with DNS name
az network public-ip update --ids $AZURE_PUBLIC_IP_ID --dns-name $DNS_NAME

$DOMAIN_NAME_FQDN=$(az network public-ip show --ids $AZURE_PUBLIC_IP_ID --query='dnsSettings.fqdn' -o tsv)
echo $DOMAIN_NAME_FQDN

# # 10.2. Option 2: Name to associate with Azure DNS Zone

# # Add an A record to your DNS zone
# az network dns record-set a add-record `
#     --resource-group rg-houssem-cloud-dns `
#     --zone-name "houssem.cloud" `
#     --record-set-name "*" `
#     --ipv4-address $INGRESS_PUPLIC_IP

# # az network public-ip update -g MC_rg-aks-we_aks-cluster_westeurope -n kubernetes-af54fcf50c6b24d7fbb9ed6aa62bdc77 --dns-name $DNS_NAME
# $DOMAIN_NAME_FQDN=$DNS_NAME.houssem.cloud
# echo $DOMAIN_NAME_FQDN

# 11. Deploy Ingress resource taht will retrieve TLS certificate from secret

@"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: $INGRESS_CLASS_NAME # nginx
  tls:
  - hosts:
    - $DOMAIN_NAME_FQDN
    secretName: $TLS_SECRET
  rules:
  - host: $DOMAIN_NAME_FQDN
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-svc
            port:
              number: 80
"@ > app-ingress.yaml

kubectl apply -f app-ingress.yaml --namespace $NAMESPACE_APP

kubectl get ingress --namespace $NAMESPACE_APP

# 12. Check app is working with HTTPS

# check tls certificate
curl -v -k --resolve $DOMAIN_NAME_FQDN:443:$INGRESS_PUPLIC_IP https://$DOMAIN_NAME_FQDN