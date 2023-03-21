# Secuing Ingress with TLS - HTTPS

## Introduction

In this lab, we will secure traffic to Ingress Controller using HTTPS with TLS certificate.

We will perform the following steps:
1. Create an AKS cluster
2. Install Nginx ingress controller with custom ingress class name
3. Deploy sample application into a separate namespace
4. Configure Ingress' Public IP with DNS Name
5. Create TLS certificate
6. Create ingress resoure that uses TLS
7. Check app is working with HTTPS

<img src="media/basic-ingress-tls.png">

## 1. Create an AKS cluster

```powershell
$AKS_RG="rg-aks-tls"
$AKS_NAME="aks-cluster"

az group create -n $AKS_RG -l westeurope

az aks create -g $AKS_RG -n $AKS_NAME --network-plugin azure --kubernetes-version "1.25.2" --node-count 2

az aks get-credentials --name $AKS_NAME -g $AKS_RG --overwrite-existing

# verify connection to the cluster
kubectl get nodes
# NAME                                STATUS   ROLES   AGE     VERSION
# aks-nodepool1-32594854-vmss000000   Ready    agent   4m33s   v1.25.2
# aks-nodepool1-32594854-vmss000001   Ready    agent   4m28s   v1.25.2
```

## 2. Install Nginx ingress controller with custom ingress class name

```powershell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

$NAMESPACE_INGRESS="ingress-nginx-app-02"
$INGRESS_CLASS_NAME="nginx-app-02"

@"
controller:
  ingressClassResource:
    name: $INGRESS_CLASS_NAME # default: nginx
    enabled: true
    default: false
    controllerValue: "k8s.io/ingress-$INGRESS_CLASS_NAME"
"@ > ingress-nginx-values.yaml

helm upgrade --install ingress-nginx-app-02 ingress-nginx/ingress-nginx `
     --create-namespace --namespace $NAMESPACE_INGRESS `
     --set controller.replicaCount=2 `
     --set controller.nodeSelector."kubernetes\.io/os"=linux `
     --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz `
     -f ingress-nginx-values.yaml
```

Check ingress controller installed correctly

```powershell
kubectl get pods,services --namespace $NAMESPACE_INGRESS
# NAME                                                  READY   STATUS    RESTARTS   AGE
# pod/ingress-nginx-app-02-controller-74b4f749c-7z4mb   1/1     Running   0          43s
# pod/ingress-nginx-app-02-controller-74b4f749c-c7zs4   1/1     Running   0          43s

# NAME                                                TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)                      AGE
# service/ingress-nginx-app-02-controller             LoadBalancer   10.0.150.3     20.23.111.15   80:31671/TCP,443:30205/TCP   43s
# service/ingress-nginx-app-02-controller-admission   ClusterIP      10.0.201.182   <none>         443/TCP                      43s
```

```powershell
# capture ingress, public IP (Azure Public IP created)
$INGRESS_PUPLIC_IP=$(kubectl get services ingress-$INGRESS_CLASS_NAME-controller -n $NAMESPACE_INGRESS -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $INGRESS_PUPLIC_IP
# 20.23.111.15

# get the ingress class resources, note we already have one deployed in another demo
kubectl get ingressclass
# NAME           CONTROLLER                    PARAMETERS   AGE
# nginx          k8s.io/ingress-nginx          <none>       168m
# nginx-app-02   k8s.io/ingress-nginx-app-02   <none>       69s
```

## 3. Deploy sample application into a separate namespace

```powershell
$NAMESPACE_APP_02="app-02"

kubectl create namespace $NAMESPACE_APP_02
# namespace/app-02 created

@"
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
"@ > aks-helloworld-one.yaml

kubectl apply -f aks-helloworld-one.yaml --namespace $NAMESPACE_APP_02
# deployment.apps/aks-helloworld-one created
# service/aks-helloworld-one created

@"
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
"@ > aks-helloworld-two.yaml

kubectl apply -f aks-helloworld-two.yaml --namespace $NAMESPACE_APP_02
# deployment.apps/aks-helloworld-two created
# service/aks-helloworld-two created
```

## 4. Configure Ingress' Public IP with DNS Name

## Option 1: Name to associate with Azure Public IP address

```powershell
$DNS_NAME="aks-app-02"

$NODE_RG=$(az aks show -g $AKS_RG -n $AKS_NAME --query nodeResourceGroup -o tsv)
echo $NODE_RG
# MC_rg-aks-we_aks-cluster_westeurope

# Get the resource-id of the public IP
$AZURE_PUBLIC_IP_ID=$(az network public-ip list -g $NODE_RG --query "[?ipAddress!=null]|[?contains(ipAddress, '$INGRESS_PUPLIC_IP')].[id]" -o tsv)
echo $AZURE_PUBLIC_IP_ID

# Update public IP address with DNS name
az network public-ip update --ids $AZURE_PUBLIC_IP_ID --dns-name $DNS_NAME

$DOMAIN_NAME_FQDN=$(az network public-ip show --ids $AZURE_PUBLIC_IP_ID --query='dnsSettings.fqdn' -o tsv)
echo $DOMAIN_NAME_FQDN
# aks-app-02.westeurope.cloudapp.azure.com
```

## Option 2: Name to associate with Azure DNS Zone
```powershell
$DNS_NAME="aks-app-02"

# Add an A record to your DNS zone
az network dns record-set a add-record `
    --resource-group rg-houssem-cloud-dns `
    --zone-name "houssem.cloud" `
    --record-set-name "*" `
    --ipv4-address $INGRESS_PUPLIC_IP

# az network public-ip update -g MC_rg-aks-we_aks-cluster_westeurope -n kubernetes-af54fcf50c6b24d7fbb9ed6aa62bdc77 --dns-name $DNS_NAME
$DOMAIN_NAME_FQDN=$DNS_NAME.houssem.cloud
echo $DOMAIN_NAME_FQDN
# aks-app-02.houssem.cloud
```

## 5. Create TLS certificate and save it into secret

```powershell

openssl req -x509 -nodes -days 365 -newkey rsa:2048 `
    -out aks-ingress-tls.crt `
    -keyout aks-ingress-tls.key `
    -subj "/CN=${DOMAIN_NAME_FQDN}/O=${DOMAIN_NAME_FQDN}" `
    -addext "subjectAltName = DNS:${DOMAIN_NAME_FQDN}"

ls
# aks-helloworld-one.yaml aks-helloworld-two.yaml  aks-ingress-tls.crt  aks-ingress-tls.key  commands.sh  hello-world-ingress-tls.yaml

$TLS_SECRET="tls-ingress-app-02-secret"

kubectl create secret tls $TLS_SECRET --cert=aks-ingress-tls.crt --key=aks-ingress-tls.key --namespace $NAMESPACE_APP_02
# secret/tls-ingress-app-02-secret created

kubectl describe secret $TLS_SECRET --namespace $NAMESPACE_APP_02
# Name:         tls-ingress-app-02-secret
# Namespace:    app-02
# Labels:       <none>
# Annotations:  <none>
# Type:  kubernetes.io/tls
# Data
# ====
# 
# tls.crt:  1273 bytes
# tls.key:  1704 bytes
```

## 6. Create ingress resoure that uses TLS

```powershell
@"
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
    secretName: $TLS_SECRET
  rules:
  - host: $DOMAIN_NAME_FQDN
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
"@ > hello-world-ingress.yaml

kubectl apply -f hello-world-ingress.yaml --namespace $NAMESPACE_APP_02
# ingress.networking.k8s.io/hello-world-ingress created
# ingress.networking.k8s.io/hello-world-ingress-static created

kubectl get ingress --namespace $NAMESPACE_APP_02
# NAME                         CLASS          HOSTS                                      ADDRESS   PORTS     AGE
# hello-world-ingress          nginx-app-02   aks-app-02.westeurope.cloudapp.azure.com             80, 443   12s
# hello-world-ingress-static   nginx-app-02   aks-app-02.westeurope.cloudapp.azure.com             80, 443   11s
```

## 7. Check app is working with HTTPS

```powershell
curl https://$DOMAIN_NAME_FQDN
curl https://$DOMAIN_NAME_FQDN/hello-world-one
curl https://$DOMAIN_NAME_FQDN/hello-world-two

# check the tls/ssl certificate
curl -v -k --resolve $DOMAIN_NAME_FQDN:443:$INGRESS_PUPLIC_IP https://$DOMAIN_NAME_FQDN
# * Added aks-app-02.westeurope.cloudapp.azure.com:443:20.103.29.0 to DNS cache
# * Hostname aks-app-02.westeurope.cloudapp.azure.com was found in DNS cache
# *   Trying 20.103.29.0:443...
# * Connected to aks-app-02.westeurope.cloudapp.azure.com (20.103.29.0) port 443 (#0)
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
# *  subject: CN=aks-app-02.westeurope.cloudapp.azure.com; O=aks-app-02.westeurope.cloudapp.azure.com
# *  start date: Nov 21 19:25:01 2022 GMT
# *  expire date: Nov 21 19:25:01 2023 GMT
# *  issuer: CN=aks-app-02.westeurope.cloudapp.azure.com; O=aks-app-02.westeurope.cloudapp.azure.com
# *  SSL certificate verify result: self-signed certificate (18), continuing anyway.
# * Using HTTP2, server supports multiplexing
# * Connection state changed (HTTP/2 confirmed)
# * Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
# * TLSv1.2 (OUT), TLS header, Supplemental data (23):
# * TLSv1.2 (OUT), TLS header, Supplemental data (23):
# * TLSv1.2 (OUT), TLS header, Supplemental data (23):
# * Using Stream ID: 1 (easy handle 0x55e929517e80)
# * TLSv1.2 (OUT), TLS header, Supplemental data (23):
# > GET / HTTP/2
# > Host: aks-app-02.westeurope.cloudapp.azure.com
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
# < date: Mon, 21 Nov 2022 19:29:31 GMT
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
# * Connection #0 to host aks-app-02.westeurope.cloudapp.azure.com left intact
# </html>
```