# https://azure.github.io/secrets-store-csi-driver-provider-azure/docs/configurations/ingress-tls/#deploy-an-ingress-resource-referencing-the-secret-created-by-the-csi-driver

# create an AKS cluster
RG="rg-aks-demo"
AKS="aks-cluster"

az group create -n $RG -l westeurope

az aks create -g $RG -n $AKS \
              --kubernetes-version "1.25.2" \
              --enable-managed-identity \
              --node-count 2 \
              --network-plugin azure \
              --enable-oidc-issuer \
              --enable-workload-identity \
              --enable-addons azure-keyvault-secrets-provider \
              --rotation-poll-interval 5m \
              --enable-secret-rotation

az aks get-credentials --name $AKS -g $RG --overwrite-existing

# verify connection to the cluster
kubectl get nodes

AKS_OIDC_ISSUER=$(az aks show -n $AKS -g $RG --query "oidcIssuerProfile.issuerUrl" -otsv)
echo $AKS_OIDC_ISSUER
# https://westeurope.oic.prod-aks.azure.com/16b3c013-d300-468d-ac64-7eda0820b6d3/842120d9-99dd-44dc-be68-91f78bdd41ed/

kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver, secrets-store-provider-azure)'
# NAME                                     READY   STATUS    RESTARTS   AGE
# aks-secrets-store-csi-driver-knhnr       3/3     Running   0          24m
# aks-secrets-store-csi-driver-mpd6q       3/3     Running   0          24m
# aks-secrets-store-csi-driver-rmlhk       3/3     Running   0          24m
# aks-secrets-store-provider-azure-4ckgq   1/1     Running   0          24m
# aks-secrets-store-provider-azure-88snb   1/1     Running   0          24m
# aks-secrets-store-provider-azure-zcc2z   1/1     Running   0          24m

az aks show -n $AKS -g $RG --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv
# 47744279-8b5e-4c77-9102-7c6c1874587a
# we won't use this (default) managed identity, we'll use our own

# configure keyvault

# create tls certificate
# later on, we'll set a domain name for the load balancer public IP
# aks-app-07.westeurope.cloudapp.azure.com

DNS_NAME="aks-app-07"

CERT_NAME="aks-ingress-cert" #TODO "aks-app-07-cert"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out aks-ingress-tls.crt \
    -keyout aks-ingress-tls.key \
    -subj "/CN=$DNS_NAME.westeurope.cloudapp.azure.com/O=aks-ingress-tls" \
    -addext "subjectAltName = DNS:$DNS_NAME.westeurope.cloudapp.azure.com" # added by reco

openssl pkcs12 -export -in aks-ingress-tls.crt -inkey aks-ingress-tls.key -out "${CERT_NAME}.pfx"
# skip Password prompt
# Enter Export Password:
# Verifying - Enter Export Password:

AKV_NAME="akvaksapp07"
az keyvault create -n $AKV_NAME -g $RG
az keyvault certificate import --vault-name $AKV_NAME -n $CERT_NAME -f "${CERT_NAME}.pfx"

IDENTITY_NAME="keyvault-identity"
az identity create -g $RG -n $IDENTITY_NAME

IDENTITY_ID=$(az identity show -g $RG -n $IDENTITY_NAME --query "id" -o tsv)
echo $IDENTITY_ID
# /subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourcegroups/rg-aks-we/providers/Microsoft.ManagedIdentity/userAssignedIdentities/keyvault-identity

IDENTITY_CLIENT_ID=$(az identity show -g $RG -n $IDENTITY_NAME --query "clientId" -o tsv)
echo $IDENTITY_CLIENT_ID
# a908d131-d1f3-4f44-8b9e-c5d21110eb84

AKV_ID=$(az keyvault show -n $AKV_NAME -g $RG --query id -o tsv)
echo $AKV_ID
# /subscriptions/82f6d75e-85f4-xxxx-xxxx-5dddd9fa8910/resourceGroups/rg-aks-dev/providers/Microsoft.KeyVault/vaults/akvaksingressapp007

# az role assignment create --assignee $IDENTITY_CLIENT_ID \
#         --role "Key Vault Secrets User" \
#         --scope $AKV_ID

# set policy to access keys in your key vault
az keyvault set-policy -n $AKV_NAME --key-permissions get --spn $IDENTITY_CLIENT_ID
# set policy to access secrets in your key vault
az keyvault set-policy -n $AKV_NAME --secret-permissions get --spn $IDENTITY_CLIENT_ID
# set policy to access certs in your key vault
az keyvault set-policy -n $AKV_NAME --certificate-permissions get --spn $IDENTITY_CLIENT_ID

NAMESPACE_APP="app-07" # can be changed to namespace of your workload

kubectl create namespace $NAMESPACE_APP
# namespace/app-07 created

SERVICE_ACCOUNT_NAME="workload-identity-sa"

cat <<EOF >service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: $USER_ASSIGNED_CLIENT_ID
  labels:
    azure.workload.identity/use: "true"
  name: $SERVICE_ACCOUNT_NAME
EOF

kubectl apply -f service-account.yaml --namespace $NAMESPACE_APP
# serviceaccount/workload-identity-sa created

FEDERATED_IDENTITY_NAME="aksfederatedidentity"
az identity federated-credential create -n $FEDERATED_IDENTITY_NAME -g $RG \
            --identity-name $IDENTITY_NAME \
            --issuer $AKS_OIDC_ISSUER \
            --subject system:serviceaccount:$NAMESPACE_APP:$SERVICE_ACCOUNT_NAME
# {
#   "audiences": [
#     "api://AzureADTokenExchange"
#   ],
#   "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourcegroups/rg-aks-we/providers/Microsoft.ManagedIdentity/userAssignedIdentities/keyvault-identity/federatedIdentityCredentials/aksfederatedidentity",
#   "issuer": "https://westeurope.oic.prod-aks.azure.com/16b3c013-d300-468d-ac64-7eda0820b6d3/842120d9-99dd-44dc-be68-91f78bdd41ed/",
#   "name": "aksfederatedidentity",
#   "resourceGroup": "rg-aks-we",
#   "subject": "system:serviceaccount:ingress-nginx-app-07:workload-identity-sa",
#   "type": "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials"
# }

TLS_SECRET="tls-secret-csi-app-07"

TENANT_ID=$(az account list --query "[?isDefault].tenantId" -o tsv)
echo $TENANT_ID
# 16b3c013-d300-468d-ac64-7eda0820b6d3

SECRET_PROVIDER_CLASS="azure-tls-spc-app-07"

cat <<EOF >secretProviderClass.yaml
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
EOF

kubectl apply -f secretProviderClass.yaml -n $NAMESPACE_APP
# secretproviderclass.secrets-store.csi.x-k8s.io/azure-tls created

kubectl get secretProviderClass -n $NAMESPACE_APP
# NAME        AGE
# azure-tls   35s


cat <<EOF >aks-helloworld-one.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aks-helloworld-one
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aks-helloworld-one
  template:
    metadata:
      labels:
        app: aks-helloworld-one
    spec:
      serviceAccountName: $SERVICE_ACCOUNT_NAME
      containers:
      - name: aks-helloworld-one
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
        env:
        - name: TITLE
          value: "Welcome to Azure Kubernetes Service (AKS)"
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
            # nodePublishSecretRef:
            #   name: secrets-store-creds
---
apiVersion: v1
kind: Service
metadata:
  name: aks-helloworld-one  
spec:
  type: ClusterIP
  ports:
  - port: 80
  selector:
    app: aks-helloworld-one
EOF

kubectl apply -f aks-helloworld-one.yaml --namespace $NAMESPACE_APP
# deployment.apps/aks-helloworld-one created
# service/aks-helloworld-one created

cat <<EOF >aks-helloworld-two.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aks-helloworld-two
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aks-helloworld-two
  template:
    metadata:
      labels:
        app: aks-helloworld-two
    spec:
      serviceAccountName: $SERVICE_ACCOUNT_NAME
      containers:
      - name: aks-helloworld-two
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
        env:
        - name: TITLE
          value: "AKS Ingress Demo"
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
            # nodePublishSecretRef:
            #   name: secrets-store-creds
---
apiVersion: v1
kind: Service
metadata:
  name: aks-helloworld-two  
spec:
  type: ClusterIP
  ports:
  - port: 80
  selector:
    app: aks-helloworld-two
EOF

kubectl apply -f aks-helloworld-two.yaml --namespace $NAMESPACE_APP
# deployment.apps/aks-helloworld-two created
# service/aks-helloworld-two created

kubectl get pods,svc -n $NAMESPACE_APP
# NAME                                      READY   STATUS    RESTARTS   AGE
# pod/aks-helloworld-one-85bc95b4db-5phk6   1/1     Running   0          32s
# pod/aks-helloworld-two-5f89bff56-d47ft    1/1     Running   0          32s

# NAME                         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
# service/aks-helloworld-one   ClusterIP   10.0.206.22   <none>        80/TCP    32s
# service/aks-helloworld-two   ClusterIP   10.0.176.49   <none>        80/TCP    32s

# the secret should have been deployed
kubectl describe secret $TLS_SECRET -n $NAMESPACE_APP
# Name:         tls-secret-csi-app-07
# Namespace:    app-07
# Labels:       secrets-store.csi.k8s.io/managed=true
# Annotations:  <none>

# Type:  kubernetes.io/tls

# Data
# ====
# tls.crt:  1342 bytes
# tls.key:  1675 bytes

NAMESPACE_INGRESS="ingress-nginx-app-07"
kubectl create namespace $NAMESPACE_INGRESS
# namespace/ingress-nginx-app-07 created

# install Nginx ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

INGRESS_CLASS_NAME="nginx-app-07"

helm upgrade --install ingress-nginx-app-07 ingress-nginx/ingress-nginx \
     --create-namespace \
     --namespace $NAMESPACE_INGRESS \
     --set controller.replicaCount=2 \
     --set controller.nodeSelector."kubernetes\.io/os"=linux \
     --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
     --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
     -f - <<EOF
controller:
  ingressClassResource:
    name: $INGRESS_CLASS_NAME # default: nginx
    enabled: true
    default: false
    controllerValue: "k8s.io/ingress-$INGRESS_CLASS_NAME"
EOF

# get the ingress class resources, note we already have one deployed in another demo
kubectl get ingressclass
# NAME           CONTROLLER                    PARAMETERS   AGE
# nginx-app-07   k8s.io/ingress-nginx-app-07   <none>       50s

kubectl get pods,svc -n $NAMESPACE_INGRESS
# NAME                                                   READY   STATUS    RESTARTS   AGE
# pod/ingress-nginx-app-07-controller-84754f8d77-4nk4s   1/1     Running   0          15m
# pod/ingress-nginx-app-07-controller-84754f8d77-745mr   1/1     Running   0          15m

# NAME                                                TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)                      AGE
# service/ingress-nginx-app-07-controller             LoadBalancer   10.0.93.183    20.101.208.164   80:32033/TCP,443:32039/TCP   15m
# service/ingress-nginx-app-07-controller-admission   ClusterIP      10.0.151.181   <none>           443/TCP                      15m

# capture ingress, public IP (Azure Public IP created)
INGRESS_PUPLIC_IP=$(kubectl get services ingress-$INGRESS_CLASS_NAME-controller -n $NAMESPACE_INGRESS -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $INGRESS_PUPLIC_IP
# 20.101.208.164

# configure Ingress' Public IP with DNS Name

###########################################################
# Option 1: Name to associate with Azure Public IP address

# Get the resource-id of the public IP
NODE_RG=$(az aks show -g $RG -n $AKS --query nodeResourceGroup -o tsv)
echo $NODE_RG
# MC_rg-aks-demo_aks-cluster_westeurope

AZURE_PUBLIC_IP_ID=$(az network public-ip list -g $NODE_RG --query "[?ipAddress!=null]|[?contains(ipAddress, '$INGRESS_PUPLIC_IP')].[id]" -o tsv)
echo $AZURE_PUBLIC_IP_ID
# /subscriptions/82f6d75e-85f4-xxxx-xxxx-5dddd9fa8910/resourceGroups/mc_rg-aks-demo_aks-cluster_westeurope/providers/Microsoft.Network/publicIPAddresses/kubernetes-a67a81403ec5e4ebca58049d0ebfda3c

# Update public IP address with DNS name
az network public-ip update --ids $AZURE_PUBLIC_IP_ID --dns-name $DNS_NAME
DOMAIN_NAME_FQDN=$(az network public-ip show --ids $AZURE_PUBLIC_IP_ID --query='dnsSettings.fqdn' -o tsv)
# DOMAIN_NAME_FQDN=$(az network public-ip show -g MC_rg-aks-we_aks-cluster_westeurope -n kubernetes-af54fcf50c6b24d7fbb9ed6aa62bdc77 --query='dnsSettings.fqdn')
echo $DOMAIN_NAME_FQDN
# "aks-app-07.westeurope.cloudapp.azure.com"

###########################################################
# Option 2: Name to associate with Azure DNS Zone

# Add an A record to your DNS zone
az network dns record-set a add-record \
    --resource-group rg-houssem-cloud-dns \
    --zone-name "houssem.cloud" \
    --record-set-name "*" \
    --ipv4-address $INGRESS_PUPLIC_IP

# az network public-ip update -g MC_rg-aks-we_aks-cluster_westeurope -n kubernetes-af54fcf50c6b24d7fbb9ed6aa62bdc77 --dns-name $DNS_NAME
DOMAIN_NAME_FQDN=$DNS_NAME.houssem.cloud
echo $DOMAIN_NAME_FQDN
# aks-app-03.houssem.cloud

cat <<EOF >hello-world-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /\$2
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: $INGRESS_CLASS_NAME # nginx
  tls:
  - hosts:
    - $DOMAIN_NAME_FQDN
    # - frontend.20.73.235.13.nip.io
    # - aks-app-01.westeurope.cloudapp.azure.com
    secretName: $TLS_SECRET
  rules:
  - host: $DOMAIN_NAME_FQDN
  # - host: aks-app-01.westeurope.cloudapp.azure.com
  # - host: frontend.20.73.235.13.nip.io
    http:
      paths:
      - path: /hello-world-one(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: aks-helloworld-one
            port:
              number: 80
      - path: /hello-world-two(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: aks-helloworld-two
            port:
              number: 80
      - path: /(.*)
        pathType: Prefix
        backend:
          service:
            name: aks-helloworld-one
            port:
              number: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world-ingress-static
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /static/\$2
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
      - path: /static(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: aks-helloworld-one
            port: 
              number: 80
EOF

kubectl apply -f hello-world-ingress.yaml --namespace $NAMESPACE_APP

kubectl get ingress --namespace $NAMESPACE_APP
# NAME                         CLASS          HOSTS                                      ADDRESS   PORTS     AGE
# hello-world-ingress          nginx-app-07   aks-app-07.westeurope.cloudapp.azure.com             80, 443   12s
# hello-world-ingress-static   nginx-app-07   aks-app-07.westeurope.cloudapp.azure.com             80, 443   11s

# check app is working with HTTPS
curl https://$DOMAIN_NAME_FQDN
curl https://$DOMAIN_NAME_FQDN/hello-world-one
curl https://$DOMAIN_NAME_FQDN/hello-world-two

# check tls certificate
curl -v -k --resolve $DOMAIN_NAME_FQDN:443:$INGRESS_PUPLIC_IP https://$DOMAIN_NAME_FQDN
# MAIN_NAME_FQDN
# * Added aks-app-07.westeurope.cloudapp.azure.com:443:20.238.249.157 to DNS cache
# * Hostname aks-app-07.westeurope.cloudapp.azure.com was found in DNS cache
# *   Trying 20.238.249.157:443...
# * Connected to aks-app-07.westeurope.cloudapp.azure.com (20.238.249.157) port 443 (#0)
# * ALPN, offering h2
# * ALPN, offering http/1.1
# * TLSv1.0 (OUT), TLS header, Certificate Status (22):
# * TLSv1.3 (OUT), TLS handshake, Client hello (1):
# * TLSv1.2 (IN), TLS header, Certificate Status (22):
# * TLSv1.3 (IN), TLS handshake, Server hello (2):
# * TLSv1.2 (IN), TLS header, Finished (20):
# * TLSv1.2 (IN), TLS header, Supplemental data (23):
# * TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
# * TLSv1.2 (IN), TLS header, Supplemental data (23):
# * TLSv1.3 (IN), TLS handshake, Certificate (11):
# * TLSv1.2 (IN), TLS header, Supplemental data (23):
# * TLSv1.3 (IN), TLS handshake, CERT verify (15):
# * TLSv1.2 (IN), TLS header, Supplemental data (23):
# * TLSv1.3 (IN), TLS handshake, Finished (20):
# * TLSv1.2 (OUT), TLS header, Finished (20):
# * TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
# * TLSv1.2 (OUT), TLS header, Supplemental data (23):
# * TLSv1.3 (OUT), TLS handshake, Finished (20):
# * SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
# * ALPN, server accepted to use h2
# * Server certificate:
# *  subject: CN=aks-app-07.westeurope.cloudapp.azure.com; O=aks-ingress-tls
# *  start date: Nov 25 11:12:44 2022 GMT
# *  expire date: Nov 25 11:12:44 2023 GMT
# *  issuer: CN=aks-app-07.westeurope.cloudapp.azure.com; O=aks-ingress-tls
# *  SSL certificate verify result: self-signed certificate (18), continuing anyway.
# * Using HTTP2, server supports multiplexing
# * Connection state changed (HTTP/2 confirmed)
# * Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
# * TLSv1.2 (OUT), TLS header, Supplemental data (23):
# * TLSv1.2 (OUT), TLS header, Supplemental data (23):
# * TLSv1.2 (OUT), TLS header, Supplemental data (23):
# * Using Stream ID: 1 (easy handle 0x564b2b7b5e80)
# * TLSv1.2 (OUT), TLS header, Supplemental data (23):
# > GET / HTTP/2
# > Host: aks-app-07.westeurope.cloudapp.azure.com
# > user-agent: curl/7.81.0
# > accept: */*
# >
# * TLSv1.2 (IN), TLS header, Supplemental data (23):
# * TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
# * TLSv1.2 (IN), TLS header, Supplemental data (23):
# * TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
# * old SSL session ID is stale, removing
# * TLSv1.2 (IN), TLS header, Supplemental data (23):
# * Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
# * TLSv1.2 (OUT), TLS header, Supplemental data (23):
# * TLSv1.2 (IN), TLS header, Supplemental data (23):
# < HTTP/2 200
# < date: Fri, 25 Nov 2022 12:23:00 GMT
# < content-type: text/html; charset=utf-8
# < content-length: 629
# < strict-transport-security: max-age=15724800; includeSubDomains
# <
# <!DOCTYPE html>
# <html xmlns="http://www.w3.org/1999/xhtml">
# <head>
#     <link rel="stylesheet" type="text/css" href="/static/default.css">
#     <title>Welcome to Azure Kubernetes Service (AKS)</title>

#     <script language="JavaScript">
#         function send(form){
#         }
#     </script>

# </head>
# <body>
#     <div id="container">
#         <form id="form" name="form" action="/"" method="post"><center>
#         <div id="logo">Welcome to Azure Kubernetes Service (AKS)</div>
#         <div id="space"></div>
#         <img src="/static/acs.png" als="acs logo">
#         <div id="form">
#         </div>
#     </div>
# </body>
# * TLSv1.2 (IN), TLS header, Supplemental data (23):
# * Connection #0 to host aks-app-07.westeurope.cloudapp.azure.com left intact
# </html>

# default-backend="https", ingress nginx