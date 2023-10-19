# Migrating OutboundType from Load Balancer to user NAT Gateway

## Introduction

You will learn in this lab how to migrate `outboundType` of an AKS cluster from `LoadBalancer` to `user NAT Gateway`.

Why you might do that ?

Mainly in case your apps are consuming multiple SNAT ports.
The NAT Gateway manages more efficiently SNAT ports than Load Balancer.
More details on the lab `65_aks_egress_lb_natgw_udr`.

There are four options for configuring outbound type in AKS:
1. Load Balancer (default mode)
2. Managed NAT Gateway
3. User NAT Gateway
4. UserDefinedRouting (UDR)

AKS supports migrating from one mode to another.

| BYO VNet     | loadBalancer | managedNATGateway | userAssignedNATGateway | userDefinedRouting |
| ------------ | ------------ | ----------------- | ---------------------- | ------------------ |
| loadBalancer | N/A          | Not Supported     | Supported              | Supported          | 
| managedNATGateway | Not Supported | N/A | Not Supported | Not Supported | 
| userAssignedNATGateway | Supported | Not Supported | N/A | Supported | 
| userDefinedRouting | Supported | Not Supported | Supported | N/A | 

Check the following link for an updated information: https://learn.microsoft.com/en-us/azure/aks/egress-outboundtype#update-cluster-from-managednatgateway-to-userdefinedrouting

## Prerequisites

You need first to enable the migration feature.

```bash
az feature register --namespace "Microsoft.ContainerService" --name "AKS-OutBoundTypeMigrationPreview"
az feature show --namespace "Microsoft.ContainerService" --name "AKS-OutBoundTypeMigrationPreview"
az provider register --namespace Microsoft.ContainerService
```

## 1. Creating an AKS cluster with outbound type load balancer

```bash
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
```

Check outbound egress traffic uses Load Balancer public IP

```bash
kubectl run nginx --image=nginx
sleep 10
kubectl exec nginx -it -- curl http://ifconfig.me
```

Note that is the public IP of the Load Balancer. This is the default behavior of AKS clusters.

## 2. Migrate outbound type from load balancer to user NAT Gateway

### 2.1. Create the user NAT GAteway with its IP address

```bash
az network public-ip create -g $RG -n pip-natgateway --sku standard

az network nat gateway create -g $RG -n nat-gateway --public-ip-addresses pip-natgateway
```

### 2.2. Associate nat gateway with subnet where the workload is associated with.

```bash
az network vnet subnet update -g $RG --vnet-name vnet-aks --name subnet-aks --nat-gateway nat-gateway
```

### 2.3. Update cluster from loadBalancer to userAssignedNATGateway in BYO vnet scenario

```bash
az aks update -g $RG -n aks-cluster --outbound-type userAssignedNATGateway
```

Now the NAT Gateway is configured for your AKS cluster.

![](images/resources.png)

Run this command in new powershell session for watch for the downtime of egress traffic.

```bash
for ($i = 0; $i -lt 30; $i++) {
    date
    kubectl exec nginx -it -- curl http://ifconfig.me
    sleep 10 # 10 seconds
}
# Wednesday, October 18, 2023 6:07:33 PM
# 20.31.59.30
# Wednesday, October 18, 2023 6:07:34 PM
# error: Timeout occurred
# Wednesday, October 18, 2023 6:08:06 PM
# Error from server: error dialing backend: EOF
# Wednesday, October 18, 2023 6:13:09 PM
# 13.93.68.197
```

It takes about 6 minutes to update the outboundType from LB to user NAT Gateway.

Note the new IP address of the NAT Gateway used for egress/outbound traffic.

Note that the Load Balancer and its public IP was deleted.

![](images/deleted-lb.png)

## Cleanup resources

```bash
az group delete -n $RG --yes --no-wait 
```