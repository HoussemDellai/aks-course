# create an AKS cluster
AKS_RG="AKS_RG-aks-we"
AKS_NAME="aks-cluster"

az group create -n $AKS_RG -l westeurope

az aks create -g $AKS_RG -n $AKS_NAME --network-plugin azure --kubernetes-version "1.25.2" --node-count 2

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

# verify connection to the cluster
kubectl get nodes

# install Nginx ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

NAMESPACE_INGRESS="ingress-nginx"

helm install ingress-nginx ingress-nginx/ingress-nginx \
     --create-namespace \
     --namespace $NAMESPACE_INGRESS \
     --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz

kubectl get pods,deployments,services --namespace $NAMESPACE_INGRESS
# NAME                                            READY   STATUS    RESTARTS   AGE
# pod/ingress-nginx-controller-8574b6d7c9-vdst4   1/1     Running   0          80s

# NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/ingress-nginx-controller   1/1     1            1           81s

# NAME                                         TYPE           CLUSTER-IP   EXTERNAL-IP       PORT(S)                      AGE
# service/ingress-nginx-controller             LoadBalancer   10.0.77.46   20.103.25.154     80:30957/TCP,443:31673/TCP   82s
# service/ingress-nginx-controller-admission   ClusterIP      10.0.1.153   <none>            443/TCP                      82s

INGRESS_PUPLIC_IP=$(kubectl get services ingress-nginx-controller -n $NAMESPACE_INGRESS -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $INGRESS_PUPLIC_IP
# 20.103.25.154

NAMESPACE_APP_01="app-01"
kubectl create namespace $NAMESPACE_APP_01
# namespace/app-01 created

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

kubectl apply -f aks-helloworld-one.yaml --namespace $NAMESPACE_APP_01
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

kubectl apply -f aks-helloworld-two.yaml --namespace $NAMESPACE_APP_01
# deployment.apps/aks-helloworld-two created
# service/aks-helloworld-two created

cat <<EOF >hello-world-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-taAKS_RGet: /\$2
spec:
  ingressClassName: nginx
  rules:
  - http:
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
    nginx.ingress.kubernetes.io/rewrite-taAKS_RGet: /static/\$2
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /static(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: aks-helloworld-one
            port: 
              number: 80
EOF

kubectl apply -f hello-world-ingress.yaml --namespace $NAMESPACE_APP_01
# ingress.networking.k8s.io/hello-world-ingress created
# ingress.networking.k8s.io/hello-world-ingress-static created

kubectl get pods,svc,ingress --namespace $NAMESPACE_APP_01
# NAME                                      READY   STATUS    RESTARTS   AGE
# pod/aks-helloworld-one-749789b6c5-9989d   1/1     Running   0          4m21s
# pod/aks-helloworld-two-5b8d45b8bf-zxlsd   1/1     Running   0          4m20s

# NAME                         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
# service/aks-helloworld-one   ClusterIP   10.0.65.14     <none>        80/TCP    4m21s
# service/aks-helloworld-two   ClusterIP   10.0.136.130   <none>        80/TCP    4m20s

# NAME                                                   CLASS   HOSTS   ADDRESS         PORTS   AGE
# ingress.networking.k8s.io/hello-world-ingress          nginx   *       20.103.25.154   80      59s
# ingress.networking.k8s.io/hello-world-ingress-static   nginx   *       20.103.25.154   80      59s

# check app is running behind Nginx Ingress Controller (with no HTTPS)
curl http://$INGRESS_PUPLIC_IP
curl http://$INGRESS_PUPLIC_IP/aks-helloworld-one
curl http://$INGRESS_PUPLIC_IP/aks-helloworld-two

# Mapping a domain name (Azure Public IP)

DNS_NAME="aks-app-01"

###########################################################
# Option 1: Name to associate with Azure Public IP address

# Get the resource-id of the public IP
AZURE_PUBLIC_IP_ID=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$INGRESS_PUPLIC_IP')].[id]" -o tsv)
echo $AZURE_PUBLIC_IP_ID

# Update public IP address with DNS name
az network public-ip update --ids $AZURE_PUBLIC_IP_ID --dns-name $DNS_NAME
DOMAIN_NAME_FQDN=$(az network public-ip show --ids $AZURE_PUBLIC_IP_ID --query='dnsSettings.fqdn' -o tsv)
# DOMAIN_NAME_FQDN=$(az network public-ip show -g MC_AKS_RG-aks-we_aks-cluster_westeurope -n kubernetes-af54fcf50c6b24d7fbb9ed6aa62bdc77 --query='dnsSettings.fqdn')
echo $DOMAIN_NAME_FQDN
# aks-app-01.westeurope.cloudapp.azure.com

###########################################################
# Option 2: Name to associate with Azure DNS Zone

# Add an A record to your DNS zone
az network dns record-set a add-record \
    --resource-group AKS_RG-houssem-cloud-dns \
    --zone-name "houssem.cloud" \
    --record-set-name "*" \
    --ipv4-address $INGRESS_PUPLIC_IP

# az network public-ip update -g MC_AKS_RG-aks-we_aks-cluster_westeurope -n kubernetes-af54fcf50c6b24d7fbb9ed6aa62bdc77 --dns-name $DNS_NAME
DOMAIN_NAME_FQDN=$DNS_NAME.houssem.cloud
echo $DOMAIN_NAME_FQDN
# aks-app-03.houssem.cloud

# check app is working with FQDN (http, not https)
curl http://$DOMAIN_NAME_FQDN
curl http://$DOMAIN_NAME_FQDN/hello-world-one
curl http://$DOMAIN_NAME_FQDN/hello-world-two