# create an AKS cluster
RG="rg-aks-we"
AKS="aks-cluster"

az group create -n $RG -l westeurope

az aks create -g $RG -n $AKS --network-plugin azure --kubernetes-version "1.25.2" --node-count 2

az aks get-credentials --name $AKS -g $RG --overwrite-existing

# verify connection to the cluster
kubectl get nodes

# install Nginx ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

NAMESPACE_INGRESS="ingress-nginx-app-03"
INGRESS_CLASS_NAME="nginx-app-03"

helm upgrade --install ingress-nginx-app-03 ingress-nginx/ingress-nginx \
     --create-namespace \
     --namespace $NAMESPACE_INGRESS \
     --set controller.replicaCount=2 \
     --set controller.nodeSelector."kubernetes\.io/os"=linux \
     --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
-f - <<EOF
controller:
  ingressClassResource:
    name: $INGRESS_CLASS_NAME # default: nginx
    enabled: true
    default: false
    controllerValue: "k8s.io/ingress-$INGRESS_CLASS_NAME"
EOF

kubectl get services --namespace $NAMESPACE_INGRESS
# NAME                                        TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)                      AGE
# ingress-nginx-app-03-controller             LoadBalancer   10.0.148.15   20.76.206.157   80:31276/TCP,443:32227/TCP   31s
# ingress-nginx-app-03-controller-admission   ClusterIP      10.0.41.91    <none>          443/TCP                      31s

# capture ingress, public IP (Azure Public IP created)
INGRESS_PUPLIC_IP=$(kubectl get services ingress-$INGRESS_CLASS_NAME-controller -n $NAMESPACE_INGRESS -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $INGRESS_PUPLIC_IP
# 20.76.206.157

# get the ingress class resources, note we already have one deployed in another demo
kubectl get ingressclass
# NAME           CONTROLLER                    PARAMETERS   AGE
# nginx          k8s.io/ingress-nginx          <none>       6h18m
# nginx-app-02   k8s.io/ingress-nginx-app-02   <none>       3h30m
# nginx-app-03   k8s.io/ingress-nginx-app-03   <none>       86s

NAMESPACE_APP_03="app-03"
kubectl create namespace $NAMESPACE_APP_03

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
      containers:
      - name: aks-helloworld-one
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
        env:
        - name: TITLE
          value: "Welcome to Azure Kubernetes Service (AKS)"
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

kubectl apply -f aks-helloworld-one.yaml --namespace $NAMESPACE_APP_03
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
      containers:
      - name: aks-helloworld-two
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
        env:
        - name: TITLE
          value: "AKS Ingress Demo"
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

kubectl apply -f aks-helloworld-two.yaml --namespace $NAMESPACE_APP_03
# deployment.apps/aks-helloworld-two created
# service/aks-helloworld-two created

# configure Ingress' Public IP with DNS Name

DNS_NAME="aks-app-03"

###########################################################
# Option 1: Name to associate with Azure Public IP address

# Get the resource-id of the public IP
AZURE_PUBLIC_IP_ID=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$INGRESS_PUPLIC_IP')].[id]" --output tsv)
# /subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/mc_rg-aks-we_aks-cluster_westeurope/providers/Microsoft.Network/publicIPAddresses/kubernetes-ac66be6d522074f829e69bcf36c6e986

# Update public IP address with DNS name
az network public-ip update --ids $AZURE_PUBLIC_IP_ID --dns-name $DNS_NAME
# az network public-ip update -g MC_rg-aks-we_aks-cluster_westeurope -n kubernetes-af54fcf50c6b24d7fbb9ed6aa62bdc77 --dns-name $DNS_NAME
DOMAIN_NAME_FQDN=$(az network public-ip show --ids $AZURE_PUBLIC_IP_ID --query='dnsSettings.fqdn' -o tsv)
echo $DOMAIN_NAME_FQDN
# aks-app-02.westeurope.cloudapp.azure.com

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


# install cert-manager

# Label the namespace to disable resource validation
kubectl label namespace $NAMESPACE_INGRESS cert-manager.io/disable-validation=true
# namespace/ingress-basic labeled
# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io
# Update your local Helm chart repository cache
helm repo update
# Install the cert-manager Helm chart
helm install cert-manager jetstack/cert-manager \
     --namespace $NAMESPACE_INGRESS \
     --create-namespace --set installCRDs=true

cat <<EOF >cluster-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: "houssem.dellai@live.com"
    privateKeySecretRef:
      name: letsencrypt
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

kubectl apply -f cluster-issuer.yaml
# issuer.cert-manager.io/letsencrypt created

kubectl get clusterissuer
# NAME          READY   AGE
# letsencrypt   True    56s

cat <<EOF >hello-world-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /\$2
    nginx.ingress.kubernetes.io/use-regex: "true"
    # cert-manager.io/issuer: letsencrypt
    cert-manager.io/cluster-issuer: "letsencrypt"
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
    # cert-manager.io/issuer: letsencrypt
    cert-manager.io/cluster-issuer: "letsencrypt"
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

kubectl apply -f hello-world-ingress.yaml --namespace $NAMESPACE_APP_03

kubectl get ingress --namespace $NAMESPACE_APP_03
# NAME                         CLASS          HOSTS                                      ADDRESS   PORTS     AGE
# hello-world-ingress          nginx-app-02   aks-app-02.westeurope.cloudapp.azure.com             80, 443   12s
# hello-world-ingress-static   nginx-app-02   aks-app-02.westeurope.cloudapp.azure.com             80, 443   11s

# check app is working with HTTPS
curl https://$DOMAIN_NAME_FQDN
curl https://$DOMAIN_NAME_FQDN/hello-world-one
curl https://$DOMAIN_NAME_FQDN/hello-world-two

# check the tls/ssl certificate
curl -v -k --resolve $DOMAIN_NAME_FQDN:443:$INGRESS_PUPLIC_IP https://$DOMAIN_NAME_FQDN
# * Added aks-app-03.westeurope.cloudapp.azure.com:443:20.103.76.255 to DNS cache
# * Hostname aks-app-03.westeurope.cloudapp.azure.com was found in DNS cache
# *   Trying 20.103.76.255:443...
# * Connected to aks-app-03.westeurope.cloudapp.azure.com (20.103.76.255) port 443 (#0)
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
# *  subject: CN=aks-app-03.westeurope.cloudapp.azure.com
# *  start date: Nov 21 18:43:38 2022 GMT
# *  expire date: Feb 19 18:43:37 2023 GMT
# *  issuer: C=US; O=Let's Encrypt; CN=R3
# *  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
# * Using HTTP2, server supports multiplexing
# * Connection state changed (HTTP/2 confirmed)
# * Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
# * TLSv1.2 (OUT), TLS header, Supplemental data (23):
# * TLSv1.2 (OUT), TLS header, Supplemental data (23):
# * TLSv1.2 (OUT), TLS header, Supplemental data (23):
# * Using Stream ID: 1 (easy handle 0x555642a78e80)
# * TLSv1.2 (OUT), TLS header, Supplemental data (23):
# > GET / HTTP/2
# > Host: aks-app-03.westeurope.cloudapp.azure.com
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
# < date: Mon, 21 Nov 2022 19:44:50 GMT
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
# * Connection #0 to host aks-app-03.westeurope.cloudapp.azure.com left intact
# </html>