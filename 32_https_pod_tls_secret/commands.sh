# demo: end to end https in AKS

# create an AKS cluster
AKS_RG="rg-aks-demo-tls"
AKS_NAME="aks-cluster"

az group create -n $AKS_RG -l westeurope

az aks create -g $AKS_RG -n $AKS_NAME \
              --kubernetes-version "1.25.2" \
              --enable-managed-identity \
              --node-count 2 \
              --network-plugin azure

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes

NAMESPACE_APP="dotnet-app"

kubectl create namespace $NAMESPACE_APP

# create TLS certificate for the Deployment

APP_CERT_NAME="app-tls-cert"

SERVICE_NAME="app-svc"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out "${APP_CERT_NAME}.crt" \
    -keyout "${APP_CERT_NAME}.key" \
    -subj "/CN=$SERVICE_NAME.$NAMESPACE_APP.svc.cluster.local/O=aks-ingress-tls" \
    -addext "subjectAltName=DNS:$SERVICE_NAME.$NAMESPACE_APP.svc.cluster.local"

openssl pkcs12 -export -in "${APP_CERT_NAME}.crt" -inkey "${APP_CERT_NAME}.key" -out "${APP_CERT_NAME}.pfx"

# save certificate into a kubernetes secret object

APP_SECRET_TLS="app-tls-cert-secret"

kubectl create secret generic $APP_SECRET_TLS --from-file="${APP_CERT_NAME}.pfx" --namespace $NAMESPACE_APP

kubectl describe secret $APP_SECRET_TLS --namespace $NAMESPACE_APP

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
          secretName: $APP_SECRET_TLS
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
          value: /secrets/tls-cert/$APP_CERT_NAME.pfx
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