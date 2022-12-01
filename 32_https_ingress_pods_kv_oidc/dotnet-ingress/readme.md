
# create an AKS cluster
RG="rg-aks-demo-tls"
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

NAMESPACE_APP="dotnet-app"

kubectl create namespace $NAMESPACE_APP

CERT_NAME="app-tls-cert"

SERVICE_NAME="app-svc"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out "${CERT_NAME}.crt" \
    -keyout "${CERT_NAME}.key" \
    -subj "/CN=$SERVICE_NAME.$NAMESPACE_APP.svc.cluster.local/O=aks-ingress-tls" \
    -addext "subjectAltName=DNS:$SERVICE_NAME.$NAMESPACE_APP.svc.cluster.local"

openssl pkcs12 -export -in "${CERT_NAME}.crt" -inkey "${CERT_NAME}.key" -out "${CERT_NAME}.pfx"

SECRET_TLS="app-tls-cert-secret"

# kubectl create secret tls $SECRET_TLS --cert="${CERT_NAME}.crt" --key="${CERT_NAME}.key" --namespace $NAMESPACE_APP
# secret/app-tls-cert-secret created

kubectl create secret generic $SECRET_TLS --from-file="${CERT_NAME}.pfx" --namespace $NAMESPACE_APP
# secret/app-tls-cert-secret created

kubectl describe secret $SECRET_TLS --namespace $NAMESPACE_APP
# Name:         app-tls-cert-secret
# Namespace:    dotnet-app
# Labels:       <none>
# Annotations:  <none>

# Type:  kubernetes.io/tls

# Data
# ====
# tls.crt:  1326 bytes
# tls.key:  1704 bytes

cat <<EOF >app-deploy.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: demo-app
  name: $SERVICE_NAME
spec:
  ports:
  - port: 443
    protocol: TCP
    targetPort: 443
  selector:
    app: demo-app
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: demo-app
  name: demo-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      restartPolicy: Always
      volumes:
      - name: demo-app-tls
        secret:
          secretName: $SECRET_TLS
      containers:
      - name: demo-app
        image: mcr.microsoft.com/dotnet/samples:aspnetapp
        ports:
        - containerPort: 443
        volumeMounts:
        - name: demo-app-tls
          mountPath: /secrets/tls-cert
          readOnly: true
        env:
        - name: ASPNETCORE_Kestrel__Certificates__Default__Password
          value: ""
        - name: ASPNETCORE_Kestrel__Certificates__Default__Path
          value: /secrets/tls-cert/$CERT_NAME.pfx
        - name: ASPNETCORE_URLS
          value: "https://+;http://+" # "https://+:443;http://+:80"
        - name: ASPNETCORE_HTTPS_PORT
          value: "443"
EOF

kubectl apply -f app-deploy.yaml -n $NAMESPACE_APP
# service/app-svc created
# deployment.apps/demo-app created

kubectl get pods,svc -n $NAMESPACE_APP
# NAME                            READY   STATUS    RESTARTS   AGE
# pod/demo-app-69b8774746-9v8mm   1/1     Running   0          2m8s

# NAME              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
# service/app-svc   ClusterIP   10.0.179.173   <none>        443/TCP   2m9s

curl -v -k https://app-svc.dotnet-app.svc.cluster.local
# * Trying 10.0.154.220:443...
# * Connected to app-svc.dotnet-app.svc.cluster.local (10.0.154.220) port 443 (#0)
# * ALPN, offering h2
# * ALPN, offering http/1.1
# * successfully set certificate verify locations:
# *  CAfile: /etc/ssl/certs/ca-certificates.crt
# *  CApath: /etc/ssl/certs
# * TLSv1.3 (OUT), TLS handshake, Client hello (1):
# * TLSv1.3 (IN), TLS handshake, Server hello (2):
# * TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
# * TLSv1.3 (IN), TLS handshake, Certificate (11):
# * TLSv1.3 (IN), TLS handshake, CERT verify (15):
# * TLSv1.3 (IN), TLS handshake, Finished (20):
# * TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
# * TLSv1.3 (OUT), TLS handshake, Finished (20):
# * SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
# * ALPN, server accepted to use h2
# * Server certificate:
# *  subject: CN=app-svc.dotnet-app.svc.cluster.local; O=aks-ingress-tls
# *  start date: Nov 27 12:44:43 2022 GMT
# *  expire date: Nov 27 12:44:43 2023 GMT
# *  issuer: CN=app-svc.dotnet-app.svc.cluster.local; O=aks-ingress-tls
# *  SSL certificate verify result: self signed certificate (18), continuing anyway.
# * Using HTTP2, server supports multi-use
# * Connection state changed (HTTP/2 confirmed)
# * Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
# * Using Stream ID: 1 (easy handle 0x55e4e75262c0)
# > GET / HTTP/2
# > Host: app-svc.dotnet-app.svc.cluster.local
# > user-agent: curl/7.74.0
# > accept: */*
# >
# * TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
# * TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
# * old SSL session ID is stale, removing
# * Connection state changed (MAX_CONCURRENT_STREAMS == 100)!
# < HTTP/2 200
# < content-type: text/html; charset=utf-8
# < date: Sun, 27 Nov 2022 14:17:00 GMT
# < server: Kestrel
# < strict-transport-security: max-age=2592000
# <
# <!DOCTYPE html>
# <html lang="en">
# <head>
#     <meta charset="utf-8" />
#     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
#     <title>Home page - aspnetapp</title>
#     <link rel="stylesheet" href="/lib/bootstrap/dist/css/bootstrap.min.css" />
#     <link rel="stylesheet" href="/css/site.css?v=AKvNjO3dCPPS0eSU1Ez8T2wI280i08yGycV9ndytL-c" />
#     <link rel="stylesheet" href="/aspnetapp.styles.css?v=dmaWIJMtYHjABWevZ_2Q8P4v1xrVPOBMkiL86DlKmX8" />
# </head>
# <body>
#     <header>
#         <nav b-o45o6oy0cw class="navbar navbar-expand-sm navbar-toggleable-sm navbar-light bg-white border-bottom box-shadow mb-3">
#             <div b-o45o6oy0cw class="container-fluid">
#                 <a class="navbar-brand" href="/">aspnetapp</a>
#                 <button b-o45o6oy0cw class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target=".navbar-collapse" aria-controls="navbarSupportedContent"
#                         aria-expanded="false" aria-label="Toggle navigation">
#                     <span b-o45o6oy0cw class="navbar-toggler-icon"></span>
#                 </button>
#                 <div b-o45o6oy0cw class="navbar-collapse collapse d-sm-inline-flex justify-content-between">
#                     <ul b-o45o6oy0cw class="navbar-nav flex-grow-1">
#                         <li b-o45o6oy0cw class="nav-item">
#                             <a class="nav-link text-dark" href="/">Home</a>
#                         </li>
#                         <li b-o45o6oy0cw class="nav-item">
#                             <a class="nav-link text-dark" href="/Home/Privacy">Privacy</a>
#                         </li>
#                     </ul>
#                 </div>
#             </div>
#         </nav>
#     </header>
#     <div b-o45o6oy0cw class="container">
#         <main b-o45o6oy0cw role="main" class="pb-3">

# <div class="text-center">
#     <h1>Welcome to .NET</h1>
# </div>

# <div align="center">
#     <table class="table table-striped table-hover">
#         <tr>
#             <td>.NET version</td>
#             <td>.NET 7.0.0</td>
#         </tr>
#         <tr>
#             <td>Operating system</td>
#             <td>Linux 5.15.0-1022-azure #27-Ubuntu SMP Thu Oct 13 17:09:33 UTC 2022</td>
#         </tr>
#         <tr>
#             <td>Processor architecture</td>
#             <td>X64</td>
#         </tr>
#         <tr>
#             <td>CPU cores</td>
#             <td>2</td>
#         </tr>
#         <tr>
#             <td>Containerized</td>
#             <td>true</td>
#         </tr>
#         <tr>
#             <td>Memory, total available GC memory</td>
#             <td>6.78 GiB</td>
#         </tr>
#         <tr>
#             <td>Host name</td>
#             <td>demo-app-69b8774746-m9wxv</td>
#         </tr>
#         <tr>
#             <td style="vertical-align: top">Server IP address</td>
#             <td>
# 10.224.0.48                        <br />
# fe80::48d6:f9ff:fefb:d5a9%29                        <br />

#             </td>
#         </tr>
#     </table>
# </div>


#         </main>
#     </div>

#     <footer b-o45o6oy0cw class="border-top footer text-muted">
#         <div b-o45o6oy0cw class="container">
#             &copy; 2022 - aspnetapp - <a href="/Home/Privacy">Privacy</a>
#         </div>
#     </footer>
#     <script src="/lib/jquery/dist/jquery.min.js"></script>
#     <script src="/lib/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
#     <script src="/js/site.js?v=4q1jwFhaPaZgr8WAUSrux6hAuh0XDg9kPS3xIVq36I0"></script>

# </body>
# </html>
# * Connection #0 to host app-svc.dotnet-app.svc.cluster.local left intact

# deploy ingress controller


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
DNS_NAME="app-07"

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
# aks-app-07.westeurope.cloudapp.azure.com

# creating certificate and ingress

INGRESS_CERT_NAME="ingress-tls-cert"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out "${INGRESS_CERT_NAME}.crt" \
    -keyout "${INGRESS_CERT_NAME}.key" \
    -subj "/CN=$DOMAIN_NAME_FQDN/O=aks-ingress-tls" \
    -addext "subjectAltName=DNS:$DOMAIN_NAME_FQDN"

# openssl pkcs12 -export -in "${INGRESS_CERT_NAME}.crt" -inkey "${INGRESS_CERT_NAME}.key" -out "${INGRESS_CERT_NAME}.pfx"

INGRESS_SECRET_TLS="ingress-tls-cert-secret"

kubectl create secret tls $INGRESS_SECRET_TLS --cert="${INGRESS_CERT_NAME}.crt" --key="${INGRESS_CERT_NAME}.key" --namespace $NAMESPACE_APP
# secret/app-tls-cert-secret created

# kubectl create secret generic $SECRET_TLS --from-file="${INGRESS_CERT_NAME}.pfx" --namespace $NAMESPACE_APP
# secret/app-tls-cert-secret created

kubectl describe secret $INGRESS_SECRET_TLS --namespace $NAMESPACE_APP
# secret/ingress-tls-cert-secret created
# Name:         ingress-tls-cert-secret
# Namespace:    dotnet-app
# Labels:       <none>
# Annotations:  <none>

# Type:  kubernetes.io/tls

# Data
# ====
# tls.crt:  1326 bytes
# tls.key:  1704 bytes

cat <<EOF >app-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /\$2
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: $INGRESS_CLASS_NAME # nginx
  tls:
  - hosts:
    - $DOMAIN_NAME_FQDN
    secretName: $INGRESS_SECRET_TLS
  rules:
  - host: $DOMAIN_NAME_FQDN
    http:
      paths:
      - path: /app(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: $SERVICE_NAME
            port:
              number: 443 # 80
      - path: /(.*)
        pathType: Prefix
        backend:
          service:
            name: $SERVICE_NAME
            port:
              number: 443 # 80
EOF

kubectl apply -f app-ingress.yaml --namespace $NAMESPACE_APP

kubectl get ingress --namespace $NAMESPACE_APP
# NAME                  CLASS          HOSTS                                      ADDRESS        PORTS     AGE
# hello-world-ingress   nginx-app-07   aks-app-07.westeurope.cloudapp.azure.com   20.23.44.216   80, 443   64s

# check app is working with HTTPS
curl https://$DOMAIN_NAME_FQDN
curl https://$DOMAIN_NAME_FQDN/app

# check tls certificate
curl -v -k --resolve $DOMAIN_NAME_FQDN:443:$INGRESS_PUPLIC_IP https://$DOMAIN_NAME_FQDN

