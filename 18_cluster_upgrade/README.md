## Introduction
Kubernetes releases a new version each 4 months.
AKS maintains only 3 versions under Azure support.
So cluster administrators should upgrade their clusters regularly.
There are many options for upgrading the cluster:
1) Upgrade both the control plane and the nodepools at the same time
   Easy option but could be risky for production clusters if there is no rollback plan.
2) Upgrade the AKS control plane only then upgrade the nodepools:
   Still risky when upgrading the node pool.
3) Perform Blue/Green upgrade for the cluster: create new cluster with new version and route traffic to that cluster using Traffic Manager.
   Less risky as the blue cluster will serve as a backup and requires automation for recreating the cluster and deploying the applications.
4) Perform Blue/Green upgrade for the node pool: Upgrade the AKS control plane only then add a new node pool with the new version.
   This is the least risk option and easiest as it doesn't require cluster recreation.

In this tutorial, we will explore the Blue/Green upgrade for the node pool.
We will perform the following steps:
1) Upgrade the cluster control plane only to the new version
2) Add new node pool (green) with new version
3) Cordon and drain the old node pool (blue)
4) Check the application is up and running
5) Remove the old node pool (blue)

## 1. setup demo environment
```bash
# variables
$AKS_NAME="aks-dev-02"
$AKS_RG="rg-aks-dev-02"
```
```bash
az aks get-versions -l westeurope -o table
# KubernetesVersion    Upgrades
# -------------------  ------------------------
# 1.22.4               None available
# 1.22.2               1.22.4
# 1.21.7               1.22.2, 1.22.4
# 1.21.2               1.21.7, 1.22.2, 1.22.4
# 1.20.13              1.21.2, 1.21.7
# 1.20.9               1.20.13, 1.21.2, 1.21.7
# 1.19.13              1.20.9, 1.20.13
# 1.19.11              1.19.13, 1.20.9, 1.20.13
$VERSION_OLD="1.21.7"
$VERSION_NEW="1.22.4"
```

```bash
# create and connect to cluster
az group create --name $AKS_RG `
                --location westeurope
az aks create --name $AKS_NAME `
              --resource-group $AKS_RG `
              --node-count 2 `
              --kubernetes-version $VERSION_OLD `
              --generate-ssh-keys
          #     --enable-managed-identity
az aks get-credentials --name $AKS_NAME `
                       --resource-group $AKS_RG
# Merged "aks-dev-01" as current context in C:\Users\user1\.kube\config
kubectl get nodes
# NAME                                STATUS   ROLES   AGE   VERSION
# aks-nodepool1-34806685-vmss000000   Ready    agent   92s   v1.21.7
# aks-nodepool1-34806685-vmss000001   Ready    agent   82s   v1.21.7   
```

```bash
# (optional) add system nodepool with taints
az aks nodepool add --name systempool `
                    --cluster-name $AKS_NAME `
                    --resource-group $AKS_RG `
                    --node-count 2 `
                    --node-vm-size Standard_D2s_v5 `
                    --kubernetes-version $VERSION_OLD `
                    --max-pods 110 `
                    --priority Regular `
                    --zones 1, 2, 3 `
                    --node-taints CriticalAddonsOnly=true:NoSchedule `
                    --mode System
# (optional) remove old system nodepool
az aks nodepool delete --cluster-name $AKS_NAME `
                       --name nodepool1 `
                       --resource-group $AKS_RG `
                       --no-wait
# add user Nodepool blue
az aks nodepool add `
     --cluster-name $AKS_NAME `
     --resource-group $AKS_RG `
     --name bluepool `
     --node-count 3 `
     --node-vm-size Standard_D2s_v5 `
     --kubernetes-version $VERSION_OLD `
     --max-pods 110 `
     --priority Regular `
     --zones 1, 2, 3 `
     --mode User

az aks nodepool list --cluster-name $AKS_NAME --resource-group $AKS_RG -o table
# Name        OsType    VmSize           Count    MaxPods    ProvisioningState    Mode
# ----------  --------  ---------------  -------  ---------  -------------------  ------
# bluepool    Linux     Standard_D2s_v5  3        110        Succeeded            User
# systempool  Linux     Standard_D2s_v5  2        30         Succeeded            System
```

```bash
# deploy stateless application
kubectl create deployment nginx --image=nginx --replicas=10  -o yaml --dry-run=client
# apiVersion: apps/v1
# kind: Deployment
# metadata:
#   creationTimestamp: null
#   labels:
#     app: nginx
#   name: nginx
# spec:
#   replicas: 10
#   selector:
#     matchLabels:
#       app: nginx
#   strategy: {}
#   template:
#     metadata:
#       creationTimestamp: null
#       labels:
#         app: nginx
#     spec:
#       containers:
#       - image: nginx
#         name: nginx
#         resources: {}
# status: {}

kubectl create deployment nginx --image=nginx --replicas=10
# deployment.apps/nginx created

# view pods running in blue nodepool
kubectl get pods -o wide
# NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE                               NOMINATED NODE   READINESS GATES
# nginx-6799fc88d8-2rdpc   1/1     Running   0          29s   10.244.6.3   aks-bluepool-36768833-vmss000001   <none>           <none>
# nginx-6799fc88d8-4bqvv   1/1     Running   0          29s   10.244.4.2   aks-bluepool-36768833-vmss000002   <none>           <none>
# nginx-6799fc88d8-5p4j8   1/1     Running   0          29s   10.244.5.2   aks-bluepool-36768833-vmss000000   <none>           <none>
# nginx-6799fc88d8-6z8md   1/1     Running   0          29s   10.244.6.4   aks-bluepool-36768833-vmss000001   <none>           <none>
# nginx-6799fc88d8-78ndh   1/1     Running   0          29s   10.244.5.3   aks-bluepool-36768833-vmss000000   <none>           <none>
# nginx-6799fc88d8-bwl6x   1/1     Running   0          29s   10.244.5.4   aks-bluepool-36768833-vmss000000   <none>           <none>
# nginx-6799fc88d8-mdp28   1/1     Running   0          29s   10.244.5.5   aks-bluepool-36768833-vmss000000   <none>           <none>
# nginx-6799fc88d8-qnkt6   1/1     Running   0          29s   10.244.4.4   aks-bluepool-36768833-vmss000002   <none>           <none>
# nginx-6799fc88d8-tvg5q   1/1     Running   0          29s   10.244.6.2   aks-bluepool-36768833-vmss000001   <none>           <none>
# nginx-6799fc88d8-w24lx   1/1     Running   0          29s   10.244.4.3   aks-bluepool-36768833-vmss000002   <none>           <none>
```

## 2. start the cluster upgrade
```bash
az aks list -o table
# Name         Location    ResourceGroup    KubernetesVersion    ProvisioningState    Fqdn
# -----------  ----------  ---------------  -------------------  -------------------  -----------------------------------------------------------------
# aks-dev-01   westeurope  rg-aks-dev-01    1.21.7               Succeeded            aks-dev-01-rg-aks-dev-01-4b72ed-76eed78f.hcp.westeurope.azmk8s.io

# upgrade control plane only
echo $VERSION_NEW
# 1.22.4
az aks upgrade --kubernetes-version $VERSION_NEW `
               --control-plane-only `
               --name $AKS_NAME `
               --resource-group $AKS_RG
# Kubernetes may be unavailable during cluster upgrades.
# Are you sure you want to perform this operation? (y/N): y
# Since control-plane-only argument is specified, this will upgrade only the control plane to 1.22.4. Node pool will not change. Continue? (y/N): y
```

```bash
# add user Nodepool green
echo $VERSION_NEW
# 1.22.4
az aks nodepool add `
     --cluster-name $AKS_NAME `
     --resource-group $AKS_RG `
     --name greenpool `
     --node-count 3 `
     --node-vm-size Standard_D2s_v5 `
     --kubernetes-version $VERSION_NEW `
     --max-pods 110 `
     --priority Regular `
     --zones 1, 2, 3 `
     --mode User

az aks nodepool list --cluster-name $AKS_NAME --resource-group $AKS_RG -o table
# The behavior of this command has been altered by the following extension: aks-preview
# Name        OsType    VmSize           Count    MaxPods    ProvisioningState    Mode
# ----------  --------  ---------------  -------  ---------  -------------------  ------
# bluepool    Linux     Standard_D2s_v5  3        110        Updating             User
# greenpool   Linux     Standard_D2s_v5  3        110        Updating             User
# systempool  Linux     Standard_D2s_v5  2        30         Updating             System
```

```bash
# cordon nodepool blue
kubectl cordon -l agentpool=bluepool
# node/aks-bluepool-36768833-vmss000000 cordoned
# node/aks-bluepool-36768833-vmss000001 cordoned
# node/aks-bluepool-36768833-vmss000002 cordoned
```

```bash
# drain nodepool blue
kubectl drain -l agentpool=bluepool --ignore-daemonsets --delete-local-data
# Flag --delete-local-data has been deprecated, This option is deprecated and will be deleted. Use --delete-emptydir-data.
# node/aks-bluepool-36768833-vmss000000 already cordoned
# node/aks-bluepool-36768833-vmss000001 already cordoned
# node/aks-bluepool-36768833-vmss000002 already cordoned
# WARNING: ignoring DaemonSet-managed Pods: kube-system/azure-ip-masq-agent-4lgpn, kube-system/cloud-node-manager-trn4s, kube-system/csi-azuredisk-node-q9t4b, kube-system/csi-azurefile-node-k6ldn, kube-system/kube-proxy-8vf2w
# evicting pod default/nginx-6799fc88d8-mdp28
# evicting pod default/nginx-6799fc88d8-bwl6x
# evicting pod default/nginx-6799fc88d8-5p4j8
# evicting pod default/nginx-6799fc88d8-78ndh
# pod/nginx-6799fc88d8-bwl6x evicted
# pod/nginx-6799fc88d8-5p4j8 evicted
# pod/nginx-6799fc88d8-78ndh evicted
# pod/nginx-6799fc88d8-mdp28 evicted
# node/aks-bluepool-36768833-vmss000000 drained
# WARNING: ignoring DaemonSet-managed Pods: kube-system/azure-ip-masq-agent-rdmpr, kube-system/cloud-node-manager-9lgpd, kube-system/csi-azuredisk-node-nwcl8, kube-system/csi-azurefile-node-n7zlq, kube-system/kube-proxy-kff66
# evicting pod kube-system/konnectivity-agent-65cbb59d85-wpn65
# evicting pod default/nginx-6799fc88d8-6z8md
# evicting pod default/nginx-6799fc88d8-tvg5q
# evicting pod default/nginx-6799fc88d8-2rdpc
# pod/nginx-6799fc88d8-2rdpc evicted
# pod/konnectivity-agent-65cbb59d85-wpn65 evicted
# pod/nginx-6799fc88d8-6z8md evicted
# pod/nginx-6799fc88d8-tvg5q evicted
# node/aks-bluepool-36768833-vmss000001 drained
# WARNING: ignoring DaemonSet-managed Pods: kube-system/azure-ip-masq-agent-krrbl, kube-system/cloud-node-manager-drh4r, kube-system/csi-azuredisk-node-27phl, kube-system/csi-azurefile-node-2fjgm, kube-system/kube-proxy-27qbr
# evicting pod default/nginx-6799fc88d8-w24lx
# evicting pod default/nginx-6799fc88d8-4bqvv
# evicting pod default/nginx-6799fc88d8-qnkt6
# pod/nginx-6799fc88d8-qnkt6 evicted
# pod/nginx-6799fc88d8-w24lx evicted
# pod/nginx-6799fc88d8-4bqvv evicted
# node/aks-bluepool-36768833-vmss000002 drained
```

```bash
# check nginx pods are rescheduled to green nodepool
kubectl get pods -o wide
# NAME                     READY   STATUS    RESTARTS   AGE   IP            NODE                             
# nginx-6799fc88d8-8xxxw   1/1     Running   0          75s   10.244.0.3    aks-greenpool-45772455-vmss000001
# nginx-6799fc88d8-d55zk   1/1     Running   0          66s   10.244.0.7    aks-greenpool-45772455-vmss000001
# nginx-6799fc88d8-dt98n   1/1     Running   0          66s   10.244.0.8    aks-greenpool-45772455-vmss000001
# nginx-6799fc88d8-ffdxt   1/1     Running   0          75s   10.244.0.4    aks-greenpool-45772455-vmss000001
# nginx-6799fc88d8-nmzds   1/1     Running   0          75s   10.244.0.6    aks-greenpool-45772455-vmss000001
# nginx-6799fc88d8-phs95   1/1     Running   0          66s   10.244.0.9    aks-greenpool-45772455-vmss000001
# nginx-6799fc88d8-tb64z   1/1     Running   0          58s   10.244.0.12   aks-greenpool-45772455-vmss000001
# nginx-6799fc88d8-wz49h   1/1     Running   0          75s   10.244.0.5    aks-greenpool-45772455-vmss000001
# nginx-6799fc88d8-z84tg   1/1     Running   0          58s   10.244.0.10   aks-greenpool-45772455-vmss000001
# nginx-6799fc88d8-zl2pk   1/1     Running   0          58s   10.244.0.11   aks-greenpool-45772455-vmss000001
```

```bash
# delete nodepool blue
az aks nodepool delete --name bluepool `
                       --cluster-name $AKS_NAME `
                       --resource-group $AKS_RG `
                       -- no-wait
```