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
  replicas: 1
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
      # - ASPNETCORE_ENVIRONMENT=Development
        - name: ASPNETCORE_URLS
          value: "https://+:443;http://+:80"
EOF

kubectl apply -f app-deploy.yaml -n $NAMESPACE_APP
# service/app-svc created
# deployment.apps/demo-app created

curl -v -k https://demo-app.nginx.svc.cluster.local
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