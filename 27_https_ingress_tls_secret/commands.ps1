# create an AKS cluster
$AKS_RG="rg-aks-tls"
$AKS_NAME="aks-cluster"

az group create -n $AKS_RG -l westeurope

az aks create -g $AKS_RG -n $AKS_NAME --network-plugin azure --kubernetes-version "1.25.2" --node-count 2

az aks get-credentials --name $AKS_NAME -g $AKS_RG --overwrite-existing

# verify connection to the cluster
kubectl get nodes

# install Nginx ingress controller with custom ingress class name
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

kubectl get pods,services --namespace $NAMESPACE_INGRESS

# capture ingress, public IP (Azure Public IP created)
$INGRESS_PUPLIC_IP=$(kubectl get services ingress-$INGRESS_CLASS_NAME-controller -n $NAMESPACE_INGRESS -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $INGRESS_PUPLIC_IP

# get the ingress class resources, note we already have one deployed in another demo
kubectl get ingressclass

$NAMESPACE_APP_02="app-02"

kubectl create namespace $NAMESPACE_APP_02

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

# configure Ingress' Public IP with DNS Name

###########################################################
# Option 1: Name to associate with Azure Public IP address
$DNS_NAME="aks-app-02"

$NODE_RG=$(az aks show -g $AKS_RG -n $AKS_NAME --query nodeResourceGroup -o tsv)
echo $NODE_RG

# Get the resource-id of the public IP
$AZURE_PUBLIC_IP_ID=$(az network public-ip list -g $NODE_RG --query "[?ipAddress!=null]|[?contains(ipAddress, '$INGRESS_PUPLIC_IP')].[id]" -o tsv)
echo $AZURE_PUBLIC_IP_ID

# Update public IP address with DNS name
az network public-ip update --ids $AZURE_PUBLIC_IP_ID --dns-name $DNS_NAME

$DOMAIN_NAME_FQDN=$(az network public-ip show --ids $AZURE_PUBLIC_IP_ID --query='dnsSettings.fqdn' -o tsv)
echo $DOMAIN_NAME_FQDN

###########################################################
# Option 2: Name to associate with Azure DNS Zone
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


# create TLS/SSL certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 `
    -out aks-ingress-tls.crt `
    -keyout aks-ingress-tls.key `
    -subj "/CN=${DOMAIN_NAME_FQDN}/O=${DOMAIN_NAME_FQDN}" `
    -addext "subjectAltName = DNS:${DOMAIN_NAME_FQDN}"

ls

$TLS_SECRET="tls-ingress-app-02-secret"

kubectl create secret tls $TLS_SECRET --cert=aks-ingress-tls.crt --key=aks-ingress-tls.key --namespace $NAMESPACE_APP_02

kubectl describe secret $TLS_SECRET --namespace $NAMESPACE_APP_02

# create ingress resoure

@"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /`$2
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
    nginx.ingress.kubernetes.io/rewrite-target: /static/`$2
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

kubectl get ingress --namespace $NAMESPACE_APP_02

# check app is working with HTTPS
curl https://$DOMAIN_NAME_FQDN
curl https://$DOMAIN_NAME_FQDN/hello-world-one
curl https://$DOMAIN_NAME_FQDN/hello-world-two

# check the tls/ssl certificate
curl -v -k --resolve $DOMAIN_NAME_FQDN:443:$INGRESS_PUPLIC_IP https://$DOMAIN_NAME_FQDN