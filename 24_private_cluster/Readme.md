# Public and private AKS clusters demystified

## Introduction
Azure Kubernetes Service (AKS) is the managed kubernetes service in Azure. It has two main components: worker nodes and control plane.  
The worker nodes are the VMs where customer applications will be deployed into.  
The control plane is the component that manages the applications and the worker nodes.  
A Kubernetes operator like a user, devops team or a release pipeline who wants to deploy applications, will do so using the control plane.  
Worker nodes and operators will need to access the control plane.  
The control plane is critical and is fully managed by Azure.  
By default, it is exposed on a public endpoint accessible over the internet.  
It could be secured using authentication and authorization using Azure AD for example. It does also support whitelisting only specific IP ranges to connect to it.  
But for organizations who want to disable this public endpoint, they can leverage the private cluster feature.  

AKS supports 4 access options to the control plane:
1) public cluster
2) private cluster
3) public cluster with API Integration enabled
4) private cluster with API Integration enabled  

This article will explain these 4 options showing the architectural implementation for each one.  
This does not cover scenarios where a user accesses an application through public Load Balancer or Ingress Controller.  

<img src="images\aks_access_modes.png">

## 1. Public cluster

Let us start with the default access mode for an AKS cluster's control plane: public access. We will create a new public cluster and explore its configuration.

```bash
# create public cluster
az group create -n rg-aks-public -l westeurope
az aks create -n aks-cluster -g rg-aks-public
```

A public cluster will have a public endpoint for the control plane called `fqdn`. It is in form of: <unique_id>.hcp.<region>.azmk8s.io. And it resolves to a public IP.

```bash
# get the public FQDN
az aks show -n aks-cluster -g rg-aks-public --query fqdn
# output: "aks-cluste-rg-aks-private-17b128-93acc102.hcp.westeurope.azmk8s.io"
# resolve the public FQDN
nslookup aks-cluste-rg-aks-public-17b128-93acc102.hcp.westeurope.azmk8s.io
# output:
# Address: 20.103.218.175
```

AKS Rest API defines a property called `privateFqdn`. Its value is null because this is a public cluster.

```bash
az aks show -n aks-cluster -g rg-aks-public --query privateFqdn
# output: null
```

Now the question is how cluster operators and `worker nodes` connect to the `control plane` ?  
Well, they both use the public endpoint (public IP).
We can check that if we look at the `kubernetes` service inside the cluster. We will see an endpoint with a public IP address. Note that it is the same IP address from the public endpoint.

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

<img src="images\architecture_public_cluster.png">

Following is print screen for created resources for public cluster.

<img src="images\resources_public_cluster.png">

> **Note:** In the cluster resources we see a public IP created with the cluster. It is used for egress traffic (outbound from pods and worker nodes). It is different from the public endpoint for our cluster. It already has a different IP address.

> AKS can whitelist the IP addresses that can connect to the control plane.
More details about [api-server-authorized-ip-ranges](https://learn.microsoft.com/en-us/azure/aks/api-server-authorized-ip-ranges)

<img src="images\authorized-ip.png">

The public cluster advantages are:  
➕ Easy to get started.  
➕ Kubernetes CLI connects easily through the public endpoint.  

However, it has some drawbacks:  
➖ Public endpoint exposure on internet is not tolerated for some use cases.  
➖ Worker nodes connect to control plane over public endpoint (within Azure backbone).  

## 2. Private cluster using Private Endpoint

For customers looking to avoid public exposure of their resources, the `Private Endpoint` would be a solution.

A [private AKS cluster](https://learn.microsoft.com/en-us/azure/aks/private-clusters) disable the public endpoint and creates a private endpoint to access the control plane. As a result, access to the cluster for kubectl and CD pipelines requires access to cluster's private endpoint.  

<img src="images\architecture_private_cluster.png">

Let us see how that works.

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

The private IP address `10.224.0.4` is the address used by Private Endpoint to access the Control Plane.

The private cluster still (by default) exposes a public FQDN resolving the private endpoint IP address.

> In private cluster, the exposed [public FQDN could be disabled](https://learn.microsoft.com/en-us/azure/aks/private-clusters#disable-public-fqdn-on-an-existing-cluster).
> ```bash
> # disable public FQDN
> az aks update -n aks-cluster -g rg-aks-private --disable-public-fqdn
> # resolve the public (disabled) FQDN
> az aks show -n aks-cluster -g rg-aks-private --query fqdn
> # output: null (no public fqdn)
> ```

The following is a print screen for the created resources. Note here the Private Endpoint, Network Interface and Private DNS Zone. They are all created inside the managed node resource group that starts with MC_. This means they will be managed by AKS for you.

<img src="images\resources_private_cluster.png">

> Private AKS creates a new Private DNS Zone by default. But you can [bring your own private DNS Zone](https://learn.microsoft.com/en-us/azure/aks/private-clusters#create-a-private-aks-cluster-with-custom-private-dns-zone-or-private-dns-subzone).

Let us take a closer look at the Private DNS Zone. Note how it adds an `A` record to resolve the private IP address of the Private Endpoint. 

<img src="images\resources_private_cluster_dns.png">

```bash
# get the private FQDN
az aks show -n aks-cluster -g rg-aks-private --query privateFqdn
# output: "aks-cluste-rg-aks-private-17b128-6d8d6675.628fd8ef-83fc-49d4-975e-c765c36407d7.privatelink.westeurope.azmk8s.io"
# resolve the private FQDN from outside the cluster VNET
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

**Important notes for private clusters**  
+ Restarting the private cluster will recreate a new Private Endpoint with different private IP.
+ In a Hub & Spoke model, more attention is needed to manage the Private DNS Zone, [more details here](https://learn.microsoft.com/en-us/azure/aks/private-clusters#hub-and-spoke-with-custom-dns).
+ No support for public agents like Github Actions or Azure DevOps Microsoft-hosted Agents with private clusters. Consider using Self-hosted Agents.
+ No support for converting existing AKS clusters into private clusters.
+ AKS control plane supports adding multiple Private Endpoints.
+ IP authorized ranges cannot be applied to the private API server endpoint, they only apply to the public API server.
+ To connect to the private cluster, consider the dedicated section below.

The pros and the cons of this mode:  
➕ No public endpoint exposed on internet (which helps implement Zero Trust Network).  
➕ Worker nodes connect to control plane using private endpoint.  
➖ More work should be done to get access to the cluster for DevOps pipelines and cluster operators.  
➖ Choosing private cluster is only possible during cluster creation. Not possible for existing clusters.

## 3. Public cluster using API Integration

The control plane exposes one single endpoint for both worker nodes and cluster operators (kubectl). That endpoint is either public or private. 
A Private endpoint is suitable for worker nodes to secure the traffic from and to control plane.  
But for access for cluster operators (admins using kubectl) and DevOps pipelines, they might prefer to use a public endpoint (if their security preferences allow).  

Does AKS support this kind of 'hybrid' access where we expose both public and private endpoints ?  

Well, yes ! That is the [API Server VNet Integration](https://learn.microsoft.com/en-us/azure/aks/api-server-vnet-integration).

Like the public AKS cluster, we will have a public endpoint (public IP). And to expose private access, unlike a private cluster that uses Private Endpoint, here We will use the `VNET Integration`.
The API server (part of the control plane) will be projected into a dedicated and delegated subnet in the cluster VNET. An internal Load Balancer will be created in that subnet. Worker nodes will be configured to access the control plane.  

Following is the simplified architecture.

<img src="images\architecture_public_cluster_vnet_integration.png">

Let us see how that works.

```bash
# create public cluster with VNET Integration
az group create -n rg-aks-public-vnet-integration -l eastus2
az aks create -n aks-cluster -g rg-aks-public-vnet-integration --enable-apiserver-vnet-integration
```

Following is print screen for created resources. Note the created internal Load Balancer.

<img src="images\resources_public_cluster_vnet_integration_ilb.png">

And note also the created Subnet within the AKS VNET.

<img src="images\resources_public_cluster_vnet_integration_subnet.png">

Note the private IP address used in the internal Load Balancer.

<img src="images\resources_public_cluster_vnet_integration.png">

Let us retrieve the public endpoint which will resolve into public IP.

```bash
# get the public FQDN
az aks show -n aks-cluster -g rg-aks-public-vnet-integration --query fqdn
# output: "aks-cluste-rg-aks-public-vn-17b128-2ab6e274.hcp.eastus2.azmk8s.io"
# resolve the public FQDN
nslookup aks-cluste-rg-aks-public-vn-17b128-2ab6e274.hcp.eastus2.azmk8s.io
# output:
# Address:  20.94.16.207
```

However, the private FQDN does not resolve anything. That is because the `privateFQDN` attribute is used only for Private Endpoint and not for VNET Integration.

```bash
# get the private FQDN
az aks show -n aks-cluster -g rg-aks-public-vnet-integration --query privateFqdn
# output: not found
```

If we take a look at the kubernetes service endpoint within the cluster, we can see the same private IP as in the internal Load Balancer.

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

> Note: You can let AKS create and configure the subnet for VNET Integration and you can also bring your own subnet.

It is possible to [convert existing public AKS clusters to use VNET Integration](https://learn.microsoft.com/en-us/azure/aks/api-server-vnet-integration#convert-an-existing-aks-cluster-to-api-server-vnet-integration). Pay attention when you do that, the public IP address of the control plane will change.  

Pros and cons of this approach:  
➕ Easy to get started.  
➕ Kubernetes CLI connects easily through the public endpoint.  
➕ Worker nodes connect to control plane over internal Load Balancer.  
➖ Uses a subnet with CIDR range `/28` at least.  

## 4. Private cluster using VNET Integration

Default VNET Integration will create private access for the worker nodes to access the control plane through internal Load Balancer. Any resource with access to that internal Load Balancer can access the cluster control plane. This is a simpler alternative to using the Private Endpoint with Private DNS Zone for private clusters.
But it keeps the public endpoint. We can [disable or enable that public endpoint](https://learn.microsoft.com/en-us/azure/aks/api-server-vnet-integration#enable-or-disable-private-cluster-mode-on-an-existing-cluster-with-api-server-vnet-integration).

<img src="images\architecture_private_cluster_vnet_integration.png" width="60%">

Let us see how that works.

```bash
# create private cluster with VNET Integration
az group create -n rg-aks-private-vnet-integration -l eastus2
az aks create -n aks-cluster -g rg-aks-private-vnet-integration --enable-apiserver-vnet-integration --enable-private-cluster
```

That will create the following resources. Note the internal Load Balancer and the Private DNS Zone.

<img src="images\resources_private_cluster_vnet_integration.png">

The Private DNS Zone will privately resolve the private FQDN to the private IP of the internal Load Balancer to communicate with control plane.

<img src="images\resources_private_cluster_vnet_integration_dns.png">

Note here how the public FQDN (could be disabled) resolves to the private IP.

```bash
# get the public FQDN
az aks show -n aks-cluster -g rg-aks-private-vnet-integration --query fqdn
# output: "aks-cluste-rg-aks-private-v-17b128-4948be0c.hcp.eastus2.azmk8s.io"
# resolve the public FQDN
nslookup aks-cluste-rg-aks-private-v-17b128-4948be0c.hcp.eastus2.azmk8s.io
# output:
# Address:  10.226.0.4
```

Sure enough, the private FQDN could not be resolved outside the AKS network.

```bash
# get the private FQDN
az aks show -n aks-cluster -g rg-aks-private-vnet-integration --query privateFqdn
# output: "aks-cluste-rg-aks-private-v-17b128-38360d0d.2788811a-873a-450d-811f-b7c7cf918694.private.eastus2.azmk8s.io""
# resolve private FQDN
nslookup aks-cluste-rg-aks-private-v-17b128-38360d0d.2788811a-873a-450d-811f-b7c7cf918694.private.eastus2.azmk8s.io
# output:
# Address:  not found
```

Pros and cons of this approach:    
➕ Kubernetes CLI connects only through internal Load Balancer.  
➕ Worker nodes connect to control plane over internal Load Balancer.  
➖ Uses a subnet with CIDR range `/28` at least.

## How to access a private cluster

+ Az AKS command invoke –command “kubectl get pods”
+ JumpBox VM inside the AKS VNET or peered network
+ Use an Express Route or VPN connection
+ Use a private endpoint connection
More details on how to [connect to private cluster](https://learn.microsoft.com/en-us/azure/aks/private-clusters#options-for-connecting-to-the-private-cluster).

> The [AKS command invoke](https://learn.microsoft.com/en-us/azure/aks/command-invoke) could be used to easily access private clusters without setting any network access. It will use the Azure API to get access to the cluster. This option could be disabled.

## Conclusion

<table>
<tr>
<td></td><td>Public FQDN</td><td>Private FQDN</td><td>Public FQDN could be disactivated</td><td>How to access Control Plane</td>
</tr>
<tr>
<td>Public cluster</td><td>Yes (public IP)</td><td>No</td><td>No</td><td>Public IP/FQDN for Control Plane</td>
</tr>
<tr>
<td>Private cluster</td><td>Yes (private IP)</td><td>Yes (Private Endpoint)</td><td>Yes</td><td>Private Endpoint + Private DNS Zone</td>
</tr>
<tr>
<td>VNET Integration + public cluster</td><td>Yes (public IP)</td><td>Yes (private IP of internal Load Balancer)</td><td>No</td><td>VNET Integration + Internal Load Balancer</td>
</tr>
<tr>
<td>VNET Integration + private cluster</td><td>Yes (private IP)</td><td>Yes (private IP of internal Load Balancer)</td><td>Yes</td><td>VNET Integration + Internal Load Balancer + Private DNS Zone
</td>
</tr>
</table>

This article is also available in a video format on youtube:
https://www.youtube.com/watch?v=8e8vBLZiIhQ&list=PLpbcUe4chE79sB7Jg7B4z3HytqUUEwcNE&index=60&t=772s

<a href="https://www.youtube.com/watch?v=8e8vBLZiIhQ&list=PLpbcUe4chE79sB7Jg7B4z3HytqUUEwcNE&index=60&t=772s"> <img src="images\video-youtube.png"> </a>