# Using Azure Application Gateway as Ingress Controller for AKS

## Introduction

Kubernetes exposes services securely (HTTPS) through an ingress controller.
Kubernets supports the ingress resources. But users should provide and install a plugin to handle ingress traffic. There are lots of plugins available like Nginx Ingress Controller or also Azure Application Gateway Ingress Controller (AGIC).

In this demonstration, we will enable AGIC extension in AKS and use it to expose a sample application to the internet.

## How AGIC works ?

Application Gateway will act as the `frontend` that will receive customer traffic.
Then it will route the traffic to the pods directly.

How that is possible ?

This achievable because the Application Gateway and the AKS cluster should be in the same network. Either in 2 separate subnets within the same VNET or in 2 different peered VNETs. So the App Gateway can reach the Pods through their private IPs.

But how the App Gateway could know the private IPs of the pods ?

Here comes the AGIC extension. AGIC will be installed into the AKS cluster as a pod within kube-system namespace. Its role is to listen for ingress resources creation, get pod IPs then use it to control the configuration of the App Gateway. This means it will connect to the App Gateway and authenticate and authorize using a User Assigned Managed Identity created within the node resource group. AGIC will create the listeners and backend configuration for App Gateway.
The following picture shows the workflow.

<img src="images\architecture.png" style="background-color:white;">

## What are the pros and cons of using AGIC when compared with Nginx Ingress Controler ?

There are a lot of features available for App Gateway and for Nginx IC. Here I will put only the most relevant ones. (this is not a refence for comparing the 2 tools).

| | Application Gateway | Nginx Ingress Controller |
| ----------- | ----------- | ----------- |
| Support HTTPS/TLS | Yes | Yes |
| TLS decryption | outside the cluster | inside the cluster |
| Scale out | Outside the cluster | Inside the cluster (HPA) |
| Consume cluster resources | No | No |
| Cost | Cost of Azure resource (more expensive) | Cost of pods inside cluster (cheaper) |
| WAF | Supported with SKU WAF_v2 | Very basic, needs Nginx Plus license |

Note: The App Gateway will not consume resources from the cluster when doing TLS termination or scale out.

## 1. Create an AKS cluster with Azure CNI network plugin

```shell
az group create -n rg-aks-cluster -l westeurope

az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure

# AKS by default uses 10.224.0.0/12 for VNET and 10.224.0.0/16 for Subnet

# enable Azure Application Gateway Ingress Controller

az aks addon enable -n aks-cluster -g rg-aks-cluster `
       --addon ingress-appgw `
       --appgw-subnet-cidr 10.225.0.0/16 `
       --appgw-name gateway

# connect to AKS cluster

az aks get-credentials -n aks-cluster -g rg-aks-cluster

kubectl get ingressclass
# NAME                        CONTROLLER                  PARAMETERS   AGE
# azure-application-gateway   azure/application-gateway   <none>       3h24m

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