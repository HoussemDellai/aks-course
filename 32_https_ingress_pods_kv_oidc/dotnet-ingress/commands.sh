# demo: end to end https in AKS

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

kubectl get nodes

NAMESPACE_APP="dotnet-app"

kubectl create namespace $NAMESPACE_APP

# create TLS certificate for the Deployment

CERT_NAME="app-tls-cert"

SERVICE_NAME="app-svc"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out "${CERT_NAME}.crt" \
    -keyout "${CERT_NAME}.key" \
    -subj "/CN=$SERVICE_NAME.$NAMESPACE_APP.svc.cluster.local/O=aks-ingress-tls" \
    -addext "subjectAltName=DNS:$SERVICE_NAME.$NAMESPACE_APP.svc.cluster.local"

openssl pkcs12 -export -in "${CERT_NAME}.crt" -inkey "${CERT_NAME}.key" -out "${CERT_NAME}.pfx"

# save certificate into a kubernetes secret object

SECRET_TLS="app-tls-cert-secret"

kubectl create secret generic $SECRET_TLS --from-file="${CERT_NAME}.pfx" --namespace $NAMESPACE_APP

kubectl describe secret $SECRET_TLS --namespace $NAMESPACE_APP

# deploy sample application that uses the TLS secret to configure HTTPS

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

kubectl get pods,svc -n $NAMESPACE_APP

# verify TLS certificate is working

kubectl run nginx --image=nginx
kubectl exec -it nginx -- curl -v -k https://app-svc.dotnet-app.svc.cluster.local

# deploy ingress controller

NAMESPACE_INGRESS="ingress-nginx-app-07"
kubectl create namespace $NAMESPACE_INGRESS

# install Nginx ingress controller with custom name for the ingressClass

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

kubectl get ingressclass

kubectl get pods,svc -n $NAMESPACE_INGRESS

# capture ingress, public IP (Azure Public IP created)
INGRESS_PUPLIC_IP=$(kubectl get services ingress-$INGRESS_CLASS_NAME-controller -n $NAMESPACE_INGRESS -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $INGRESS_PUPLIC_IP

# configure Ingress' Public IP with DNS Name
DNS_NAME="app-07"

# Name to associate with Azure Public IP address

# Get the resource-id of the public IP
NODE_RG=$(az aks show -g $RG -n $AKS --query nodeResourceGroup -o tsv)
echo $NODE_RG

AZURE_PUBLIC_IP_ID=$(az network public-ip list -g $NODE_RG --query "[?ipAddress!=null]|[?contains(ipAddress, '$INGRESS_PUPLIC_IP')].[id]" -o tsv)
echo $AZURE_PUBLIC_IP_ID

# Update public IP address with DNS name
az network public-ip update --ids $AZURE_PUBLIC_IP_ID --dns-name $DNS_NAME
DOMAIN_NAME_FQDN=$(az network public-ip show --ids $AZURE_PUBLIC_IP_ID --query='dnsSettings.fqdn' -o tsv)
echo $DOMAIN_NAME_FQDN

# creating TLS certificate for ingress

INGRESS_CERT_NAME="ingress-tls-cert"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out "${INGRESS_CERT_NAME}.crt" \
    -keyout "${INGRESS_CERT_NAME}.key" \
    -subj "/CN=$DOMAIN_NAME_FQDN/O=aks-ingress-tls" \
    -addext "subjectAltName=DNS:$DOMAIN_NAME_FQDN"

INGRESS_SECRET_TLS="ingress-tls-cert-secret"

# save TLS certificate for ingress into kubernetes secret object

kubectl create secret tls $INGRESS_SECRET_TLS --cert="${INGRESS_CERT_NAME}.crt" --key="${INGRESS_CERT_NAME}.key" --namespace $NAMESPACE_APP

kubectl describe secret $INGRESS_SECRET_TLS --namespace $NAMESPACE_APP

# deploy an ingress that uses HTTPS

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

# check app is working with HTTPS
curl https://$DOMAIN_NAME_FQDN
curl https://$DOMAIN_NAME_FQDN/app

# check tls certificate
curl -v -k --resolve $DOMAIN_NAME_FQDN:443:$INGRESS_PUPLIC_IP https://$DOMAIN_NAME_FQDN