# prerequisites

az feature register --namespace "Microsoft.ContainerService" --name "AKS-OutBoundTypeMigrationPreview"
az feature show --namespace "Microsoft.ContainerService" --name "AKS-OutBoundTypeMigrationPreview"
az provider register --namespace Microsoft.ContainerService

# 1. AKS cluster with outbound type load balancer

$RG = "rg-aks-cluster-dev"

az group create -n $RG -l westeurope

az network vnet create -g $RG -n vnet-aks --address-prefixes 172.16.0.0/20 

$SUBNET_ID = $(az network vnet subnet create -g $RG --vnet-name vnet-aks -n subnet-aks `
        --address-prefixes 172.16.0.0/22 `
        --query id --output tsv)

$IDENTITY_ID = $(az identity create -g $RG -n identity-aks --query id --output tsv)

az aks create -g $RG -n aks-cluster `
    --network-plugin azure `
    --vnet-subnet-id $SUBNET_ID `
    --outbound-type loadBalancer `
    --enable-managed-identity `
    --assign-identity $IDENTITY_ID

az aks get-credentials -g $RG -n aks-cluster --overwrite-existing

# check outbound egress traffic uses Load Balancer public IP

kubectl run nginx --image=nginx
sleep 10
kubectl exec nginx -it -- curl http://ifconfig.me

# Note that is the public IP of the Load Balancer. This is the default behavior of AKS clusters.

# Associate nat gateway with subnet where the workload is associated with.

az network public-ip create -g $RG -n pip-natgateway --sku standard

az network nat gateway create -g $RG -n nat-gateway --public-ip-addresses pip-natgateway

az network vnet subnet update -g $RG --vnet-name vnet-aks --name subnet-aks --nat-gateway nat-gateway

kubectl exec nginx -it -- curl http://ifconfig.me
# timeout

# Update cluster from loadbalancer to userAssignedNATGateway in BYO vnet scenario
az aks update -g $RG -n aks-cluster --outbound-type userAssignedNATGateway

# run this in new powershell session

for ($i = 0; $i -lt 30; $i++) {
    date
    kubectl exec nginx -it -- curl http://ifconfig.me
    sleep 10
}

# Wednesday, October 18, 2023 6:07:33 PM
# 20.31.59.30
# Wednesday, October 18, 2023 6:07:34 PM
# error: Timeout occurred
# Wednesday, October 18, 2023 6:08:06 PM
# Error from server: error dialing backend: EOF
# Wednesday, October 18, 2023 6:13:09 PM
# 13.93.68.197

# it takes about 6 minutes to update the outboundType from LB to managed NAT Gateway

# note the new IP address of the NAT Gateway used for egress/outbound traffic

# note that the Load Balancer and its public IP was deleted

# cleanup resources
az group delete -n $RG --yes --no-wait 

# resources
https://learn.microsoft.com/en-us/azure/aks/egress-outboundtype#update-cluster-from-managednatgateway-to-userdefinedrouting