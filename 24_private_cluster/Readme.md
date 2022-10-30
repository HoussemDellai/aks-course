# Public and private AKS clusters demystified

## Introduction
For security reasons, the Control PLane in AKS cluster could be either public or private.

<img src="AKS_access_modes.png">

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
# Address: 20.103.218.175
az aks show -n aks-cluster -g rg-aks-public --query privateFqdn
# output: null
```
How Worker Nodes connects to the Control Plane ?
They use the public IP address.
```bash
az aks get-credentials --resource-group rg-aks-public --name aks-cluster
kubectl get svc
# NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
# kubernetes   ClusterIP   10.0.0.1     <none>        443/TCP   113m
kubectl describe svc kubernetes
# IPs:               10.0.0.1
# Port:              https  443/TCP
# TargetPort:        443/TCP
# Endpoints:         20.103.218.175:443
kubectl get endpoints
# NAME         ENDPOINTS            AGE
# kubernetes   20.103.218.175:443   114m
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
# output: "aks-cluste-rg-aks-private-17b128-32f70f3f.hcp.westeurope.azmk8s.io"
# resolve the public FQDN
nslookup aks-cluste-rg-aks-private-17b128-32f70f3f.hcp.westeurope.azmk8s.io
# output:
# Address:  10.224.0.4
```
The private IP address '10.224.0.4' is the address used by Private Endpoint to access to Control Plane.
```bash
# get the private FQDN
az aks show -n aks-cluster -g rg-aks-private --query privateFqdn
# output: "aks-cluste-rg-aks-private-17b128-6d8d6675.628fd8ef-83fc-49d4-975e-c765c36407d7.privatelink.westeurope.azmk8s.io"
# resolve the private FQDN
nslookup aks-cluste-rg-aks-private-17b128-6d8d6675.628fd8ef-83fc-49d4-975e-c765c36407d7.privatelink.westeurope.azmk8s.io
# output:
# Address:  not found
```
Private FQDN is resolvable only through Private DNS Zone.

```bash
az aks get-credentials --resource-group rg-aks-private --name aks-cluster
az aks command invoke --resource-group rg-aks-private --name aks-cluster --command "kubectl describe svc kubernetes"
# command started at 2022-10-30 21:41:50+00:00, finished at 2022-10-30 21:41:50+00:00 with exitcode=0
# IPs:               10.0.0.1
# Port:              https  443/TCP
# TargetPort:        443/TCP
# Endpoints:         10.224.0.4:443
```

```bash
# disable public FQDN
az aks update -n aks-cluster -g rg-aks-private --disable-public-fqdn
# resolve the public (disabled) FQDN
az aks show -n aks-cluster -g rg-aks-private --query fqdn
# output: null (no public fqdn)
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
# output: "aks-cluste-rg-aks-public-vn-17b128-2ab6e274.hcp.eastus2.azmk8s.io"
# resolve the public FQDN
nslookup aks-cluste-rg-aks-public-vn-17b128-2ab6e274.hcp.eastus2.azmk8s.io
# output:
# Address:  20.94.16.207
```

```bash
# get the private FQDN
az aks show -n aks-cluster -g rg-aks-public-vnet-integration --query privateFqdn
# output: not found
```

```bash
az aks get-credentials --resource-group rg-aks-public-vnet-integration --name aks-cluster
kubectl get svc
# NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
# kubernetes   ClusterIP   10.0.0.1     <none>        443/TCP   178m
kubectl describe svc kubernetes
# IPs:               10.0.0.1
# Port:              https  443/TCP
# TargetPort:        443/TCP
# Endpoints:         10.226.0.4:443
kubectl get endpoints
# NAME         ENDPOINTS        AGE
# kubernetes   10.226.0.4:443   178m
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
# output: "aks-cluste-rg-aks-private-v-17b128-4948be0c.hcp.eastus2.azmk8s.io"
# resolve the public FQDN
nslookup aks-cluste-rg-aks-private-v-17b128-4948be0c.hcp.eastus2.azmk8s.io
# output:
# Address:  10.226.0.4
```

```bash
# get the private FQDN
az aks show -n aks-cluster -g rg-aks-private-vnet-integration --query privateFqdn
# output: "aks-cluste-rg-aks-private-v-17b128-38360d0d.2788811a-873a-450d-811f-b7c7cf918694.private.eastus2.azmk8s.io""
# resolve private FQDN
nslookup aks-cluste-rg-aks-private-v-17b128-38360d0d.2788811a-873a-450d-811f-b7c7cf918694.private.eastus2.azmk8s.io
# output:
# Address:  not found
```
