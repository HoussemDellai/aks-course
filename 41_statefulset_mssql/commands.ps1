# 0. setup demo environment

# variables
$AKS_RG="rg-aks-stateful"
$AKS_NAME="aks-cluster"

# create and connect to AKS cluster
az group create --name $AKS_RG --location westeurope

az aks create --name $AKS_NAME `
              --resource-group $AKS_RG `
              --node-count 3

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes

# 1. deploy statefulset, service and webapp

# check the YAML manifest files in vs code
code app-deploy-svc.yaml
code db-statefulset-svc.yaml

kubectl apply -f .

kubectl get sts,pod,svc,pv,pvc

# 2. check app can connect to the database (browse to web app public IP)

# check the database created successfully

kubectl exec db-statefulset-0 -it -- ls /var/opt/mssql/data

# 3. check the created resources in Azure:
# Azure Disk (CSI) and Public IP.

# 4. check the DNS resolution for the headless service

kubectl run nginx --image=nginx
kubectl exec nginx -it -- apt-get update
kubectl exec nginx -it -- apt-get install dnsutils

kubectl exec nginx -it -- nslookup mssql-service

# note how each pod will have its own network identity

kubectl exec nginx -it -- nslookup db-statefulset-0.mssql-service

# 5. let us scale the StatefulSet

kubectl scale --replicas=3 statefulset/db-statefulset

# note how each replicas have its own PV and PVC

kubectl get sts,pod,svc,pv,pvc

# each pod still have its own IP address and might be deployed in a different node
# note how each pod have well defined name, that name will be used later for DNS resolution to target a specific pod

kubectl get pods -o wide

# note how the service resolves to the 3 IPs of the StatefulSet pods

kubectl exec nginx -it -- nslookup mssql-service

# note how each pod in the StatefulSet have its own DNS name

kubectl exec nginx -it -- nslookup db-statefulset-0.mssql-service

kubectl exec nginx -it -- nslookup db-statefulset-1.mssql-service

kubectl exec nginx -it -- nslookup db-statefulset-2.mssql-service