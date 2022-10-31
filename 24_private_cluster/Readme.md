# Public and private AKS clusters demystified

## Introduction
Azure Kubernetes Service (AKS) is the managed kubernetes service in Azure. It have two main components: worker nodes and control plane.  
The worker nodes are the VMs where customer applications will be deployed into.  
The control plane is the component that manages the applications and the worker nodes.  
A Kubernetes operator like a user, devops team or a release pipeline who wants to deploy applications, will do so using the control plane.  
Worker nodes and operators will need to access the control plane.  
The control plane is very critical and is fully managed by Azure.  
By default, it is exposed on a public endpoint accessible over the internet.  
It could be secured using authentication and authorisation using Azure AD for example. It does also support whitelisting only secific IP ranges to connect to it.  
But for organisations who wants to disable this public endpoint, they can leverage the private cluster feature.  

AKS supports 4 access options:
1) public cluster
2) private cluster
3) public cluster with API Integration enabled
4) private cluster with API Integration enabled  

This article will explain these 4 options showing the architectural implementation for each one.  
This is not covering scenarios where a user access an application through public Load Balancer or Ingress Controller.  

<img src="images\aks_access_modes.png" width="60%">

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

<img src="images\architecture_public_cluster.png" width="60%">

Following is print screen for created resources.

<img src="images\resources_public_cluster.png" width="60%">

## 2. Private cluster using Private Endpoint
```bash
# create private cluster
az group create -n rg-aks-private -l westeurope
az aks create -n aks-cluster -g rg-aks-private --enable-private-cluster
```

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

<img src="images\architecture_private_cluster.png" width="60%">

Following is print screen for created resources.

<img src="images\resources_private_cluster.png" width="60%">

<img src="images\resources_private_cluster_dns.png" width="60%">

## 3. Public cluster using API Integration
```bash
# create public cluster with VNET Integration
az group create -n rg-aks-public-vnet-integration -l eastus2
az aks create -n aks-cluster -g rg-aks-public-vnet-integration --enable-apiserver-vnet-integration
```

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

<img src="images\architecture_public_cluster_vnet_integration.png" width="60%">

Following is print screen for created resources.

<img src="images\resources_public_cluster_vnet_integration.png" width="60%">

<img src="images\resources_public_cluster_vnet_integration_ild.png" width="60%">

<img src="images\resources_public_cluster_vnet_integration_subnet.png" width="60%">

## 4. Private cluster using API Integration
```bash
# create private cluster with VNET Integration
az group create -n rg-aks-private-vnet-integration -l eastus2
az aks create -n aks-cluster -g rg-aks-private-vnet-integration --enable-apiserver-vnet-integration --enable-private-cluster
```

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

<img src="images\architecture_private_cluster_vnet_integration.png" width="60%">

Following is print screen for created resources.

<img src="images\resources_private_cluster_vnet_integration.png" width="60%">

<img src="images\resources_private_cluster_vnet_integration_dns.png" width="60%">

Conclusion

<img src="images\recap.png" width="60%">