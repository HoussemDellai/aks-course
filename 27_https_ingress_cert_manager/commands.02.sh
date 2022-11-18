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

NAMESPACE_INGRESS="ingress-nginx-app-02"
INGRESS_CLASS_NAME="nginx-app-02"

helm upgrade --install ingress-nginx-app-02 ingress-nginx/ingress-nginx --create-namespace --namespace $NAMESPACE_INGRESS \
--set controller.replicaCount=2 \
--set controller.nodeSelector."kubernetes\.io/os"=linux \
-f - <<EOF
controller:
  ingressClassResource:
    name: $INGRESS_CLASS_NAME # default: nginx
    enabled: true
    default: false
    controllerValue: "k8s.io/ingress-$INGRESS_CLASS_NAME"
EOF

kubectl get services --namespace $NAMESPACE_INGRESS
# NAME                                        TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)                      AGE
# ingress-nginx-app-02-controller             LoadBalancer   10.0.233.36   20.101.30.39   80:31691/TCP,443:31211/TCP   11s
# ingress-nginx-app-02-controller-admission   ClusterIP      10.0.210.58   <none>         443/TCP                      11s

# capture ingress, public IP (Azure Public IP created)
INGRESS_PUPLIC_IP=$(kubectl get services ingress-$INGRESS_CLASS_NAME-controller -n $NAMESPACE_INGRESS -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $INGRESS_PUPLIC_IP
# 20.101.30.39

# get the ingress class resources, note we already have one deployed in another demo
kubectl get ingressclass
# NAME           CONTROLLER                    PARAMETERS   AGE
# nginx          k8s.io/ingress-nginx          <none>       168m
# nginx-app-02   k8s.io/ingress-nginx-app-02   <none>       69s

NAMESPACE_APP_02="app-02"
kubectl create namespace $NAMESPACE_APP_02

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

kubectl apply -f aks-helloworld-one.yaml --namespace $NAMESPACE_APP_02
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

kubectl apply -f aks-helloworld-two.yaml --namespace $NAMESPACE_APP_02
# deployment.apps/aks-helloworld-two created
# service/aks-helloworld-two created

# configure Ingress' Public IP with DNS Name
az network public-ip update -g MC_rg-aks-we_aks-cluster_westeurope -n kubernetes-af54fcf50c6b24d7fbb9ed6aa62bdc77 --dns-name aks-app-02
# {
#   "ddosSettings": {
#     "protectionMode": "VirtualNetworkInherited"
#   },
#   "dnsSettings": {
#     "domainNameLabel": "aks-app-02",
#     "fqdn": "aks-app-02.westeurope.cloudapp.azure.com"
#   },
#   "etag": "W/\"1d9ccec0-6672-48ac-883b-8ad3a3b487e3\"",
#   "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/MC_rg-aks-we_aks-cluster_westeurope/providers/Microsoft.Network/publicIPAddresses/kubernetes-af54fcf50c6b24d7fbb9ed6aa62bdc77",
#   "idleTimeoutInMinutes": 4,
#   "ipAddress": "20.101.30.39",
#   "ipConfiguration": {
#     "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/mc_rg-aks-we_aks-cluster_westeurope/providers/Microsoft.Network/loadBalancers/kubernetes/frontendIPConfigurations/af54fcf50c6b24d7fbb9ed6aa62bdc77",
#     "resourceGroup": "mc_rg-aks-we_aks-cluster_westeurope"
#   },
#   "ipTags": [],
#   "location": "westeurope",
#   "name": "kubernetes-af54fcf50c6b24d7fbb9ed6aa62bdc77",
#   "provisioningState": "Succeeded",
#   "publicIPAddressVersion": "IPv4",
#   "publicIPAllocationMethod": "Static",
#   "resourceGroup": "MC_rg-aks-we_aks-cluster_westeurope",
#   "resourceGuid": "d0b81369-691c-404e-99fd-640415a9d2a4",
#   "sku": {
#     "name": "Standard",
#     "tier": "Regional"
#   },
#   "tags": {
#     "k8s-azure-cluster-name": "kubernetes",
#     "k8s-azure-service": "ingress-nginx-app-02/ingress-nginx-app-02-controller"
#   },
#   "type": "Microsoft.Network/publicIPAddresses",
#   "zones": [
#     "2",
#     "3",
#     "1"
#   ]
# }


# Name to associate with public IP address
DNS_NAME="aks-app-02"

# Get the resource-id of the public IP
AZURE_PUBLIC_IP_ID=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$INGRESS_PUPLIC_IP')].[id]" --output tsv)

# Update public IP address with DNS name
az network public-ip update --ids $AZURE_PUBLIC_IP_ID --dns-name $DNS_NAME
# az network public-ip update -g MC_rg-aks-we_aks-cluster_westeurope -n kubernetes-af54fcf50c6b24d7fbb9ed6aa62bdc77 --dns-name $DNS_NAME
DOMAIN_NAME_FQDN=$(az network public-ip show --ids $AZURE_PUBLIC_IP_ID --query='dnsSettings.fqdn')
# DOMAIN_NAME_FQDN=$(az network public-ip show -g MC_rg-aks-we_aks-cluster_westeurope -n kubernetes-af54fcf50c6b24d7fbb9ed6aa62bdc77 --query='dnsSettings.fqdn')
echo $DOMAIN_NAME_FQDN
# "aks-app-02.westeurope.cloudapp.azure.com"

# create TLS/SSL certificate
CERT_NAME=aks-ingress-cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out aks-ingress-tls.crt \
    -keyout aks-ingress-tls.key \
    -subj "/CN=$DOMAIN_NAME_FQDN/O=aks-ingress-tls" \
    -addext "subjectAltName = DNS:$DOMAIN_NAME_FQDN"

ls
# aks-helloworld-one.yaml  aks-helloworld-two.yaml  aks-ingress-tls.crt  aks-ingress-tls.key  cert_issuer.yaml  commands.02.sh  hello-world-ingress-tls.yaml

TLS_SECRET="tls-ingress-app-02-secret"

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
# tls.crt:  1273 bytes
# tls.key:  1704 bytes

cat <<EOF >hello-world-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/use-regex: "true"
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
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /static/$2
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

kubectl apply -f hello-world-ingress.yaml --namespace $NAMESPACE_APP_02
# ingress.networking.k8s.io/hello-world-ingress created
# ingress.networking.k8s.io/hello-world-ingress-static created

kubectl get ingress --namespace $NAMESPACE_APP_02
# NAME                         CLASS          HOSTS                                      ADDRESS   PORTS     AGE
# hello-world-ingress          nginx-app-02   aks-app-02.westeurope.cloudapp.azure.com             80, 443   12s
# hello-world-ingress-static   nginx-app-02   aks-app-02.westeurope.cloudapp.azure.com             80, 443   11s

kubectl get pods --namespace $NAMESPACE_APP_02
# NAME                                  READY   STATUS    RESTARTS   AGE
# aks-helloworld-one-749789b6c5-tlgsm   1/1     Running   0          113m
# aks-helloworld-two-5b8d45b8bf-scp8g   1/1     Running   0          113m

kubectl get svc --namespace $NAMESPACE_APP_02
# NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
# aks-helloworld-one   ClusterIP   10.0.40.82   <none>        80/TCP    113m
# aks-helloworld-two   ClusterIP   10.0.54.42   <none>        80/TCP    113m

# check app is working with HTTPS
curl https://$INGRESS_PUPLIC_IP

# check the tls/ssl certificate
curl -v -k --resolve $DOMAIN_NAME_FQDN:443:$INGRESS_PUPLIC_IP https://$DOMAIN_NAME_FQDN





# Configure HTTPS for Ingress resources

# install cert-manager

# Label the ingress-basic namespace to disable resource validation
kubectl label namespace $NAMESPACE_APP_02 cert-manager.io/disable-validation=true
# namespace/ingress-basic labeled
# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io
# Update your local Helm chart repository cache
helm repo update
# Install the cert-manager Helm chart
helm install cert-manager jetstack/cert-manager --namespace  $NAMESPACE_APP_02 --create-namespace --set installCRDs=true

kubectl apply -f issuer.yaml -n $NAMESPACE_APP_02
# issuer.cert-manager.io/letsencrypt created

kubectl get issuer -n  $NAMESPACE_APP_02
# NAME          READY   AGE
# letsencrypt   True    56s

kubectl apply -f hello-world-ingress-tls.yaml --namespace  $NAMESPACE_APP_02
# ingress.networking.k8s.io/hello-world-ingress created
# ingress.networking.k8s.io/hello-world-ingress-static created

kubectl get ingress -n  $NAMESPACE_APP_02
# NAME                         CLASS    HOSTS                                      ADDRESS   PORTS     AGE
# cm-acme-http-solver-qccmx    <none>   aks-app-01.westeurope.cloudapp.azure.com             80        4s
# hello-world-ingress          nginx    aks-app-01.westeurope.cloudapp.azure.com             80, 443   7s
# hello-world-ingress-static   nginx    aks-app-01.westeurope.cloudapp.azure.com             80, 443   7s

kubectl get certificate --namespace  $NAMESPACE_APP_02
# NAME         READY   SECRET       AGE
# tls-secret   False   tls-secret   4m10s