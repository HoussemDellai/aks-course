## Introduction
For security reasons, the Control PLane in AKS cluster could be either public or private.
## 1. Public cluster
```bash
# create public cluster
az group create  -n rg-aks-public -l westeurope
az aks create -n aks-cluster -g rg-aks-public
```
```bash
# get the public FQDN
az aks show -n aks-cluster -g rg-aks-public --query fqdn
# output: "aks-cluste-rg-aks-private-17b128-93acc102.hcp.westeurope.azmk8s.io"
# resolve the public FQDN
nslookup aks-cluste-rg-aks-public-17b128-93acc102.hcp.westeurope.azmk8s.io
# output:
# Address:  10.224.0.4
```
# print screen for created resources

## 2. Private cluster using Private Endpoint
```bash
# create private cluster
az group create -n rg-aks-private -l westeurope
az aks create -n aks-cluster -g rg-aks-private --enable-private-cluster
```
# print screen for created resources

```bash
# get the public FQDN
az aks show -n aks-cluster -g rg-aks-private --query fqdn
# output: "aks-cluste-rg-aks-private-17b128-93acc102.hcp.westeurope.azmk8s.io"
# resolve the public FQDN
nslookup aks-cluste-rg-aks-private-17b128-93acc102.hcp.westeurope.azmk8s.io
# output:
# Address:  10.224.0.4
```

```bash
# get the private FQDN
az aks show -n aks-cluster -g rg-aks-private --query privateFqdn
# output: "aks-cluste-rg-aks-private-17b128-77ac7912.2fce4e7c-d421-4bec-a1ed-936a275d8f96.privatelink.westeurope.azmk8s.io"
# resolve the private FQDN
nslookup aks-cluste-rg-aks-private-17b128-77ac7912.2fce4e7c-d421-4bec-a1ed-936a275d8f96.privatelink.westeurope.azmk8s.io
# output:
# Address:  10.224.0.4
```

```bash
# disable public FQDN
az aks update -n aks-cluster -g rg-aks-private --disable-public-fqdn
# resolve the public (disabled) FQDN
nslookup aks-cluste-rg-aks-private-17b128-93acc102.hcp.westeurope.azmk8s.io
# output:
# Address:  <not exist>
```

## 3. Public cluster using API Integration
```bash
# create public cluster with VNET Integration
az group create -n rg-aks-public-vnet-integration -l eastus2
az aks create -n aks-cluster -g rg-aks-public-vnet-integration --enable-apiserver-vnet-integration
```
# print screen for created resources

```bash
# get the public FQDN
az aks show -n aks-cluster -g rg-aks-public-vnet-integration --query fqdn
# output: "aks-cluste-rg-aks-public-vn-17b128-e971c74b.hcp.eastus2.azmk8s.io"
# resolve the public FQDN
nslookup aks-cluste-rg-aks-public-vn-17b128-e971c74b.hcp.eastus2.azmk8s.io
# output:
# Address:  
```

```bash
# get the private FQDN
az aks show -n aks-cluster -g rg-aks-public-vnet-integration --query privateFqdn
# output: null
```

## 4. Private cluster using API Integration
```bash
# create private cluster with VNET Integration
az group create -n rg-aks-private-vnet-integration -l eastus2
az aks create -n aks-cluster -g rg-aks-private-vnet-integration --enable-apiserver-vnet-integration --enable-private-cluster
```
# print screen for created resources

```bash
# get the public FQDN
az aks show -n aks-cluster -g rg-aks-private-vnet-integration --query fqdn
# output: "aks-cluste-rg-aks-public-vn-17b128-e971c74b.hcp.eastus2.azmk8s.io"
# resolve the public FQDN
nslookup aks-cluste-rg-aks-private-v-17b128-6437ad52.hcp.eastus2.azmk8s.io
# output:
# Address:  
```

```bash
# get the private FQDN
az aks show -n aks-cluster -g rg-aks-private-vnet-integration --query privateFqdn
# output: "aks-cluste-rg-aks-private-v-17b128-a421b4e5.adfb044f-ce19-4cd6-8f9e-4ad9b2ce23bf.private.eastus2.azmk8s.io"
# resolve private FQDN
nslookup aks-cluste-rg-aks-private-v-17b128-a421b4e5.adfb044f-ce19-4cd6-8f9e-4ad9b2ce23bf.private.eastus2.azmk8s.io
# output:
# Address:  
```
