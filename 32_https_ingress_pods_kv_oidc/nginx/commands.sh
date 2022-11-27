kubectl create namespace nginx

kubectl apply -f backend -n nginx

CERT_NAME="aks-ingress-cert"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out aks-ingress-tls.crt \
    -keyout aks-ingress-tls.key \
    -subj "/CN=demo-app.nginx.svc.cluster.local/O=aks-ingress-tls" \
    -addext "subjectAltName=DNS:demo-app.nginx.svc.cluster.local"

openssl pkcs12 -export -in aks-ingress-tls.crt -inkey aks-ingress-tls.key -out "${CERT_NAME}.pfx"

kubectl create secret tls $TLS_SECRET --cert=aks-ingress-tls.crt --key=aks-ingress-tls.key --namespace nginx

curl -v -k https://demo-app.nginx.svc.cluster.local