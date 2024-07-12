# Create a self-signed SSL certificate to use with the Ingress
openssl req -new -x509 -nodes -out aks-ingress-tls.crt -keyout aks-ingress-tls.key -subj "/CN=houssemdellai01.com" -addext "subjectAltName=DNS:houssemdellai01.com"

# Export the SSL certificate
openssl pkcs12 -export -in aks-ingress-tls.crt -inkey aks-ingress-tls.key -out aks-ingress-tls.pfx
