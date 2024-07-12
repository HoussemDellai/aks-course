# Introduction to AKS Automatic

This lab guide will walk you through the process of creating a Kubernetes cluster on Azure using Azure Kubernetes Service (AKS) Automatic, deploying an application, and testing it.

## Prerequisites

- Azure CLI installed and configured
- Kubernetes CLI (kubectl) installed

## Steps

1. **Create a Resource Group**

A resource group is a logical container for resources deployed on Azure.

```sh
az group create -n $rg --location eastus
```

2. **Create a Kubernetes Cluster**

This command creates a Kubernetes cluster with Managed Prometheus and Container Insights integration enabled.

```sh
az aks create -n $aks -g $rg --sku automatic
```

3. **Connect to the Cluster**

This command retrieves credentials that kubectl uses to access the cluster.

```sh
az aks get-credentials -n $aks -g $rg
```

4. **Get Nodes**

This command lists all nodes in your cluster.

```sh
kubectl get nodes
```

5. **Create a Namespace**

Namespaces are a way to divide cluster resources between multiple users.

```sh
kubectl create ns aks-store-demo
```

6. **Deploy an Application**

This command deploys an application from a YAML file located at a given URL.

```sh
kubectl apply -n aks-store-demo -f https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/main/aks-store-ingress-quickstart.yaml
```

7. **Test the Application**

These commands list the pods in the namespace and watch the ingress resource, respectively.

```sh
kubectl get pods -n aks-store-demo
kubectl get ingress store-front -n aks-store-demo --watch
```

## More Resources

For more information about AKS, visit the [official Azure documentation](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-automatic-deploy?pivots=azure-cli).