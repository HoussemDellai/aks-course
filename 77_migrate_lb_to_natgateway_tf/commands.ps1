# prerequisites

az feature register --namespace "Microsoft.ContainerService" --name "AKS-OutBoundTypeMigrationPreview"
az feature show --namespace "Microsoft.ContainerService" --name "AKS-OutBoundTypeMigrationPreview"
az provider register --namespace Microsoft.ContainerService

# 1. Deploying AKS and VM

# Use terraform to deploy :
# 1. AKS cluster with outbound type load balancer 
# 2. Azure Linux VM and Bastion
# 3. Nat Gateway
# 4. Two separate peered VNETs

terraform init

terraform apply -auto-approve

$RG = "rg-aks-cluster"

az aks get-credentials -g $RG -n aks-cluster --overwrite-existing

# check outbound egress traffic uses Load Balancer public IP

kubectl run nginx --image=nginx
sleep 10
kubectl exec nginx -it -- curl http://ifconf.me
# 20.160.240.183

# Update AKS subnet to use Nat Gateway

az network vnet subnet update -g $RG --vnet-name vnet-aks --name subnet-aks --nat-gateway nat-gateway

# Update cluster from loadbalancer to userAssignedNATGateway in BYO vnet scenario

az aks update -g $RG -n aks-cluster --outbound-type userAssignedNATGateway

# check outbound egress traffic uses Nat Gateway public IP

kubectl exec nginx -it -- curl http://ifconf.me
# 172.201.129.36

# test connection to web app hosted on the Azure VM within a peered VNET

kubectl exec nginx -it -- curl 10.0.1.4
# Hello from virtual machine: vm-linux, with IP address: 10.0.1.4

# cleanup resources
az group delete -n $RG --yes --no-wait