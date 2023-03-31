# Using Azure Application Gateway as Ingress Controller for AKS

## Introduction

Kubernetes exposes services securely (HTTPS) through an ingress controller.
Kubernets supports the ingress resources. But users should provide and install a plugin to handle ingress traffic. There are lots of plugins available like Nginx Ingress Controller or also Azure Application Gateway Ingress Controller (AGIC).

In this demonstration, we will enable AGIC extension in AKS and use it to expose a sample application to the internet or internal network.

## How AGIC works ?

Application Gateway will act as the `frontend` that will receive customer traffic.
Then it will route the traffic to the pods directly.

How that is possible ?

This achievable because the Application Gateway and the AKS cluster should be in the same network. Either in 2 separate subnets within the same VNET or in 2 different peered VNETs. So the App Gateway can reach the Pods through their private IPs.

But how the App Gateway could know the private IPs of the pods ?

Here comes the AGIC extension. AGIC will be installed into the AKS cluster as a pod within kube-system namespace. Its role is to listen for ingress resources creation, get pod IPs then use it to control the configuration of the App Gateway. This means it will connect to the App Gateway and authenticate and authorize using a User Assigned Managed Identity created within the node resource group. AGIC will create the listeners and backend configuration for App Gateway.
The following picture shows the workflow.

<img src="images\architecture-white.png" style="background-color:white;">

## What are the pros and cons of using AGIC when compared with Nginx Ingress Controler ?

There are a lot of features available for App Gateway and for Nginx IC. Here I will put only the most relevant ones. (this is not a refence for comparing the 2 tools).

| | Application Gateway | Nginx Ingress Controller |
| ----------- | ----------- | ----------- |
| Support HTTPS/TLS | Yes | Yes |
| TLS decryption | outside the cluster | inside the cluster |
| Scale out | Outside the cluster | Inside the cluster (HPA) |
| Consume cluster resources | No | Yes |
| Cost | Cost of Azure resource (more expensive) | Cost of pods inside cluster (cheaper) |
| WAF | Supported with SKU WAF_v2 | Very basic, needs Nginx Plus license |

Note: The App Gateway will not consume resources from the cluster when doing TLS termination or scale out.

Note: With Kubenet, the cluster route table should be attached to the App Gateway subnet to reach pods.
More details here: https://azure.github.io/application-gateway-kubernetes-ingress/how-tos/networking/

## 1. Creating an AKS cluster with Azure CNI network plugin

App Gateway works with both Azure CNI and Kubenet plugins.

```shell
az group create -n rg-aks-cluster -l westeurope

az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure
```

AKS by default uses 10.224.0.0/12 for VNET and 10.224.0.0/16 for Subnet

## 2. Enabling Azure Application Gateway Ingress Controller

Enabling the AGIC component could be done using the portal, the command line, ARM templates, Bicep and Terraform.
The easiest option is to enable it using the Azure portal. 
From inside AKS, go to Networking section then enable Application Gateway.

<img src="images\enable-agic.png">

App Gateway will be deployed into its own subnet. Provide a subnet CIDR range. `/27` would be enough.

<img src="images\appgw-subnet.png">

If you prefer using the command line, here is the command.

```shell
az aks addon enable -n aks-cluster -g rg-aks-cluster `
       --addon ingress-appgw `
       --appgw-subnet-cidr 10.225.0.0/16 `
       --appgw-name gateway
```

## 3. Checking the created resources

AGIC will create the following resources:
1) New ingress class called : `azure-application-gateway`
2) AGIC pod inside kube-system namespace
3) Azure Application Gateway
4) New Subnet in cluster VNET
5) Public IP for App Gateway
6) User Managed Identity in node resource group for AGIC pod

Check the created ingress class.

```shell
az aks get-credentials -n aks-cluster -g rg-aks-cluster

kubectl get ingressclass
# NAME                        CONTROLLER                  PARAMETERS   AGE
# azure-application-gateway   azure/application-gateway   <none>       3h24m
```

Check the created AGIC pod inside kube-system namespace.

```shell
kubectl get pods -n kube-system -l app=ingress-appgw
# NAME                                       READY   STATUS    RESTARTS   AGE
# ingress-appgw-deployment-8c6db6f79-vzf5x   1/1     Running   0          43m
```

Check the created Azure Application Gateway, Public IP for App Gateway and User Managed Identity in node resource group.

<img src="images\node-rg.png"/>

Note the RBAC role `Contributor` over the node resource group. This will be used by AGIC pod to connect to the App Gateway and change its configuration.

Check the created new Subnet in cluster VNET.

<img src="images\subnet.png"/>

## 4. Deploying (public) ingress using App Gateway

Let's deploy a sample application and expose it through public endpoint.
We create a deployment, service and ingress resources.

The full file content is here: https://raw.githubusercontent.com/HoussemDellai/docker-kubernetes-course/main/35_app_gateway_ingress/ingress_appgw.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: aspnetapp
spec:
  ingressClassName: azure-application-gateway
  rules:
  - http:
      paths:
      - path: /
        backend:
          service:
            name: aspnetapp
            port:
              number: 80
        pathType: Exact
```

Let's deploy the resources into AKS.

```shell
kubectl apply -f ingress_appgw.yaml
# deployment.apps/aspnetapp created
# service/aspnetapp created
# ingress.networking.k8s.io/aspnetapp created

kubectl get pods,svc,ingress
# NAME                            READY   STATUS              RESTARTS   AGE
# pod/aspnetapp-bbcc5cf6c-4mtdc   1/1     Running             0          6s
# pod/aspnetapp-bbcc5cf6c-k8lqw   1/1     Running             0          6s
# pod/aspnetapp-bbcc5cf6c-x8r7z   0/1     ContainerCreating   0          6s

# NAME                 TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
# service/aspnetapp    ClusterIP   10.0.115.64   <none>        80/TCP    6s
# service/kubernetes   ClusterIP   10.0.0.1      <none>        443/TCP   32m

# NAME                                  CLASS                       HOSTS   ADDRESS        PORTS   AGE
# ingress.networking.k8s.io/aspnetapp   azure-application-gateway   *       20.8.165.123   80      6s

kubectl get pods -o wide
# NAME                        READY   STATUS    RESTARTS   AGE   IP            NODE                             
# aspnetapp-bbcc5cf6c-4mtdc   1/1     Running   0          41s   10.224.0.85   aks-nodepool1-28007812-vmss000002
# aspnetapp-bbcc5cf6c-k8lqw   1/1     Running   0          41s   10.224.0.34   aks-nodepool1-28007812-vmss000000
# aspnetapp-bbcc5cf6c-x8r7z   1/1     Running   0          41s   10.224.0.28   aks-nodepool1-28007812-vmss000001
```

Note from above output the public IP address `20.8.165.123` for the exposed ingress.
That IP is the same as the App Gateway public IP.

## 5. Deploying (internal) ingress using App Gateway

### Enable Application Gateway private IP

Some organisations wants to expose their AKS applications on internal network, instead of public network.
Application Gateway have a public IP by default. But it can also have a (only one) private IP.
AGIC will use this private IP to expose private services.
Let's enable Application Gateway private IP using command line. This could be done also using Azure portal.
Change the values accordingly and choose an IP within the range of the App Gateway Subnet (avoid 3 first IPs).

```shell
az network application-gateway frontend-ip create `
           --name frontendIp `
           --gateway-name gateway `
           --resource-group MC_rg-aks-cluster_aks-cluster_westeurope `
           --vnet-name aks-vnet-11733080 `
           --subnet gateway-subnet `
           --private-ip-address 10.225.0.10
```

### Create private ingress

To create a private ingress resource, we just add the annotation: `appgw.ingress.kubernetes.io/use-private-ip: "true"`.
Here is an example:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: aspnetapp-internal
  annotations:
    appgw.ingress.kubernetes.io/use-private-ip: "true"
spec:
  ingressClassName: azure-application-gateway
  rules:
  - http:
      paths:
      - path: /
        backend:
          service:
            name: aspnetapp
            port:
              number: 80
        pathType: Exact
```

```shell
kubectl apply -f ingress_private.yaml
# ingress.networking.k8s.io/aspnetapp-internal created

kubectl get ingress
# NAME                 CLASS                       HOSTS   ADDRESS       PORTS   AGE
# aspnetapp            azure-application-gateway   *       20.23.82.47   80      131m
# aspnetapp-internal   azure-application-gateway   *       10.225.0.10   80      27m

kubectl run nginx --image=nginx
kubectl exec nginx -it -- /bin/bash
## inside nginx
root@nginx:/# curl 10.225.0.10
# <!DOCTYPE html>
# <html lang="en">
# <head>
#     <meta charset="utf-8" />
# ...
```

## Conclusion

This demonstration is a getting started with App Gateway integration with AKS.
We choosed the simplest configuration. However, there are a lot of possibilities for multiple scenarios.
Here are some of the possibilities:
- Share an Application Gateway between multiple clusters.
- Can configure TLS certificates.
- Configure re-routing.
- Configure App Gateway scalability.
- Rewrite HTTP headers and URL.
- Enabling Cookie affinity.

Note: there is some limitations to App Gateway. For example, the public IP could not be disabled.

## More resources:

https://azure.github.io/application-gateway-kubernetes-ingress/