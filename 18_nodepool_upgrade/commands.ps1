# 1. setup demo environment

az aks get-versions -l westeurope -o table
# KubernetesVersion    Upgrades
# -------------------  ------------------------
# 1.25.2(preview)      None available
# 1.24.6               1.25.2(preview)
# 1.24.3               1.24.6, 1.25.2(preview)
# 1.23.12              1.24.3, 1.24.6
# 1.23.8               1.23.12, 1.24.3, 1.24.6
# 1.22.15              1.23.8, 1.23.12
# 1.22.11              1.22.15, 1.23.8, 1.23.12

$VERSION_OLD="1.23.12"
$VERSION_NEW="1.24.6"

# variables
$AKS_RG="rg-aks-upgrade"
$AKS_NAME="aks-cluster"

# create and connect to cluster
az group create --name $AKS_RG --location westeurope

az aks create --name $AKS_NAME `
              --resource-group $AKS_RG `
              --node-count 3 `
              --kubernetes-version $VERSION_OLD

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes
# NAME                                STATUS   ROLES   AGE   VERSION
# aks-nodepool1-35994406-vmss000000   Ready    agent   29m   v1.24.6
# aks-nodepool1-35994406-vmss000001   Ready    agent   29m   v1.24.6
# aks-nodepool1-35994406-vmss000002   Ready    agent   25m   v1.24.6

# deploy stateless application
kubectl create deployment nginx --image=nginx --replicas=10 -o yaml --dry-run=client

kubectl create deployment nginx --image=nginx --replicas=10

# view pods running
kubectl get pods

# 2. start the cluster upgrade
az aks list -o table

# upgrade control plane only
echo $VERSION_NEW

az aks upgrade --kubernetes-version $VERSION_NEW `
               --name $AKS_NAME `
               --resource-group $AKS_RG

az aks nodepool list --cluster-name $AKS_NAME `
                     --resource-group $AKS_RG `
                     -o table

# check nginx pods
kubectl get pods


kubectl exec web-1 -it -- apt-get update
kubectl exec web-1 -it -- apt-get install dnsutils

kubectl exec web-1 -it -- nslookup nginx
# Server:         10.0.0.10
# Address:        10.0.0.10#53

# Name:   nginx.default.svc.cluster.local
# Address: 10.244.4.10
# Name:   nginx.default.svc.cluster.local
# Address: 10.244.5.6