# AKS Egress Traffic

## 1. AKS cluster with outbound type load balancer

```shell
az group create -n rg-aks-lb -l westeurope

az aks create -g rg-aks-lb -n aks-lb `
              --outbound-type loadBalancer # default

az aks get-credentials -g rg-aks-lb -n aks-lb --overwrite-existing
```

Check outbound egress traffic uses Load Balancer public IP

```shell
kubectl run nginx --image=nginx
kubectl exec nginx -it -- curl http://ifconfig.me
# 20.101.4.180
```

Note that is the public IP of the Load Balancer. This is the default behavior of AKS clusters.

## 2. AKS cluster with outbound type managed NAT Gateway

```shell
az group create -n rg-aks-natgateway -l westeurope

az aks create -g rg-aks-natgateway -n aks-natgateway `
    --outbound-type managedNATGateway `
    --nat-gateway-managed-outbound-ip-count 2 `
    --nat-gateway-idle-timeout 4

az aks get-credentials -g rg-aks-natgateway -n aks-natgateway --overwrite-existing
```

Note the egress traffic uses 2 public IPs of the NAT Gateway.

```shell
kubectl run nginx --image=nginx
kubectl exec nginx -it -- curl http://ifconfig.me
# 20.101.4.185
kubectl exec nginx -it -- curl http://ifconfig.me
# 20.102.5.80
```

## 3. AKS cluster with outbound type user assigned NAT Gateway

```shell
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
```

Note the egress traffic uses public IPs of the NAT Gateway.

```shell
kubectl run nginx --image=nginx
kubectl exec nginx -it -- curl http://ifconfig.me
# 20.16.100.134
```

## 4. AKS cluster with outbound type user defined route

```shell
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
# {
#   "newVNet": {
#     "addressSpace": {
#       "addressPrefixes": [
#         "10.42.0.0/16"
#       ]
#     },
#     "enableDdosProtection": false,
#     "etag": "W/\"d5266e0b-4251-49d2-bc0f-e501473eb886\"",
#     "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-cluster-egress/providers/Microsoft.Network/virtualNetworks/aks-vnet",
#     "location": "westeurope",
#     "name": "aks-vnet",
#     "provisioningState": "Succeeded",
#     "resourceGroup": "rg-aks-cluster-egress",
#     "resourceGuid": "60613112-7755-4af6-8d42-1056c34f5c30",
#     "subnets": [
#       {
#         "addressPrefix": "10.42.1.0/24",
#         "delegations": [],
#         "etag": "W/\"d5266e0b-4251-49d2-bc0f-e501473eb886\"",
#         "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-cluster-egress/providers/Microsoft.Network/virtualNetworks/aks-vnet/subnets/aks-subnet",
#         "name": "aks-subnet",
#         "privateEndpointNetworkPolicies": "Disabled",
#         "privateLinkServiceNetworkPolicies": "Enabled",
#         "provisioningState": "Succeeded",
#         "resourceGroup": "rg-aks-cluster-egress",
#         "type": "Microsoft.Network/virtualNetworks/subnets"
#       }
#     ],
#     "type": "Microsoft.Network/virtualNetworks",
#     "virtualNetworkPeerings": []
#   }
# }

# Dedicated subnet for Azure Firewall (Firewall name cannot be changed)

az network vnet subnet create `
    --resource-group $RG `
    --vnet-name $VNET_NAME `
    --name $FWSUBNET_NAME `
    --address-prefix 10.42.2.0/24
# {
#   "addressPrefix": "10.42.2.0/24",
#   "delegations": [],
#   "etag": "W/\"2fb83303-5359-4609-8cd6-daba462136ca\"",
#   "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-cluster-egress/providers/Microsoft.Network/virtualNetworks/aks-vnet/subnets/AzureFirewallSubnet",
#   "name": "AzureFirewallSubnet",
#   "privateEndpointNetworkPolicies": "Disabled",
#   "privateLinkServiceNetworkPolicies": "Enabled",
#   "provisioningState": "Succeeded",
#   "resourceGroup": "rg-aks-cluster-egress",
#   "type": "Microsoft.Network/virtualNetworks/subnets"
# }

# 3. Create and set up an Azure Firewall with a UDR

# Azure Firewall inbound and outbound rules must be configured. The main purpose of the firewall is to enable organizations to configure granular ingress and egress traffic rules into and out of the AKS Cluster.

az network public-ip create -g $RG -n $FWPUBLICIP_NAME -l $LOC --sku "Standard"
# {
#   "publicIp": {
#     "ddosSettings": {
#       "protectionMode": "VirtualNetworkInherited"
#     },
#     "etag": "W/\"689dbc85-3bdd-4bcc-bc4a-3beb2ea9c1b9\"",
#     "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-cluster-egress/providers/Microsoft.Network/publicIPAddresses/firewall-publicip",
#     "idleTimeoutInMinutes": 4,
#     "ipAddress": "20.229.246.163",
#     "ipTags": [],
#     "location": "westeurope",
#     "name": "firewall-publicip",
#     "provisioningState": "Succeeded",
#     "publicIPAddressVersion": "IPv4",
#     "publicIPAllocationMethod": "Static",
#     "resourceGroup": "rg-aks-cluster-egress",
#     "resourceGuid": "172c3fde-50a4-4059-a84c-4280446b19b5",
#     "sku": {
#       "name": "Standard",
#       "tier": "Regional"
#     },
#     "type": "Microsoft.Network/publicIPAddresses"
#   }
# }

# Install Azure Firewall preview CLI extension

az extension add --name azure-firewall --upgrade
# Extension 'azure-firewall' 0.14.5 is already installed.
# Latest version of 'azure-firewall' is already installed.

# Deploy Azure Firewall

az network firewall create -g $RG -n $FWNAME -l $LOC --enable-dns-proxy true
# {
#   "Network.DNS.EnableProxy": "true",
#   "applicationRuleCollections": [],
#   "etag": "W/\"e82bc7c8-8144-45c9-8b8b-c3a21ecee7c0\"",
#   "firewallPolicy": null,
#   "hubIpAddresses": null,
#   "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-cluster-egress/providers/Microsoft.Network/azureFirewalls/hub-firewall",
#   "ipConfigurations": [],
#   "ipGroups": null,
#   "location": "westeurope",
#   "managementIpConfiguration": null,
#   "name": "hub-firewall",
#   "natRuleCollections": [],
#   "networkRuleCollections": [],
#   "provisioningState": "Succeeded",
#   "resourceGroup": "rg-aks-cluster-egress",
#   "sku": {
#     "name": "AZFW_VNet",
#     "tier": "Standard"
#   },
#   "tags": null,
#   "threatIntelMode": "Alert",
#   "type": "Microsoft.Network/azureFirewalls",
#   "virtualHub": null,
#   "zones": null
# }

# Configure Firewall IP Config

az network firewall ip-config create -g $RG -f $FWNAME -n $FWIPCONFIG_NAME --public-ip-address $FWPUBLICIP_NAME --vnet-name $VNET_NAME
# {
#   "etag": "W/\"98218133-d92b-4a8b-a9f2-66bc8821dab0\"",
#   "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-cluster-egress/providers/Microsoft.Network/azureFirewalls/hub-firewall/azureFirewallIpConfigurations/firewall-config",
#   "name": "firewall-config",
#   "privateIpAddress": "10.42.2.4",
#   "provisioningState": "Succeeded",
#   "publicIpAddress": {
#     "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-cluster-egress/providers/Microsoft.Network/publicIPAddresses/firewall-publicip",
#     "resourceGroup": "rg-aks-cluster-egress"
#   },
#   "resourceGroup": "rg-aks-cluster-egress",
#   "subnet": {
#     "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-cluster-egress/providers/Microsoft.Network/virtualNetworks/aks-vnet/subnets/AzureFirewallSubnet",
#     "resourceGroup": "rg-aks-cluster-egress"
#   },
#   "type": "Microsoft.Network/azureFirewalls/azureFirewallIpConfigurations"
# }

# Capture Firewall IP Address for Later Use

$FWPUBLIC_IP=$(az network public-ip show -g $RG -n $FWPUBLICIP_NAME --query "ipAddress" -o tsv)
$FWPRIVATE_IP=$(az network firewall show -g $RG -n $FWNAME --query "ipConfigurations[0].privateIpAddress" -o tsv)
echo $FWPRIVATE_IP
# 10.42.2.4

# Create UDR and add a route for Azure Firewall

az network route-table create -g $RG -l $LOC --name $FWROUTE_TABLE_NAME
# {
#   "disableBgpRoutePropagation": false,
#   "etag": "W/\"d5766c17-ef48-4f5d-b153-765118656819\"",
#   "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-cluster-egress/providers/Microsoft.Network/routeTables/firewall-routetable",
#   "location": "westeurope",
#   "name": "firewall-routetable",
#   "provisioningState": "Succeeded",
#   "resourceGroup": "rg-aks-cluster-egress",
#   "resourceGuid": "947c193e-ed88-40f8-9b9b-0f34a151e7a5",
#   "routes": [],
#   "type": "Microsoft.Network/routeTables"
# }

az network route-table route create -g $RG --name $FWROUTE_NAME --route-table-name $FWROUTE_TABLE_NAME --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address $FWPRIVATE_IP
# {
#   "addressPrefix": "0.0.0.0/0",
#   "etag": "W/\"a575328c-b28b-4f05-9b9e-a58e9ee68d31\"",
#   "hasBgpOverride": false,
#   "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-cluster-egress/providers/Microsoft.Network/routeTables/firewall-routetable/routes/firewall-route",
#   "name": "firewall-route",
#   "nextHopIpAddress": "10.42.2.4",
#   "nextHopType": "VirtualAppliance",
#   "provisioningState": "Succeeded",
#   "resourceGroup": "rg-aks-cluster-egress",
#   "type": "Microsoft.Network/routeTables/routes"
# }

az network route-table route create -g $RG --name $FWROUTE_NAME_INTERNET --route-table-name $FWROUTE_TABLE_NAME --address-prefix $FWPUBLIC_IP/32 --next-hop-type Internet
# {
#   "addressPrefix": "20.229.246.163/32",
#   "etag": "W/\"ade51b62-5fc1-458a-b989-2f8e754f0b5f\"",
#   "hasBgpOverride": false,
#   "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-cluster-egress/providers/Microsoft.Network/routeTables/firewall-routetable/routes/firewall-route-internet",
#   "name": "firewall-route-internet",
#   "nextHopType": "Internet",
#   "provisioningState": "Succeeded",
#   "resourceGroup": "rg-aks-cluster-egress",
#   "type": "Microsoft.Network/routeTables/routes"
# }

# 4. Adding firewall rules

# Add FW Network Rules

az network firewall network-rule create -g $RG -f $FWNAME --collection-name 'aksfwnr' -n 'apiudp' --protocols 'UDP' --source-addresses '*' --destination-addresses "AzureCloud.$LOC" --destination-ports 1194 --action allow --priority 100
# Creating rule collection 'aksfwnr'.
# {
#   "description": null,
#   "destinationAddresses": [
#     "AzureCloud.westeurope"
#   ],
#   "destinationFqdns": [],
#   "destinationIpGroups": [],
#   "destinationPorts": [
#     "1194"
#   ],
#   "name": "apiudp",
#   "protocols": [
#     "UDP"
#   ],
#   "sourceAddresses": [
#     "*"
#   ],
#   "sourceIpGroups": []
# }

az network firewall network-rule create -g $RG -f $FWNAME --collection-name 'aksfwnr' -n 'apitcp' --protocols 'TCP' --source-addresses '*' --destination-addresses "AzureCloud.$LOC" --destination-ports 9000
# {
#   "description": null,
#   "destinationAddresses": [
#     "AzureCloud.westeurope"
#   ],
#   "destinationFqdns": [],
#   "destinationIpGroups": [],
#   "destinationPorts": [
#     "9000"
#   ],
#   "name": "apitcp",
#   "protocols": [
#     "TCP"
#   ],
#   "sourceAddresses": [
#     "*"
#   ],
#   "sourceIpGroups": []
# }

az network firewall network-rule create -g $RG -f $FWNAME --collection-name 'aksfwnr' -n 'time' --protocols 'UDP' --source-addresses '*' --destination-fqdns 'ntp.ubuntu.com' --destination-ports 123
# {
#   "description": null,
#   "destinationAddresses": [],
#   "destinationFqdns": [
#     "ntp.ubuntu.com"
#   ],
#   "destinationIpGroups": [],
#   "destinationPorts": [
#     "123"
#   ],
#   "name": "time",
#   "protocols": [
#     "UDP"
#   ],
#   "sourceAddresses": [
#     "*"
#   ],
#   "sourceIpGroups": []
# }

# Add FW Application Rules

az network firewall application-rule create -g $RG -f $FWNAME --collection-name 'aksfwar' -n 'fqdn' --source-addresses '*' --protocols 'http=80' 'https=443' --fqdn-tags "AzureKubernetesService" --action allow --priority 100
# Creating rule collection 'aksfwar'.
# {
#   "actions": [],
#   "description": null,
#   "direction": "Inbound",
#   "fqdnTags": [
#     "AzureKubernetesService"
#   ],
#   "name": "fqdn",
#   "priority": 0,
#   "protocols": [
#     {
#       "port": 80,
#       "protocolType": "Http"
#     },
#     {
#       "port": 443,
#       "protocolType": "Https"
#     }
#   ],
#   "sourceAddresses": [
#     "*"
#   ],
#   "sourceIpGroups": [],
#   "targetFqdns": []
# }

# 5. Associate the route table to AKS

# Associate route table with next hop to Firewall to the AKS subnet

az network vnet subnet update -g $RG --vnet-name $VNET_NAME --name $AKSSUBNET_NAME --route-table $FWROUTE_TABLE_NAME
# {
#   "addressPrefix": "10.42.1.0/24",
#   "delegations": [],
#   "etag": "W/\"797dbbf7-1479-467a-852e-cb855a452070\"",
#   "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-cluster-egress/providers/Microsoft.Network/virtualNetworks/aks-vnet/subnets/aks-subnet",
#   "name": "aks-subnet",
#   "privateEndpointNetworkPolicies": "Disabled",
#   "privateLinkServiceNetworkPolicies": "Enabled",
#   "provisioningState": "Succeeded",
#   "resourceGroup": "rg-aks-cluster-egress",
#   "routeTable": {
#     "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-cluster-egress/providers/Microsoft.Network/routeTables/firewall-routetable",
#     "resourceGroup": "rg-aks-cluster-egress"
#   },
#   "type": "Microsoft.Network/virtualNetworks/subnets"
# }

# 6. Deploy AKS with outbound type of UDR to the existing network

$SUBNETID=$(az network vnet subnet show -g $RG --vnet-name $VNET_NAME --name $AKSSUBNET_NAME --query id -o tsv)
echo $SUBNETID
# /subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-cluster-egress/providers/Microsoft.Network/virtualNetworks/aks-vnet/subnets/aks-subnet

az aks create -g $RG -n $AKSNAME -l $LOC `
  --node-count 3 `
  --network-plugin azure `
  --outbound-type userDefinedRouting `
  --vnet-subnet-id $SUBNETID `
  --api-server-authorized-ip-ranges $FWPUBLIC_IP
```

## 4.7. Test the egress traffic is using the Firewall public IP

```shell
kubectl run nginx --image=nginx
# pod/nginx created

kubectl exec nginx -it -- /bin/bash
# error: unable to upgrade connection: container not found ("nginx")

kubectl get pods
# NAME    READY   STATUS         RESTARTS   AGE
# nginx   0/1     ErrImagePull   0          32s
```

The above error is because Azure Firewall blocks access to non allowed endpoints.
Create an application rule to allow access to Docker Hub.

```shell
az network firewall application-rule create -g $RG -f $FWNAME --collection-name 'dockerhub-registry' -n 'dockerhub-registry' --action allow --priority 200 --source-addresses '*' --protocols 'https=443' --target-fqdns hub.docker.com registry-1.docker.io production.cloudflare.docker.com auth.docker.io cdn.auth0.com login.docker.com
# Creating rule collection 'dockerhub-registry'.
# {
#   "actions": [],
#   "description": null,
#   "direction": "Inbound",
#   "fqdnTags": [],
#   "name": "dockerhub-registry",
#   "priority": 0,
#   "protocols": [
#     {
#       "port": 443,
#       "protocolType": "Https"
#     }
#   ],
#   "sourceAddresses": [
#     "*"
#   ],
#   "sourceIpGroups": [],
#   "targetFqdns": [
#     "hub.docker.com",
#     "registry-1.docker.io",
#     "production.cloudflare.docker.com",
#     "auth.docker.io",
#     "cdn.auth0.com",
#     "login.docker.com"
#   ]
# }
```

Let's retry now. The image is pulled and pod works.

```shell
kubectl get pods
# NAME    READY   STATUS    RESTARTS   AGE
# nginx   1/1     Running   0          21m
```

Let's see what IP address is used by the pod to access external services. We use ifconfig.me to view the IP address on the remote server.

```shell
kubectl exec nginx -it -- curl http://ifconfig.me
# Action: Deny. Reason: No rule matched. Proceeding with default action.
```

Again, access is blocked by the Firewall.
Create an application rule to allow access to ifconfig.me

```shell
az network firewall application-rule create -g $RG -f $FWNAME --collection-name 'ifconfig' -n 'ifconfig' --action allow --priority 300 --source-addresses '*' --protocols 'http=80' --target-fqdns ifconfig.me
# Creating rule collection 'ifconfig'.
# {
#   "actions": [],
#   "description": null,
#   "direction": "Inbound",
#   "fqdnTags": [],
#   "name": "ifconfig",
#   "priority": 0,
#   "protocols": [
#     {
#       "port": 80,
#       "protocolType": "Http"
#     }
#   ],
#   "sourceAddresses": [
#     "*"
#   ],
#   "sourceIpGroups": [],
#   "targetFqdns": [
#     "ifconfig.me"
#   ]
# }
```

Let's retry again now. We should see the Pod outbound traffic uses the Firewall public IP address.

```shell
kubectl exec nginx -it -- curl http://ifconfig.me
# 20.229.246.163
```

### 4.8. [Optional] Deploy the Azure Application Gateway Ingress Controller

```shell
az aks enable-addons -n $AKSNAME -g $RG -a ingress-appgw --appgw-name azure-appgateway --appgw-subnet-cidr '10.42.3.0/24'
#  \ Running ..
```

### 4.8.1. Deploy an application

```shell
kubectl apply -f pod-svc-ingress.yaml
# pod/aspnetapp created
# service/aspnetapp created
# ingress.networking.k8s.io/aspnetapp created
```

### 4.8.2. Test the application

```shell
kubectl get pod,svc,ingress
# NAME            READY   STATUS    RESTARTS   AGE
# pod/aspnetapp   1/1     Running   0          21s
# pod/nginx       1/1     Running   0          98m

# NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
# service/aspnetapp    ClusterIP   10.0.8.241   <none>        80/TCP    21s
# service/kubernetes   ClusterIP   10.0.0.1     <none>        443/TCP   6h9m

# NAME                                  CLASS    HOSTS   ADDRESS        PORTS   AGE
# ingress.networking.k8s.io/aspnetapp   <none>   *       20.13.91.180   80      21s
```

View the application in the browser: http://20.13.91.180. It should be working. The ingress traffic go through and returns through the App Gateway. It is not routed to the Firewall. That is because the App Gateway is inside the cluster VNET. Traffic from App Gateway is considered "internal" traffic.

## More resources
https://learn.microsoft.com/en-us/azure/aks/limit-egress-traffic#restrict-egress-traffic-using-azure-firewall