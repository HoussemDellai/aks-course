## AKS Egress Traffic with Load Balancer, NAT Gateway, and User Defined Route

# 1. AKS cluster with outbound type load balancer

az group create -n rg-aks-lb -l westeurope

az aks create -g rg-aks-lb -n aks-lb `
              --outbound-type loadBalancer # default

az aks get-credentials -g rg-aks-lb -n aks-lb --overwrite-existing

# check outbound egress traffic uses Load Balancer public IP

kubectl run nginx --image=nginx
kubectl exec nginx -it -- curl http://ifconfig.me

# Note that is the public IP of the Load Balancer. This is the default behavior of AKS clusters.

# 2. AKS cluster with outbound type managed NAT Gateway

az group create -n rg-aks-natgateway -l westeurope

az aks create -g rg-aks-natgateway -n aks-natgateway `
    --outbound-type managedNATGateway `
    --nat-gateway-managed-outbound-ip-count 2 `
    --nat-gateway-idle-timeout 4

az aks get-credentials -g rg-aks-natgateway -n aks-natgateway --overwrite-existing

kubectl run nginx --image=nginx
kubectl exec nginx -it -- curl http://ifconfig.me

kubectl exec nginx -it -- curl http://ifconfig.me

# Note the egress traffic uses 2 public IPs of the NAT Gateway.

# 3. AKS cluster with outbound type user assigned NAT Gateway

az group create -n rg-aks-usernatgateway -l westeurope

# Create a managed identity for network permissions and store the ID to $IDENTITY_ID for later use.

$IDENTITY_ID=$(az identity create `
--resource-group rg-aks-usernatgateway `
--name natClusterId `
--location westeurope `
--query id `
--output tsv)

# Create a public IP for the NAT gateway.
az network public-ip create `
    --resource-group rg-aks-usernatgateway `
    --name myNatGatewayPip `
    --location westeurope `
    --sku standard

# Create the NAT gateway.

az network nat gateway create `
    --resource-group rg-aks-usernatgateway `
    --name myNatGateway `
    --location westeurope `
    --public-ip-addresses myNatGatewayPip

# Create a virtual network.

az network vnet create `
    --resource-group rg-aks-usernatgateway `
    --name myVnet `
    --location westeurope `
    --address-prefixes 172.16.0.0/20 

# Create a subnet in the virtual network using the NAT gateway and store the ID to $SUBNET_ID for later use.

$SUBNET_ID=$(az network vnet subnet create `
    --resource-group rg-aks-usernatgateway `
    --vnet-name myVnet `
    --name natCluster `
    --address-prefixes 172.16.0.0/22 `
    --nat-gateway myNatGateway `
    --query id `
    --output tsv)

# Create an AKS cluster using the subnet with the NAT gateway and the managed identity.

az aks create `
    --resource-group rg-aks-usernatgateway `
    --name natCluster `
    --location westeurope `
    --network-plugin azure `
    --vnet-subnet-id $SUBNET_ID `
    --outbound-type userAssignedNATGateway `
    --enable-managed-identity `
    --assign-identity $IDENTITY_ID

az aks get-credentials -g rg-aks-usernatgateway -n natCluster --overwrite-existing

kubectl run nginx --image=nginx

kubectl exec nginx -it -- curl http://ifconfig.me

# Note the egress traffic uses public IPs of the NAT Gateway.

# 4. AKS cluster with outbound type user defined route

# 4.1. Set configuration via environment variables

$RG="rg-aks-udr"
$LOC="westeurope"
$AKSNAME="aks-udr"
$VNET_NAME="aks-vnet"
$AKSSUBNET_NAME="aks-subnet"
# DO NOT CHANGE FWSUBNET_NAME - This is currently a requirement for Azure Firewall.
$FWSUBNET_NAME="AzureFirewallSubnet"
$FWNAME="hub-firewall"
$FWPUBLICIP_NAME="firewall-publicip"
$FWIPCONFIG_NAME="firewall-config"
$FWROUTE_TABLE_NAME="firewall-routetable"
$FWROUTE_NAME="firewall-route"
$FWROUTE_NAME_INTERNET="firewall-route-internet"

# 4.2. Create a virtual network with multiple subnets

# Create Resource Group

az group create --name $RG --location $LOC

# Create a virtual network with two subnets to host the AKS cluster and the Azure Firewall. Each will have their own subnet. Let's start with the AKS network.

# Dedicated virtual network with AKS subnet

az network vnet create `
    --resource-group $RG `
    --name $VNET_NAME `
    --location $LOC `
    --address-prefixes 10.42.0.0/16 `
    --subnet-name $AKSSUBNET_NAME `
    --subnet-prefix 10.42.1.0/24

# Dedicated subnet for Azure Firewall (Firewall name cannot be changed)

az network vnet subnet create `
    --resource-group $RG `
    --vnet-name $VNET_NAME `
    --name $FWSUBNET_NAME `
    --address-prefix 10.42.2.0/24

# 4.3. Create and set up an Azure Firewall with a UDR

# Azure Firewall inbound and outbound rules must be configured. The main purpose of the firewall is to enable organizations to configure granular ingress and egress traffic rules into and out of the AKS Cluster.

az network public-ip create -g $RG -n $FWPUBLICIP_NAME -l $LOC --sku "Standard"

# Install Azure Firewall preview CLI extension

az extension add --name azure-firewall --upgrade

# Deploy Azure Firewall

az network firewall create -g $RG -n $FWNAME -l $LOC --enable-dns-proxy true

# Configure Firewall IP Config

az network firewall ip-config create -g $RG -f $FWNAME -n $FWIPCONFIG_NAME --public-ip-address $FWPUBLICIP_NAME --vnet-name $VNET_NAME

# Capture Firewall IP Address for Later Use

$FWPUBLIC_IP=$(az network public-ip show -g $RG -n $FWPUBLICIP_NAME --query "ipAddress" -o tsv)
$FWPRIVATE_IP=$(az network firewall show -g $RG -n $FWNAME --query "ipConfigurations[0].privateIPAddress" -o tsv)
echo $FWPRIVATE_IP

# Create UDR and add a route for Azure Firewall

az network route-table create -g $RG -l $LOC --name $FWROUTE_TABLE_NAME

az network route-table route create -g $RG --name $FWROUTE_NAME --route-table-name $FWROUTE_TABLE_NAME --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address $FWPRIVATE_IP

az network route-table route create -g $RG --name $FWROUTE_NAME_INTERNET --route-table-name $FWROUTE_TABLE_NAME --address-prefix $FWPUBLIC_IP/32 --next-hop-type Internet

# 4.4. Adding firewall rules

# Add FW Network Rules

az network firewall network-rule create -g $RG -f $FWNAME --collection-name 'aksfwnr' -n 'apiudp' --protocols 'UDP' --source-addresses '*' --destination-addresses "AzureCloud.$LOC" --destination-ports 1194 --action allow --priority 100

az network firewall network-rule create -g $RG -f $FWNAME --collection-name 'aksfwnr' -n 'apitcp' --protocols 'TCP' --source-addresses '*' --destination-addresses "AzureCloud.$LOC" --destination-ports 9000

az network firewall network-rule create -g $RG -f $FWNAME --collection-name 'aksfwnr' -n 'time' --protocols 'UDP' --source-addresses '*' --destination-fqdns 'ntp.ubuntu.com' --destination-ports 123

# Add FW Application Rules

az network firewall application-rule create -g $RG -f $FWNAME --collection-name 'aksfwar' -n 'fqdn' --source-addresses '*' --protocols 'http=80' 'https=443' --fqdn-tags "AzureKubernetesService" --action allow --priority 100

# 4.5. Associate the route table to AKS

# Associate route table with next hop to Firewall to the AKS subnet

az network vnet subnet update -g $RG --vnet-name $VNET_NAME --name $AKSSUBNET_NAME --route-table $FWROUTE_TABLE_NAME

# 4.6. Deploy AKS with outbound type of UDR to the existing network

$SUBNETID=$(az network vnet subnet show -g $RG --vnet-name $VNET_NAME --name $AKSSUBNET_NAME --query id -o tsv)
echo $SUBNETID

az aks create -g $RG -n $AKSNAME -l $LOC `
  --node-count 3 `
  --kubernetes-version 1.26.3 `
  --network-plugin azure `
  --outbound-type userDefinedRouting `
  --vnet-subnet-id $SUBNETID

# Connect to the cluster

az aks get-credentials -n $AKSNAME -g $RG --overwrite-existing

# 4.7. Test the egress traffic is using the Firewall public IP

kubectl run nginx --image=nginx

kubectl get pods

# Note the error message in the events section. The image is not available in the cluster. The cluster is trying to pull the image from Docker Hub. The firewall is blocking the traffic.

# Create an application rule to allow access to Docker Hub

az network firewall application-rule create -g $RG -f $FWNAME --collection-name 'dockerhub-registry' -n 'dockerhub-registry' --action allow --priority 200 --source-addresses '*' --protocols 'https=443' --target-fqdns hub.docker.com registry-1.docker.io production.cloudflare.docker.com auth.docker.io cdn.auth0.com login.docker.com

kubectl get pods
# NAME    READY   STATUS    RESTARTS   AGE
# nginx   1/1     Running   0          21m

kubectl exec nginx -it -- curl http://ifconfig.me

# Create an application rule to allow access to ifconfig.me
az network firewall application-rule create -g $RG -f $FWNAME --collection-name 'ifconfig' -n 'ifconfig' --action allow --priority 300 --source-addresses '*' --protocols 'http=80' --target-fqdns ifconfig.me

kubectl exec nginx -it -- curl http://ifconfig.me

# Note the IP address is the public IP address of the firewall.

# 4.8. [Optional] Deploy the Azure Application Gateway Ingress Controller

az aks enable-addons -n $AKSNAME -g $RG -a ingress-appgw --appgw-name azure-appgateway --appgw-subnet-cidr '10.42.3.0/24'

# 4.8.1. Deploy an application

kubectl apply -f pod-svc-ingress.yaml

# 4.8.2. Test the application

kubectl get pod,svc,ingress

# View the application in the browser: http://<REPLACE_INGRESS_IP>