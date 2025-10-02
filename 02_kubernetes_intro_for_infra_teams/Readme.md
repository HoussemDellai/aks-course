# Introduction to AKS for Infrastructure Teams

## Introduction

In this lab, you will learn how to deploy an application into a Kubernetes cluster in Azure using AKS (Azure Kubernetes Service).
You will explore the basic concepts of Kubernetes, such as Pods, Services, and Deployments, and how to manage them using `kubectl`.
You will also explore some aspects of networking in AKS, such as creating a Load Balancer and exposing services to the internet.

## Creating an AKS cluster

Let's start by creating an AKS cluster in Azure. This cluster will be used to deploy and manage your applications.

```sh
az group create --name rg-aks-cluster --location francecentral
az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay -k 1.33.3 --node-vm-size standard_d2ads_v6 --node-osdisk-type Ephemeral --node-osdisk-size 64 --enable-apiserver-vnet-integration
```

>Note: The -k option specifies the Kubernetes version to use. You can check the available versions with `az aks get-versions --location francecentral --output table`.

Now let's connect to the cluster to use the `kubectl` CLI to deploy applications.

```sh
az aks get-credentials -n aks-cluster -g rg-aks-cluster --overwrite-existing
```

Let's check that the connection was successful by listing the nodes inside the cluster:

```sh
kubectl get nodes
# NAME                                STATUS   ROLES    AGE     VERSION
# aks-nodepool1-23059632-vmss000000   Ready    <none>   3d16h   v1.32.4
# aks-nodepool1-23059632-vmss000001   Ready    <none>   3d16h   v1.32.4
# aks-nodepool1-23059632-vmss000002   Ready    <none>   3d16h   v1.32.4
```

Lets now try the following command which lists all the namespaces in the cluster:

```sh
kubectl get namespaces -A
# NAME              STATUS   AGE
# default           Active   3d16h
# kube-node-lease   Active   3d16h
# kube-public       Active   3d16h
# kube-system       Active   3d16h
```

The `kube-system` namespace is where the Kubernetes system components are running, such as DNS server, proxy, metrics server, etc.

```sh
kubectl get pods -n kube-system
# NAME                                             READY   STATUS    RESTARTS   AGE
# azure-cns-77xqz                                  1/1     Running   0          3d16h
# azure-cns-f4jzm                                  1/1     Running   0          3d16h
# azure-cns-l5kqv                                  1/1     Running   0          3d16h
# azure-ip-masq-agent-brt6z                        1/1     Running   0          3d16h
# azure-ip-masq-agent-ndnxq                        1/1     Running   0          3d16h
# azure-ip-masq-agent-xsrxm                        1/1     Running   0          3d16h
# cloud-node-manager-hvp48                         1/1     Running   0          3d16h
# cloud-node-manager-ps672                         1/1     Running   0          3d16h
# cloud-node-manager-twxfl                         1/1     Running   0          3d16h
# coredns-77f74c584-hjhf7                          1/1     Running   0          3d16h
# coredns-77f74c584-n47d6                          1/1     Running   0          3d16h
# coredns-autoscaler-79bcb4fd6b-sp572              1/1     Running   0          3d16h
# csi-azuredisk-node-m5kzw                         3/3     Running   0          3d16h
# csi-azuredisk-node-pvj9s                         3/3     Running   0          3d16h
# csi-azuredisk-node-sgd5z                         3/3     Running   0          3d16h
# csi-azurefile-node-2z9tc                         3/3     Running   0          3d16h
# csi-azurefile-node-6tslv                         3/3     Running   0          3d16h
# csi-azurefile-node-8sd58                         3/3     Running   0          3d16h
# konnectivity-agent-986b8bb95-7km95               1/1     Running   0          3d16h
# konnectivity-agent-986b8bb95-lnjmp               1/1     Running   0          3d16h
# konnectivity-agent-autoscaler-844df78bbd-q2r2m   1/1     Running   0          3d16h
# kube-proxy-9p2lr                                 1/1     Running   0          3d16h
# kube-proxy-pcn4z                                 1/1     Running   0          3d16h
# kube-proxy-rd6ps                                 1/1     Running   0          3d16h
# metrics-server-65b6ff4fc4-2ndz8                  2/2     Running   0          3d16h
# metrics-server-65b6ff4fc4-lwd2x                  2/2     Running   0          3d16h
```

## Deploying an Nginx Pod

When you want to deploy a container into Kubernetes, you will use a Pod.
A Pod is the smallest deployable unit in Kubernetes and can contain one or more containers.

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
NAME    READY   STATUS    RESTARTS   AGE     IP             NODE                                NOMINATED NODE   READINESS GATES
nginx   1/1     Running   0          15s     10.244.2.135   aks-nodepool1-23059632-vmss000000   <none>           <none>
```

So now the pod is running in one of the nodes in the cluster. It was saved into the `os disk` of the node. Lets prove that.

```sh
kubectl debug node/aks-nodepool1-23059632-vmss000000 -it --image=mcr.microsoft.com/azurelinux/busybox:1.36
# / #
```

This command will create a debug container in the node and give you a shell inside it. Then use the command `chroot /host` to change the root directory to the host filesystem.

```sh
chroot /host
# root@aks-nodepool1-23059632-vmss000000:/#
```

Now you can see the contents of the node filesystem. The pods data are saved in the `/var/lib/kubelet/pods/` directory.

```sh
ls /var/lib/kubelet/pods/
# 015080dd-d6a2-4ba3-abff-806cbee0bf3d  5057d0ac-059a-4982-b6ca-7524df870629  8f5f1abf-9887-4250-9f6c-b62f9b7f6fef  c7f65a1e-4d81-4c75-81a8-9beea2618761
# 096109b9-77f8-46c5-9c67-1d447ff835b4  5678c256-936b-4f8e-a5a4-5d25f89205f0  96e09b0d-c1e3-4621-86fc-a5ae7b67f741  f4b11676-394a-4c3b-8c4a-e1286c8dd3f6
# 278644c7-63cd-4d53-83b0-69fc611f30cc  6e006c86-1917-4944-9d19-f3517fc3acac  a9a08e56-5e79-4aba-95ba-548e00382447  ff8aa4ed-29f5-4b25-ae0f-82e102411f3a
# 3695f266-7f72-4404-8750-a8ad762ee329  7494ff6b-5dde-4c5e-828f-ef97e43e09ac  abd66aae-0964-42dd-9a2d-7239cd69c22c
# 4939e184-97c1-41c9-b2e7-11119f73b6b9  7935c1c1-3ec5-4188-8496-ce3ed652b1a1  b865a7b8-5377-48ed-ad91-296a00e96f43
# 4f298cc1-16af-4202-8755-d9953f3131ad  8d70bff7-daed-40c6-806e-62692c3a5530  bae179d7-12d3-4f62-82aa-2ecb3520a750
```

A better way to see the pods is to use the `crictl` command. It is a command line interface for CRI (Container Runtime Interface) that allows you to manage containers and pods in Kubernetes nodes. It is almost as the `docker` CLI, but it works with any container runtime that implements the CRI, such as containerd or CRI-O.

Lets list all the images in the node:

```sh
crictl images
```

<details>

<summary>Click to see the output</summary>

```sh
# IMAGE                                                                                 TAG                                               IMAGE ID            SIZE
# docker.io/library/nginx                                                               latest                                            9a9a9fd723f1d       72.2MB
# mcr.microsoft.com/aks/aks-gpu-cuda                                                    550.144.03-20250328201547                         6edb0e5685060       513MB
# mcr.microsoft.com/aks/aks-node-ca-watcher                                             master.241021.1                                   22c9fbb430259       3.51MB
# mcr.microsoft.com/aks/aks-node-ca-watcher                                             static                                            22c9fbb430259       3.51MB
# mcr.microsoft.com/aks/ip-masq-agent-v2                                                v0.1.15                                           a811f11a728f7       21.8MB
# mcr.microsoft.com/azure-policy/policy-kubernetes-addon-prod                           1.11.0                                            5591f1d58a150       31.7MB
# mcr.microsoft.com/azure-policy/policy-kubernetes-addon-prod                           1.11.1                                            270a6a34fa842       33.3MB
# mcr.microsoft.com/azure-policy/policy-kubernetes-webhook                              1.11.0                                            d4805654ac97d       28MB
# mcr.microsoft.com/azure-policy/policy-kubernetes-webhook                              1.11.1                                            517b9a3a3a5af       29.3MB
# mcr.microsoft.com/azurelinux/busybox                                                  1.36                                              5e55298aab9ca       5.94MB
# mcr.microsoft.com/azuremonitor/containerinsights/ciprod/prometheus-collector/images   6.17.0-main-05-29-2025-1a3ab39b                   af0aa6344969b       287MB
# mcr.microsoft.com/azuremonitor/containerinsights/ciprod/prometheus-collector/images   6.17.0-main-05-29-2025-1a3ab39b-cfg               42443c520da8f       104MB
# mcr.microsoft.com/azuremonitor/containerinsights/ciprod/prometheus-collector/images   6.17.0-main-05-29-2025-1a3ab39b-targetallocator   06dd1248bc2cc       42.9MB
# mcr.microsoft.com/azuremonitor/containerinsights/ciprod                               3.1.27                                            57fff2f487fe5       275MB
# mcr.microsoft.com/cbl-mariner/busybox                                                 1.35                                              54621300defc3       6.32MB
# mcr.microsoft.com/containernetworking/azure-cni                                       v1.4.59                                           c6e6ad41a95d1       57.1MB
# mcr.microsoft.com/containernetworking/azure-cni                                       v1.5.42                                           60cc1c9118d29       84.7MB
# mcr.microsoft.com/containernetworking/azure-cni                                       v1.5.44                                           6f31e6ab1dc31       84.7MB
# mcr.microsoft.com/containernetworking/azure-cni                                       v1.6.20                                           3dda6de725d54       86.1MB
# mcr.microsoft.com/containernetworking/azure-cni                                       v1.6.21                                           bbe7dabba5e9c       86.1MB
# mcr.microsoft.com/containernetworking/azure-cns                                       v1.4.59                                           984d9ea36e98d       208MB
# mcr.microsoft.com/containernetworking/azure-cns                                       v1.5.44                                           f0db0696d4598       213MB
# mcr.microsoft.com/containernetworking/azure-cns                                       v1.5.45                                           eeec37aaca122       219MB
# mcr.microsoft.com/containernetworking/azure-cns                                       v1.6.23                                           bc65361e618cc       63.6MB
# mcr.microsoft.com/containernetworking/azure-cns                                       v1.6.24                                           abaf82aa94920       63.6MB
# mcr.microsoft.com/containernetworking/azure-cns                                       v1.6.25                                           9384d7158fac8       63.2MB
# mcr.microsoft.com/containernetworking/azure-ipam                                      v0.0.7                                            dbb7d99837843       25.8MB
# mcr.microsoft.com/containernetworking/azure-ipam                                      v0.2.0                                            d0712c8269b91       26.3MB
# mcr.microsoft.com/containernetworking/azure-ipam                                      v0.2.1                                            0de157d19366d       26.8MB
# mcr.microsoft.com/containernetworking/azure-npm                                       v1.5.45                                           5f5c892ab7cae       112MB
# mcr.microsoft.com/containernetworking/cilium/cilium                                   v1.14.18-250107                                   9571fc7b84c3b       196MB
# mcr.microsoft.com/containernetworking/cilium/cilium                                   v1.14.19-250129                                   99caee4bf067b       196MB
# mcr.microsoft.com/containernetworking/cilium/cilium                                   v1.16.5-250110                                    a21c9749171b0       224MB
# mcr.microsoft.com/containernetworking/cilium/cilium                                   v1.16.6-250129                                    b5265c46e6a4a       224MB
# mcr.microsoft.com/oss/azure/secrets-store/provider-azure                              v1.6.2                                            607be4af55858       14.8MB
# mcr.microsoft.com/oss/kubernetes-csi/azuredisk-csi                                    v1.30.12                                          95614bd9b8b95       66.7MB
# mcr.microsoft.com/oss/kubernetes-csi/azuredisk-csi                                    v1.31.10                                          ba632c6857cc8       70.4MB
# mcr.microsoft.com/oss/kubernetes-csi/azuredisk-csi                                    v1.32.6                                           50685c2c0149a       68.5MB
# mcr.microsoft.com/oss/kubernetes-csi/azuredisk-csi                                    v1.32.7                                           d1276741d6bbc       66.2MB
# mcr.microsoft.com/oss/kubernetes-csi/azuredisk-csi                                    v1.33.1                                           10aabb314a550       66.2MB
# mcr.microsoft.com/oss/kubernetes-csi/azurefile-csi                                    v1.30.10                                          8c6a480624f04       121MB
# mcr.microsoft.com/oss/kubernetes-csi/azurefile-csi                                    v1.31.6                                           c22d31984f886       121MB
# mcr.microsoft.com/oss/kubernetes-csi/azurefile-csi                                    v1.32.3                                           9823e2b9c4ffc       120MB
# mcr.microsoft.com/oss/kubernetes-csi/azurefile-csi                                    v1.32.4                                           9de0dd3ca3123       121MB
# mcr.microsoft.com/oss/kubernetes-csi/azurefile-csi                                    v1.33.1                                           2db41d64e45ed       126MB
# mcr.microsoft.com/oss/kubernetes-csi/blob-csi                                         v1.24.10                                          5e6585390dcfd       185MB
# mcr.microsoft.com/oss/kubernetes-csi/blob-csi                                         v1.25.7                                           aa1191d74fb55       187MB
# mcr.microsoft.com/oss/kubernetes-csi/blob-csi                                         v1.26.4                                           f083c13ff1e46       187MB
# mcr.microsoft.com/oss/kubernetes-csi/csi-node-driver-registrar                        v2.12.0                                           f2839dc20fd2e       14MB
# mcr.microsoft.com/oss/kubernetes-csi/csi-node-driver-registrar                        v2.13.0                                           03a0bf5a23a8a       14.8MB
# mcr.microsoft.com/oss/kubernetes-csi/livenessprobe                                    v2.14.0                                           b2325d74a9194       14.7MB
# mcr.microsoft.com/oss/kubernetes-csi/livenessprobe                                    v2.15.0                                           36d7b51905972       15MB
# mcr.microsoft.com/oss/kubernetes-csi/secrets-store/driver                             v1.4.8                                            debfe36431cb6       65.7MB
# mcr.microsoft.com/oss/kubernetes/azure-cloud-node-manager                             v1.29.13                                          84d8a1c401e1d       21.5MB
# mcr.microsoft.com/oss/kubernetes/azure-cloud-node-manager                             v1.29.15                                          3e8dc03305285       21.5MB
# mcr.microsoft.com/oss/kubernetes/azure-cloud-node-manager                             v1.30.10                                          93a49e0608237       21.8MB
# mcr.microsoft.com/oss/kubernetes/azure-cloud-node-manager                             v1.30.12                                          bebdae9199424       21.9MB
# mcr.microsoft.com/oss/kubernetes/azure-cloud-node-manager                             v1.31.4                                           43563ea2d21bf       22.4MB
# mcr.microsoft.com/oss/kubernetes/azure-cloud-node-manager                             v1.31.6                                           9fa3724a80429       22.5MB
# mcr.microsoft.com/oss/kubernetes/azure-cloud-node-manager                             v1.32.3                                           13c6143b4df21       30.7MB
# mcr.microsoft.com/oss/kubernetes/azure-cloud-node-manager                             v1.32.5                                           a758ab0972266       30.6MB
# mcr.microsoft.com/oss/kubernetes/azure-cloud-node-manager                             v1.33.0                                           d6601a5bce2fe       31.4MB
# mcr.microsoft.com/oss/kubernetes/kube-proxy                                           v1.27.102-akslts                                  b0f2ff07e4691       81.2MB
# mcr.microsoft.com/oss/kubernetes/kube-proxy                                           v1.27.103-akslts                                  c2184f44cee88       81.2MB
# mcr.microsoft.com/oss/kubernetes/kube-proxy                                           v1.28.100-akslts                                  2c712698044e6       83MB
# mcr.microsoft.com/oss/kubernetes/kube-proxy                                           v1.28.101-akslts                                  ca04eb435eee4       83MB
# mcr.microsoft.com/oss/kubernetes/kube-proxy                                           v1.29.14                                          4ac042945d270       84.2MB
# mcr.microsoft.com/oss/kubernetes/kube-proxy                                           v1.29.15                                          68a6f10bb24e8       84.6MB
# mcr.microsoft.com/oss/kubernetes/kube-proxy                                           v1.30.11                                          d11bed7f62459       86.4MB
# mcr.microsoft.com/oss/kubernetes/kube-proxy                                           v1.30.12                                          60c91be4cf151       86.4MB
# mcr.microsoft.com/oss/kubernetes/kube-proxy                                           v1.31.8                                           d302f9778ff41       93.2MB
# mcr.microsoft.com/oss/kubernetes/kube-proxy                                           v1.31.9                                           8393e04be88ed       93.2MB
# mcr.microsoft.com/oss/kubernetes/kube-proxy                                           v1.32.4                                           e56d653ed7010       95.3MB
# mcr.microsoft.com/oss/kubernetes/kube-proxy                                           v1.32.5                                           4ed537536f076       95.3MB
# mcr.microsoft.com/oss/kubernetes/kube-proxy                                           v1.33.1                                           8051d06c4366f       99.1MB
# mcr.microsoft.com/oss/kubernetes/pause                                                3.6                                               7b178dc69474d       301kB
# mcr.microsoft.com/oss/nginx/nginx                                                     1.17.3-alpine                                     d87c83ec7a667       8.67MB
# mcr.microsoft.com/oss/v2/azure/ip-masq-agent-v2                                       v0.1.15-2                                         1d471a89c4ac4       28.4MB
# mcr.microsoft.com/oss/v2/azure/secrets-store/provider-azure                           v1.7.0                                            acadedeb3bc19       18.4MB
# mcr.microsoft.com/oss/v2/kubernetes-csi/secrets-store/driver                          v1.5.0                                            d4f9232485549       46.1MB
# mcr.microsoft.com/oss/v2/kubernetes/apiserver-network-proxy/agent                     v0.30.3                                           9a4f05bb422e1       13.8MB
# mcr.microsoft.com/oss/v2/kubernetes/autoscaler/addon-resizer                          v1.8.23-2                                         f0d91eb983b0c       22.5MB
# mcr.microsoft.com/oss/v2/kubernetes/autoscaler/cluster-proportional-autoscaler        v1.8.11-5                                         c9b34e1bd7ae7       19.7MB
# mcr.microsoft.com/oss/v2/kubernetes/autoscaler/cluster-proportional-autoscaler        v1.9.0-1                                          4c6cd5ed2a771       21.1MB
# mcr.microsoft.com/oss/v2/kubernetes/coredns                                           v1.11.3-7                                         682a7a064e2ed       29.2MB
# mcr.microsoft.com/oss/v2/kubernetes/coredns                                           v1.12.1-1                                         8f210c09c31ab       33.1MB
# mcr.microsoft.com/oss/v2/kubernetes/coredns                                           v1.9.4-5                                          e5b4768bab020       24.2MB
# mcr.microsoft.com/oss/v2/kubernetes/kube-state-metrics                                v2.15.0-4                                         1b26431092bb2       26.2MB
# mcr.microsoft.com/oss/v2/kubernetes/windows-gmsa-webhook                              v0.12.1-2                                         e71d8ee589c2d       21MB
# mcr.microsoft.com/oss/v2/open-policy-agent/gatekeeper                                 v3.18.2-1                                         b83322e6b5324       31.2MB
# mcr.microsoft.com/oss/v2/open-policy-agent/gatekeeper                                 v3.19.1-1                                         147e803e49e18       35.6MB
```
</details>

You can ee above that the Nginx image is present in the node. The image was pulled from the public Docker Hub registry and saved in the node's disk. Other images are also present, such as the Azure CNI (Container Network Interface) and the Azure Disk CSI (Container Storage Interface) drivers.

Lets now exit the node console using command `exit` and then `exit` again to leave the debug container.

```sh
exit
exit
```

## Creating a Deployment

A Deployment is a higher-level abstraction that manages a set of Pods and provides declarative updates to them. It allows you to define the desired state of your application and Kubernetes will ensure that the actual state matches the desired state.

You will create a Deployment that runs 3 replicas of the Nginx Pod. This means that Kubernetes will ensure that there are always 3 Pods running with the Nginx container.

```sh
kubectl create deployment nginx --image=nginx --replicas=3
# deployment.apps/nginx created
```

List the created deployments:

```sh
kubectl get deployments
# NAME    READY   UP-TO-DATE   AVAILABLE   AGE
# nginx   3/3     3            3           8s
```

View the Pods created by the Deployment:

```sh
kubectl get pods
# NAME                                                    READY   STATUS             RESTARTS   AGE
# nginx                                                   1/1     Running            0          49m
# nginx-5869d7778c-fpwx4                                  1/1     Running            0          30s
# nginx-5869d7778c-fwskg                                  1/1     Running            0          30s
# nginx-5869d7778c-tdn48                                  1/1     Running            0          30s
```

You can see that the Deployment created 3 Pods with the Nginx container. 
The Pods are running on different nodes in the cluster. You can view the nodes of the Pods using the command:

>Note also that each Pod has a unique name that is generated by Kubernetes. The name consists of the Deployment name, a random string, and the Pod index.

```sh
kubectl get pods -o wide
# NAME                                                    READY   STATUS             RESTARTS   AGE     IP             NODE                                NOMINATED NODE   READINESS GATES
# nginx                                                   1/1     Running            0          50m     10.244.2.135   aks-nodepool1-23059632-vmss000000   <none>           <none>
# nginx-5869d7778c-fpwx4                                  1/1     Running            0          112s    10.244.1.123   aks-nodepool1-23059632-vmss000001   <none>           <none>
# nginx-5869d7778c-fwskg                                  1/1     Running            0          112s    10.244.0.96    aks-nodepool1-23059632-vmss000002   <none>           <none>
# nginx-5869d7778c-tdn48                                  1/1     Running            0          112s    10.244.2.150   aks-nodepool1-23059632-vmss000000   <none>           <none>
```

>Note that the Pods are running on different nodes in the cluster. This is because Kubernetes tries to spread the Pods across the nodes to ensure high availability and fault tolerance.

>Note also that each Pod has a unique IP address that is assigned by the Azure CNI. The IP address is used to communicate with the Pod from other Pods or Services in the cluster. The CIDR ranges for the Pods and Services are defined in the AKS cluster configuration. You can view the CIDR ranges using the command:

```sh
az aks show -n aks-cluster -g rg-aks-cluster --query networkProfile.podCidr
# "10.244.0.0/16"
```

Can these pods communicate with each other? Yes, they can. Kubernetes provides a flat network model where all Pods can communicate with each other using their IP addresses. This is achieved by the Azure CNI plugin that creates a virtual network for the Pods and assigns them IP addresses from the specified CIDR range.
Lets test this by using the `kubectl exec` command to run a command inside one of the Pods and try to reach another Pod by its IP address.

```sh
kubectl exec -it nginx -- curl 10.244.2.135:80
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
# <style>
# html { color-scheme: light dark; }
# body { width: 35em; margin: 0 auto;
# font-family: Tahoma, Verdana, Arial, sans-serif; }
# </style>
# </head>
# <body>
# <h1>Welcome to nginx!</h1>
# <p>If you see this page, the nginx web server is successfully installed and
# working. Further configuration is required.</p>

# <p>For online documentation and support please refer to
# <a href="http://nginx.org/">nginx.org</a>.<br/>
# Commercial support is available at
# <a href="http://nginx.com/">nginx.com</a>.</p>

# <p><em>Thank you for using nginx.</em></p>
# </body>
# </html>
```

Containers are ephemeral by nature, meaning that they can be created and destroyed at any time. This is why Kubernetes provides a way to manage the desired state of your application using Deployments. If a Pod fails or is deleted, Kubernetes will automatically create a new Pod to replace it.
Lets validate that behaviour by deleting one of the Pods and checking that Kubernetes creates a new one to replace it.

```sh
kubectl delete pod nginx-5869d7778c-fpwx4
# pod "nginx-5869d7778c-fpwx4" deleted
```

You can see that Kubernetes created a new Pod to replace the deleted one:

```sh
kubectl get pods
# NAME                                                    READY   STATUS         RESTARTS   AGE     IP             NODE                                NOMINATED NODE   READINESS GATES
# nginx                                                   1/1     Running        0          61m     10.244.2.135   aks-nodepool1-23059632-vmss000000   <none>           <none>
# nginx-5869d7778c-fwskg                                  1/1     Running        0          12m     10.244.0.96    aks-nodepool1-23059632-vmss000002   <none>           <none>
# nginx-5869d7778c-rc9n7                                  1/1     Running        0          6s      10.244.1.185   aks-nodepool1-23059632-vmss000001   <none>           <none>
# nginx-5869d7778c-tdn48                                  1/1     Running        0          12m     10.244.2.150   aks-nodepool1-23059632-vmss000000   <none>           <none>
```

You can see that the new Pod has a different name and IP address, but it is running the same Nginx container image as the previous one. This is because Kubernetes ensures that the desired state of the Deployment is maintained.

Once the Pod is recreated, its IP address is not guaranteed to be the same as the previous one. This is because Kubernetes uses a dynamic IP address allocation mechanism for Pods. 

If you need a stable IP address for your application, you can use a Service to expose the Pods and provide a stable endpoint.

## Creating a Service

A Service is an abstraction that defines a logical set of Pods and a policy to access them. It provides a stable endpoint for accessing the Pods, regardless of their IP addresses or locations in the cluster.
You will create a Service that exposes the Nginx Pods on port 80 and maps it to port 80 of the Pods. This means that you can access the Nginx application using the Service IP address and port.

```sh
kubectl expose deployment nginx --type=LoadBalancer --port=80 --target-port=80
# service/nginx exposed
```

You can check the status of the Service and its IP address using the command:

```sh
kubectl get services
# NAME         TYPE           CLUSTER-IP   EXTERNAL-IP    PORT(S)        AGE
# kubernetes   ClusterIP      10.0.0.1     <none>         443/TCP        3d17h
# nginx        LoadBalancer   10.0.67.37   9.223.223.12   80:30261/TCP   27s
```

You can see that the Service has a `LoadBalancer` type, which means that it will create an external load balancer in Azure and assign it a public IP address. The `EXTERNAL-IP` field shows the public IP address of the load balancer.

You can view that public IP in the Azure portal on the node resource group.

You can now open your browser and navigate to the public IP address of the Service to see the Nginx welcome page.

Whenever you refresh the page, you will see that the Nginx Pods are serving the requests. This is because the Service load balances the traffic across the Pods that are part of the Deployment.

Lets use a different container image that will show the hostname of the Pod that is serving the request. This way you can see that the requests are being served by different Pods.

You will use the `ghcr.io/jelledruyts/inspectorgadget:latest` image.

Lets delete the existing Deployment and Service first:

```sh
kubectl delete service nginx
kubectl delete deployment nginx
# service "nginx" deleted
# deployment.apps "nginx" deleted
```

Now create a new Deployment with the new image and expose it as a Service:

```sh
kubectl create deployment inspectorgadget --image=ghcr.io/jelledruyts/inspectorgadget:latest --replicas=3
# deployment.apps/inspectorgadget created

kubectl get pods
# NAME                                                    READY   STATUS             RESTARTS   AGE
# inspectorgadget-795dfb7b56-5gbf4                        1/1     Running            0          15s
# inspectorgadget-795dfb7b56-m7lbk                        1/1     Running            0          15s
# inspectorgadget-795dfb7b56-vmsx2                        1/1     Running            0          15s

kubectl expose deployment inspectorgadget --type=LoadBalancer --port=80 --target-port=80
# service/inspectorgadget exposed

kubectl get services
# NAME              TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
# inspectorgadget   LoadBalancer   10.0.169.190   9.223.104.147   80:32519/TCP   17s
# kubernetes        ClusterIP      10.0.0.1       <none>          443/TCP        3d17h
```

You can now open your browser and navigate to the public IP address of the Service to see the Inspectorgadget application.
Refresh the page a few times and you will see that the hostname of the Pod that is serving the request changes. This is because the Service load balances the traffic across the Pods that are part of the Deployment.

> Note the services are using IP adresses from a CIDR range that is defined in the AKS cluster configuration. You can view the CIDR range for the Services using the command:

```sh
az aks show -n aks-cluster -g rg-aks-cluster --query networkProfile.serviceCidr
# "10.0.0.0/16"
```

How the traffic is routed from the public IP address to the Pods?

Here you will need to take a look at the Load Balancer configuration on the Azure portal. The Load Balancer is created in the node resource group and it has a public IP address assigned to it. The Load Balancer listens on port 80 and forwards the traffic to the nodes of the cluster. Then kubernetes uses `kube-proxy` and `iptables` to route the traffic to the appropriate Pod.


```sh
kubectl get pods -n kube-system -l component=kube-proxy
# NAME               READY   STATUS    RESTARTS   AGE
# kube-proxy-4qv64   1/1     Running   0          6m51s
# kube-proxy-5m8kj   1/1     Running   0          6m56s
# kube-proxy-8wrmr   1/1     Running   0          6m57s

kubectl exec -it -n kube-system kube-proxy-4qv64 -- iptables -L -n -v
# Defaulted container "kube-proxy" out of: kube-proxy, kube-proxy-bootstrap (init)
# Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
#  pkts bytes target     prot opt in     out     source               destination
#  467K   28M KUBE-PROXY-FIREWALL  0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW /* kubernetes load balancer firewall */
# 9670K 2522M KUBE-NODEPORTS  0    --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes health check service ports */
#  467K   28M KUBE-EXTERNAL-SERVICES  0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW /* kubernetes externally-visible service portals */
# 9676K 2686M KUBE-FIREWALL  0    --  *      *       0.0.0.0/0            0.0.0.0/0

# Chain FORWARD (policy ACCEPT 93239 packets, 5575K bytes)
#  pkts bytes target     prot opt in     out     source               destination
# 94827 5657K KUBE-PROXY-FIREWALL  0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW /* kubernetes load balancer firewall */
# 9148K 4924M KUBE-FORWARD  0    --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes forwarding rules */
# 93239 5575K KUBE-SERVICES  0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW /* kubernetes service portals */
# 93239 5575K KUBE-EXTERNAL-SERVICES  0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW /* kubernetes externally-visible service portals */
#     0     0 DROP       6    --  *      *       0.0.0.0/0            168.63.129.16        tcp dpt:32526
#     0     0 DROP       6    --  *      *       0.0.0.0/0            168.63.129.16        tcp dpt:80

# Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
#  pkts bytes target     prot opt in     out     source               destination
# 1179K   71M KUBE-PROXY-FIREWALL  0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW /* kubernetes load balancer firewall */
# 1179K   71M KUBE-SERVICES  0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW /* kubernetes service portals */
#   11M 3721M KUBE-FIREWALL  0    --  *      *       0.0.0.0/0            0.0.0.0/0

# Chain KUBE-EXTERNAL-SERVICES (2 references)
#  pkts bytes target     prot opt in     out     source               destination

# Chain KUBE-FIREWALL (2 references)
#  pkts bytes target     prot opt in     out     source               destination
#     0     0 DROP       0    --  *      *      !127.0.0.0/8          127.0.0.0/8          /* block incoming localnet connections */ ! ctstate RELATED,ESTABLISHED,DNAT

# Chain KUBE-FORWARD (1 references)
#  pkts bytes target     prot opt in     out     source               destination
#     0     0 DROP       0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate INVALID nfacct-name  ct_state_invalid_dropped_pkts
#   550 28592 ACCEPT     0    --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes forwarding rules */ mark match 0x4000/0x4000
# 57889   26M ACCEPT     0    --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes forwarding conntrack rule */ ctstate RELATED,ESTABLISHED

# Chain KUBE-KUBELET-CANARY (0 references)
#  pkts bytes target     prot opt in     out     source               destination

# Chain KUBE-NODEPORTS (1 references)
#  pkts bytes target     prot opt in     out     source               destination

# Chain KUBE-PROXY-CANARY (0 references)
#  pkts bytes target     prot opt in     out     source               destination

# Chain KUBE-PROXY-FIREWALL (3 references)
#  pkts bytes target     prot opt in     out     source               destination

# Chain KUBE-SERVICES (2 references)
#  pkts bytes target     prot opt in     out     source               destination
```

So now the app is exposed through a Load Balancer public IP address which is Layer 4 (TCP).

Can we expose the app through a Layer 7 (HTTP/S) load balancer?

## Creating an Ingress controller

Yes, you can expose the application through a Layer 7 (HTTP/S) load balancer using an Ingress controller. An Ingress controller is a Kubernetes resource that manages external access to the services in your cluster, typically HTTP.

To create an Ingress controller, you need to deploy an Ingress controller implementation, such as NGINX Ingress Controller, Traefik, or Azure Application Gateway Ingress Controller. These controllers listen for Ingress resource definitions and configure the underlying load balancer accordingly.

In this example, you will use the NGINX Ingress Controller, which is a popular choice for managing HTTP traffic in Kubernetes.

```sh
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# "ingress-nginx" has been added to your repositories

helm repo update
# Hang tight while we grab the latest from your chart repositories...
# ...Successfully got an update from the "ingress-nginx" chart repository
# Update Complete. ⎈Happy Helming!⎈

helm install ingress-nginx ingress-nginx/ingress-nginx `
     --create-namespace `
     --namespace ingress `
     --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz `
     --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-port"=80 
# NAME: ingress-nginx
# LAST DEPLOYED: Mon Jun 30 08:31:26 2025
# NAMESPACE: ingress
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# NOTES:
# The ingress-nginx controller has been installed.
# It may take a few minutes for the load balancer IP to be available.
# You can watch the status by running 'kubectl get service --namespace ingress ingress-nginx-controller --output wide --watch'

# An example Ingress that makes use of the controller:
#   apiVersion: networking.k8s.io/v1
#   kind: Ingress
#   metadata:
#     name: example
#     namespace: foo
#   spec:
#     ingressClassName: nginx
#     rules:
#       - host: www.example.com
#         http:
#           paths:
#             - pathType: Prefix
#               backend:
#                 service:
#                   name: exampleService
#                   port:
#                     number: 80
#               path: /
#     # This section is only required if TLS is to be enabled for the Ingress
#     tls:
#       - hosts:
#         - www.example.com
#         secretName: example-tls

# If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

#   apiVersion: v1
#   kind: Secret
#   metadata:
#     name: example-tls
#     namespace: foo
#   data:
#     tls.crt: <base64 encoded cert>
#     tls.key: <base64 encoded key>
#   type: kubernetes.io/tls

kubectl get pods,deployments,services --namespace ingress
# NAME                                            READY   STATUS    RESTARTS   AGE
# pod/ingress-nginx-controller-68547f7c99-j9p7m   1/1     Running   0          41s

# NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/ingress-nginx-controller   1/1     1            1           42s

# NAME                                         TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)                      AGE
# service/ingress-nginx-controller             LoadBalancer   10.0.26.221   135.116.48.130   80:30633/TCP,443:31022/TCP   42s
# service/ingress-nginx-controller-admission   ClusterIP      10.0.141.20   <none>           443/TCP                      42s

$INGRESS_PUBLIC_IP=$(kubectl get services ingress-nginx-controller -n ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $INGRESS_PUBLIC_IP
# 135.116.48.130
```

You can see that the Ingress controller has been deployed and is running. It has created a new public IP address attached to the Load Balancer so that you can use to access the Ingress controller.

Lets now create an Ingress resource that will route traffic to the Inspectorgadget application. The Ingress resource defines the rules for routing HTTP traffic to the backend services based on the request host and path.

Create a file named `ingress.yaml` with the following content:

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: inspectorgadget
  namespace: default
spec:
  ingressClassName: nginx
  rules:
#   - host: mycompany.com
  - http:
      paths:
      - backend:
          service:
            name: inspectorgadget
            port:
              number: 80
        path: /
        pathType: Prefix
#   tls:
#   - hosts:
#     - mycompany.com
#     secretName: secret-tls
```

Lets deploy the Ingress resource using the `kubectl apply` command:

```sh
kubectl apply -f ingress.yaml
# ingress.networking.k8s.io/inspectorgadget created
```

You can check the status of the Ingress resource using the command:

```sh
kubectl get ingress
# NAME              CLASS                                HOSTS   ADDRESS   PORTS   AGE
# inspectorgadget   webapprouting.kubernetes.azure.com   *                 80      12s
```

Navigate to the public IP address of the Ingress controller in your browser to see the Inspectorgadget application. You should see the same application as before, but now it is being served through the Ingress controller.

Note thet here the the inspectorgadget services is running under public IP address which is not recommended for production workloads. Ingress controller should be the only publicly exposed service. So you should disable public IP address for the inspectorgadget service and change it to ClusterIP type:

```sh
kubectl patch service inspectorgadget -n default -p '{\"spec\":{\"type\":\"ClusterIP\"}}'
# service/inspectorgadget patched

kubectl get svc
# NAME              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
# inspectorgadget   ClusterIP   10.0.169.190   <none>        80/TCP    35m
# kubernetes        ClusterIP   10.0.0.1       <none>        443/TCP   3d18h
```

>Note that you can configure a custom domain name for the Ingress resource by specifying the `host` field in the `rules` section. You can also enable TLS by specifying the `tls` section with a secret that contains the certificate and key.

We have seen the ingress traffic, what about egress traffic?

## Egress Traffic

Egress traffic refers to the outbound traffic from the Pods in your cluster to external services or the internet. By default, Kubernetes allows egress traffic from Pods to any destination.

Lets run a command inside one of the Pods to check the external IP address of the cluster. You can use the `ifconf.me` service to get the external IP address of the cluster.

```sh
kubectl exec -it nginx -- curl ifconf.me
# 9.223.252.156
```

The IP address returned is the external IP address of the cluster, which is the public IP address of the Load Balancer that is created by default when the cluster was created. This IP address is used only for egress traffic from the Pods to the internet.

>Note that you can control egress traffic using Network Policies or by configuring an `Azure Firewall` or `NAT Gateway`.

## Scaling the application

Kubernetes allows you to scale your applications up or down easily. You can scale your application by changing the number of replicas in the Deployment resource.

To scale the Inspectorgadget application to 5 replicas, you can run the following command:

```sh
kubectl scale deployment inspectorgadget --replicas=5
# deployment.apps/inspectorgadget scaled
```

You can verify the scaling operation by checking the status of the Pods:

```sh
kubectl get pods
# NAME                                READY   STATUS    RESTARTS   AGE
# inspectorgadget-5c6b7c8f5c-abcde   1/1     Running   0          1m
# inspectorgadget-5c6b7c8f5c-fghij   1/1     Running   0          1m
# inspectorgadget-5c6b7c8f5c-klmno   1/1     Running   0          1m
# inspectorgadget-5c6b7c8f5c-pqrst   1/1     Running   0          1m
# inspectorgadget-5c6b7c8f5c-uvwxy   1/1     Running   0          1m
```

Now lets scale the application to 100 replicas.

```sh
kubectl scale deployment inspectorgadget --replicas=100
# deployment.apps/inspectorgadget scaled
```

You can verify the scaling operation by checking the status of the Pods:

```sh
kubectl get deploy -w
```

Lets push forward and scale out to 1000 replicas:

```sh
kubectl scale deployment inspectorgadget --replicas=1000
# deployment.apps/inspectorgadget scaled

kubectl get deploy -w
```

Note that autoscaling will hit the limits allowed by `max pods per node`.

```sh
kubectl get nodes -o=jsonpath='{.items[*].status.allocatable.pods}'
# 110
```

This should trigger the cluster autoscaler to add more nodes to the cluster to accommodate the new Pods. The cluster autoscaler will monitor the resource usage and scale the cluster up or down based on the demand.

Check the number of nodes in the cluster:

```sh
kubectl get nodes
```

Note how new nodes are being created.

## Auto scaling the cluster

You can manually set up the number of nodes on the cluster or you can enable the cluster autoscaler to automatically scale the number of nodes in the cluster based on the resource usage.

Explore these features in the Azure portal or using the Azure CLI. You can set the minimum and maximum number of nodes in the node pool, and the cluster autoscaler will automatically add or remove nodes based on the resource usage of the Pods in the cluster.

## Getting container logs

You can view the logs of a container running in a Pod using the `kubectl logs` command. For example, to view the logs of the Nginx container in the `nginx` Pod, you can run the following command:

```sh
kubectl logs nginx
# /docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
# /docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
# /docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
# 10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
# 10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
# /docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
# /docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
# /docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
# /docker-entrypoint.sh: Configuration complete; ready for start up
# 2025/07/02 03:43:12 [notice] 1#1: using the "epoll" event method
# 2025/07/02 03:43:12 [notice] 1#1: nginx/1.29.0
# 2025/07/02 03:43:12 [notice] 1#1: built by gcc 12.2.0 (Debian 12.2.0-14+deb12u1)
# 2025/07/02 03:43:12 [notice] 1#1: OS: Linux 5.15.0-1090-azure
# 2025/07/02 03:43:12 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
# 2025/07/02 03:43:12 [notice] 1#1: start worker processes
# 2025/07/02 03:43:12 [notice] 1#1: start worker process 28
# 2025/07/02 03:43:12 [notice] 1#1: start worker process 29
```

These logs are saved in the node where the Pod is running under the folder `/var/log/containers/`.

```sh
kubectl debug node/aks-nodepool1-13675161-vmss000000 -it --image=mcr.microsoft.com/azurelinux/busybox:1.36

chroot /host

ls /var/log/containers/
# azure-cns-2tlsb_kube-system_cni-installer-59fbcf850052acdb8733fd4a6b731485e26d77cf03e9160adc86def15338c0a6.log
# azure-cns-2tlsb_kube-system_cns-container-6b7f572e3075d1388c935a8be8e00274085358205c2aa7b0367bef2ced48e60d.log
# azure-ip-masq-agent-w7z65_kube-system_azure-ip-masq-agent-f1974721c20fc61a62446d209ab25af3697e0733980a58dd6ade127df82f26f0.log
# cloud-node-manager-vqtnb_kube-system_cloud-node-manager-6c4a3e4bd716603ee8d7c8372c09b00eaea22aad0f5364c1363b1920bfa3cdf6.log
# csi-azuredisk-node-5559k_kube-system_azuredisk-c1f080d3da35cec8469ae42b94ce072ca3a1328d82e583599090a6e6035ff92f.log
# csi-azuredisk-node-5559k_kube-system_liveness-probe-82f3fbb41ce97f1e5ed8bf3cd9019de9b0aa18116059e8e0ff0869f99d96d7f5.log
# csi-azuredisk-node-5559k_kube-system_node-driver-registrar-c6fa93aa9b9187ee97b32d08beb54c856a6c85b0eaaab685f3df1a9d18da8455.log
# csi-azurefile-node-4hl6r_kube-system_azurefile-02dc16c7e3cca2e2c33b93413ad84334aeab48d46b5103657d21893a231bdf5c.log
# csi-azurefile-node-4hl6r_kube-system_liveness-probe-ced0a651259e788a7c9c94a76151758e13d0cfb1dccf442b05d8cb276ec9c3c8.log
# csi-azurefile-node-4hl6r_kube-system_node-driver-registrar-09d3832895f4ad86275194212acbcaf95015ff6b30d8e8a8c2def52d4763ff48.log
# kube-proxy-7m4fc_kube-system_kube-proxy-48501681f16035779d6d912bbd2c4f4b8d30823b10630a298edbde385e230a09.log
# kube-proxy-7m4fc_kube-system_kube-proxy-bootstrap-d07fbcb951bea9aa0650c0c57f47c73de5a2c4d5b28a2dab97e4865748372d3c.log
# nginx_default_nginx-fc19dd28749ecb46034d5ca8ff0d958716e524b580e06b4eee6e0b568ebf34b9.log
# node-debugger-aks-nodepool1-13675161-vmss000000-hhqs4_default_debugger-96375efb4e0d218ed1d77c10a8e47e0f648f59b9d13d18e85c56a922a1646293.log

cat /var/log/containers/nginx_default_nginx-fc19dd28749ecb46034d5ca8ff0d958716e524b580e06b4eee6e0b568ebf34b9.log
# 2025-07-02T03:43:12.760654049Z stdout F /docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
# 2025-07-02T03:43:12.760672176Z stdout F /docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
# 2025-07-02T03:43:12.76163443Z stdout F /docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
# 2025-07-02T03:43:12.765257335Z stdout F 10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
# 2025-07-02T03:43:12.770192253Z stdout F 10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
# 2025-07-02T03:43:12.770372706Z stdout F /docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
# 2025-07-02T03:43:12.770484855Z stdout F /docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
# 2025-07-02T03:43:12.772483015Z stdout F /docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
# 2025-07-02T03:43:12.773562456Z stdout F /docker-entrypoint.sh: Configuration complete; ready for start up
# 2025-07-02T03:43:12.777800831Z stderr F 2025/07/02 03:43:12 [notice] 1#1: using the "epoll" event method
# 2025-07-02T03:43:12.777811377Z stderr F 2025/07/02 03:43:12 [notice] 1#1: nginx/1.29.0
# 2025-07-02T03:43:12.777815673Z stderr F 2025/07/02 03:43:12 [notice] 1#1: built by gcc 12.2.0 (Debian 12.2.0-14+deb12u1)
# 2025-07-02T03:43:12.777819259Z stderr F 2025/07/02 03:43:12 [notice] 1#1: OS: Linux 5.15.0-1090-azure
# 2025-07-02T03:43:12.777822964Z stderr F 2025/07/02 03:43:12 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
# 2025-07-02T03:43:12.777848463Z stderr F 2025/07/02 03:43:12 [notice] 1#1: start worker processes
# 2025-07-02T03:43:12.777975144Z stderr F 2025/07/02 03:43:12 [notice] 1#1: start worker process 28
# 2025-07-02T03:43:12.778115607Z stderr F 2025/07/02 03:43:12 [notice] 1#1: start worker process 29
```

## Summary

In this lab, you learned how to create a Kubernetes cluster in Azure using AKS and deploy a simple web application using Nginx. You also learned how to expose the application using a Service and an Ingress controller.
