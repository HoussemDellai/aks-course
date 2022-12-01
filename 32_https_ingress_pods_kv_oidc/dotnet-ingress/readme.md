
create an AKS cluster

```bash
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
```

Create TLS certificate

```bash
CERT_NAME="app-tls-cert"

SERVICE_NAME="app-svc"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out "${CERT_NAME}.crt" \
    -keyout "${CERT_NAME}.key" \
    -subj "/CN=$SERVICE_NAME.$NAMESPACE_APP.svc.cluster.local/O=aks-ingress-tls" \
    -addext "subjectAltName=DNS:$SERVICE_NAME.$NAMESPACE_APP.svc.cluster.local"

openssl pkcs12 -export -in "${CERT_NAME}.crt" -inkey "${CERT_NAME}.key" -out "${CERT_NAME}.pfx"
```

Save TLS certificate into Secret generic object

```bash
SECRET_TLS="app-tls-cert-secret"

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
```

Create sample deployment object that uses TLS certificate from secret to cnfigure HTTPS.
The configuration for the TLS certificate depends on the platform/app. 
Nodejs, Java and others might define a different set of env variables to configure certificate.

```bash
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
```

Verify HTTPS is working

```bash
kubectl run nginx --image=nginx
kubectl exec -it nginx -- curl -v -k https://app-svc.dotnet-app.svc.cluster.local
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
# ...
```

deploy Nginx ingress controller with custom name into a dedicated namespace

```bash
NAMESPACE_INGRESS="ingress-nginx-app-07"
kubectl create namespace $NAMESPACE_INGRESS
# namespace/ingress-nginx-app-07 created

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
```

Nginx Ingress controller created a new Azure Public IP to receive ingress traffic.
This Azure Public IP offer a sub-domain name in form of <unique DNS NAME>.westeurope.cloudapp.azure.com.
It resolves to the public IP.
We'll reuse that as our host in this demo.
In production, we should use Azure DNS Zone to use our own custom domain name.

Configure Ingress' Public IP with DNS Name

```bash
# capture ingress, public IP (Azure Public IP created)
INGRESS_PUPLIC_IP=$(kubectl get services ingress-$INGRESS_CLASS_NAME-controller -n $NAMESPACE_INGRESS -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $INGRESS_PUPLIC_IP
# 20.101.208.164

DNS_NAME="app-07" # this name should be unique for the subdomain: <unique DNS NAME>.westeurope.cloudapp.azure.com

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
```

Creating TLS certificate for ingress

```bash
INGRESS_CERT_NAME="ingress-tls-cert"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out "${INGRESS_CERT_NAME}.crt" \
    -keyout "${INGRESS_CERT_NAME}.key" \
    -subj "/CN=$DOMAIN_NAME_FQDN/O=aks-ingress-tls" \
    -addext "subjectAltName=DNS:$DOMAIN_NAME_FQDN"
```

Save TLS certificate into secret

```bash
INGRESS_SECRET_TLS="ingress-tls-cert-secret"

kubectl create secret tls $INGRESS_SECRET_TLS --cert="${INGRESS_CERT_NAME}.crt" --key="${INGRESS_CERT_NAME}.key" --namespace $NAMESPACE_APP
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
```

Create an Ingress resource that uses HTTPS

```bash
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
```

Check tls certificate for ingress

```bash
curl -v -k --resolve $DOMAIN_NAME_FQDN:443:$INGRESS_PUPLIC_IP https://$DOMAIN_NAME_FQDN
```