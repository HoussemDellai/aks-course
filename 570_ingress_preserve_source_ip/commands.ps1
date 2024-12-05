# create an AKS cluster
$AKS_RG="rg-aks-cluster"
$AKS_NAME="aks-cluster"

az group create -n $AKS_RG -l swedencentral

az aks create -g $AKS_RG -n $AKS_NAME --network-plugin azure --network-plugin-mode overlay

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

# verify connection to the cluster
kubectl get nodes

# install Nginx ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

NAMESPACE_INGRESS="ingress-nginx"

helm install ingress-nginx ingress-nginx/ingress-nginx `
     --create-namespace `
     --namespace $NAMESPACE_INGRESS `
     --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz `
     --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-port"=80 

kubectl get pods,deployments,services --namespace $NAMESPACE_INGRESS

$INGRESS_PUPLIC_IP=$(kubectl get services ingress-nginx-controller -n $NAMESPACE_INGRESS -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $INGRESS_PUPLIC_IP
# 20.103.25.154

kubectl apply -f app.yaml

curl $INGRESS_PUPLIC_IP

# check the "X-Forwarded-For" header in the response. It should contain the SNAT'd IP address of the client, which become the IP address of the node/vm.

# Enable "externalTrafficPolicy: Local" in the ingress controller service

kubectl patch svc ingress-nginx-controller -n $NAMESPACE_INGRESS -p '{"spec":{"externalTrafficPolicy":"Local"}}'

curl $INGRESS_PUPLIC_IP

# check the "X-Forwarded-For" and "X-Real-IP" headera in the response. They should contain the original client IP address.