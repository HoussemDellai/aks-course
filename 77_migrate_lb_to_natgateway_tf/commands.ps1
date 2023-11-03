# prerequisites

az feature register --namespace "Microsoft.ContainerService" --name "AKS-OutBoundTypeMigrationPreview"
az feature show --namespace "Microsoft.ContainerService" --name "AKS-OutBoundTypeMigrationPreview"
az provider register --namespace Microsoft.ContainerService

# 1. AKS cluster with outbound type load balancer

terraform init

terraform apply -auto-approve

$RG = "rg-aks-cluster-dev"

az aks get-credentials -g $RG -n aks-cluster --overwrite-existing

# check outbound egress traffic uses Load Balancer public IP

kubectl run nginx --image=nginx
sleep 10
kubectl exec nginx -it -- curl http://ifconf.me

# Note that is the public IP of the Load Balancer. This is the default behavior of AKS clusters.

# Associate nat gateway with subnet where the workload is associated with.

az network vnet subnet update -g $RG --vnet-name vnet-aks --name subnet-aks --nat-gateway nat-gateway

# Update cluster from loadbalancer to userAssignedNATGateway in BYO vnet scenario
az aks update -g $RG -n aks-cluster --outbound-type userAssignedNATGateway

kubectl exec nginx -it -- curl 10.0.1.4
# Hello from virtual machine: vm-linux, with IP address: 10.0.1.4

# cleanup resources
az group delete -n $RG --yes --no-wait