# Deploying Applications into Kubernetes/AKS

## Introduction

You will learn in this lab how to deploy an application into a Kubernetes cluster in Azure using AKS.
You will explore the `kubectl` command line interface and the manifest YAML files for Kubernetes.

## Prerequisites

You will need the following tools:

1. Kubectl CLI: [https://kubernetes.io/docs/tasks/tools/](https://kubernetes.io/docs/tasks/tools/)
2. AKS (or any Kubernetes) cluster
3. Owner or Contributor of an Azure subscription: [http://azure.com/free](http://azure.com/free)

## 1. Setting up the environment

### Creating an AKS cluster in Azure

The creation of an AKS cluster could be achieved through one of these options: Azure portal, Azure CLI, Azure Powershell ARM templates, Bicep, Terraform, Ansible, Pulumi, Azure SDK and many more.
The simplest option is to use the portal as showed in this tutorial:
https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal

Another simple option would be to use the Azure CLI.

```sh
az group create --name myResourceGroup --location eastus
az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 3 --enable-addons monitoring --generate-ssh-keys
```

Next, the kubectl CLI will be used to deploy applications to the cluster.
This command needs to be connected to AKS.
To do that we use the following command:

```sh
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
```

Check that the connection was successfull by listing the nodes inside the cluster:

```sh
kubectl get nodes
# --------------------
# NAME                       STATUS   ROLES   VERSION
# aks-nodepool1-31718369-0   Ready    agent   v1.12.8
```

## 2. Deploying Pods from a public registry

>Pods are the smallest deployable units of computing that you can create and manage in Kubernetes. A Pod (as in a pod of whales or pea pod) is a group of one or more containers, with shared storage and network resources, and a specification for how to run the containers. A Pod's contents are always co-located and co-scheduled, and run in a shared context. A Pod models an application-specific "logical host": it contains one or more application containers which are relatively tightly coupled. In non-cloud contexts, applications executed on the same physical or virtual machine are analogous to cloud applications executed on the same logical host.

You will deploy an Nginx container image. This image is available in a public `container registry` called `Docker Hub`, available here [hub.docker.com/search?q=](https://hub.docker.com/search?q=).

```sh
kubectl run nginx --image=nginx  
# pod/nginx created 
```

List the created pods:

```sh 
kubectl get pods  
# NAME    READY   STATUS    RESTARTS   AGE  
# nginx   1/1     Running   0          10s  
```

View the private IP address of the Pod and its host node.

```sh 
kubectl get pods -o wide  
# NAME    READY   STATUS    IP           NODE                             
# nginx   1/1     Running   10.244.2.3   aks-agentpool-18451317-vmss000001
```

## 3. Creating a service to expose pods

Now you have a pod running in Kubernetes and you want to expose it on internet through a public IP address.

>In Kubernetes, a Service is a method for exposing a network application that is running as one or more Pods in your cluster.

Create a Service object to expose the Pod through public IP and Load Balancer.

```sh 
kubectl expose pod nginx --type=LoadBalancer --port=80
# service/nginx exposed
```
 
View the Service public IP: `20.61.145.135`.

```sh 
kubectl get svc
# NAME         TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)     
# kubernetes   ClusterIP      10.0.0.1      <none>          443/TCP     
# nginx        LoadBalancer   10.0.147.78   20.61.145.135   80:32640/TCP
```

## 4. Building and deploying container images in ACR

Instead of using a public registry like Docker Hub, you can create your own private registry in Azure where you push your own private images.

### 4.1. Creating a container registry in Azure (ACR)

Follow this link to create an ACR using the portal: [docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-portal](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-portal).
Or this link to create it through the command line: [docs.microsoft.com/en-us/azure/container-registry/container-registry-event-grid-quickstart](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-event-grid-quickstart).

### 4.2. Building an image in ACR

You can use `docker build` to build an image in your local machine, assuming you have docker installed.
However, there is another simple option. You can use Azure Container Registry (ACR).
Navigate into the `app-dotnet` folder and run the following command to package the source code, upload it into ACR and build the docker image inside ACR:

```sh 
$acrName="<your acr name>" 
az acr build -t "$acrName.azurecr.io/dotnet-app:1.0.0" -r $acrName .
```

This will build and push the image to ACR.

### 4.3. Deploying an image from ACR

Deploy the created image in ACR into the AKS cluster and replace image and registry names:

```sh 
kubectl run dotnet-app --image=<your registry id>.azurecr.io/dotnet-app:1.0.0
pod/dotnet-app created
```

Verify the pod deployed successfully.

```sh 
kubectl get pods
# NAME         READY   STATUS    RESTARTS
# dotnet-app   1/1     Running   0       
# nginx        1/1     Running   0       
```

Expose the pod on a public IP address.

```sh 
kubectl expose pod dotnet-app --type=LoadBalancer --port=80
# service/dotnet-app exposed
```

View the created service.

```sh 
kubectl get svc
# NAME         TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)     
# dotnet-app   LoadBalancer   10.0.202.46   <pending>       80:31774/TCP
# kubernetes   ClusterIP      10.0.0.1      <none>          443/TCP     
# nginx        LoadBalancer   10.0.147.78   20.61.145.135   80:32640/TCP
```

Note how the service creation is in `Pending` state. 
That is because it takes few seconds to create the public IP address and attach it to the Load Balancer.
Keep watching for the service until it will be created. Use the `-w` or `--watch`.
 
```sh 
kubectl get svc -w
# NAME         TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)     
# dotnet-app   LoadBalancer   10.0.202.46   52.142.237.17   80:31774/TCP
# kubernetes   ClusterIP      10.0.0.1      <none>          443/TCP     
# nginx        LoadBalancer   10.0.147.78   20.61.145.135   80:32640/TCP
```

## 5. Creating kubernetes YAML manifest files

Use the kubectl command line to generate a YAML manifest for a Pod.

```sh 
kubectl run nginx-yaml --restart=Never --image=nginx -o yaml --dry-run=client > nginx-pod.yaml
```

Deploy the YAML manifest to AKS:

```sh 
kubectl apply -f .\nginx-pod.yaml
# pod/nginx-yaml created
```

Verify the Pods created by YAML manifest are running.

```sh 
kubectl get pods
# NAME         READY   STATUS    RESTARTS   AGE
# dotnet-app   1/1     Running   0          9m19s
# nginx        1/1     Running   0          21m
# nginx-yaml   1/1     Running   0          9s
```

## Conclusion

You learned in this lab how to build, push and deploy a custom container image into Kubernetes.