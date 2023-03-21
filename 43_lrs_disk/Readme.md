# Using Azure Disk in AKS

## Introduction

In this lab, we'll mount an LRS Azure Disk with a deployment. Then we will simulate a zone or node failure. We will see how the LRS Disk will stik into its availability zone.

## Plan
0. Setup demo environment
1. Deploy a sample deployment with PVC (Azure Disk with LRS)
2. Simulate node failure (delete node)
3. Resolving the issue (adding nodes in the same AZ)

## 0. Setup demo environment

```powershell
# Variables
$AKS_RG="rg-aks-az"
$AKS_NAME="aks-cluster"

# Create and connect to AKS cluster
az group create --name $AKS_RG --location westeurope

az aks create -n $AKS_NAME -g $AKS_RG --node-count 3 --zones 1 2 3 

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes
```

## 1. Deploy a sample deployment with PVC (Azure Disk with LRS)

```powershell
kubectl apply -f lrs-disk-deploy.yaml
# persistentvolumeclaim/azure-managed-disk-lrs created
# deployment.apps/nginx-lrs created
```

Verify resources deployed successfully

```powershell
kubectl get pods,pv,pvc
# NAME                             READY   STATUS    RESTARTS   AGE
# pod/nginx-lrs-5fc6787dff-2f8zj   1/1     Running   0          70s
# NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                            STORAGECLASS
# persistentvolume/pvc-7734f114-cdef-4cf9-ae60-9cd840f641a6   5Gi        RWO            Delete           Bound    default/azure-managed-disk-lrs   managed-csi 

# NAME                                           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# persistentvolumeclaim/azure-managed-disk-lrs   Bound    pvc-7734f114-cdef-4cf9-ae60-9cd840f641a6   5Gi        RWO            managed-csi    70s
```

Check the worker node for the pod

```powershell
kubectl get pods -o wide
# NAME                         READY   STATUS    RESTARTS   AGE   IP            NODE
# nginx-lrs-5fc6787dff-2f8zj   1/1     Running   0          27s   10.244.2.12   aks-nodepool1-49785470-vmss000001

kubectl get nodes
# NAME                                STATUS   ROLES   AGE     VERSION
# aks-nodepool1-49785470-vmss000000   Ready    agent   3h32m   v1.23.12
# aks-nodepool1-49785470-vmss000001   Ready    agent   3h32m   v1.23.12
# aks-nodepool1-49785470-vmss000002   Ready    agent   3h32m   v1.23.12
```

Worker Nodes are deployed into the 3 Azure Availability Zones

```powershell
Set-Alias -Name grep -Value select-string # if using powershell

kubectl describe nodes | grep topology.kubernetes.io/zone
# topology.kubernetes.io/zone=westeurope-1
# topology.kubernetes.io/zone=westeurope-2
# topology.kubernetes.io/zone=westeurope-3
```

Check the Availability Zone for our pod

```powershell
# Get Pod's node name
$NODE_NAME=$(kubectl get pods -l app=nginx-lrs -o jsonpath='{.items[0].spec.nodeName}')
echo $NODE_NAME
# aks-nodepool1-49785470-vmss000001

kubectl get nodes $NODE_NAME -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'
# westeurope-2

kubectl describe nodes $NODE_NAME | grep topology.kubernetes.io/zone
# topology.kubernetes.io/zone=westeurope-2
```

## 2. Simulate node failure (delete node)

```powershell
kubectl delete node $NODE_NAME
# node "aks-nodepool1-49785470-vmss000001" deleted
```

Check the pod, we have a problem!

```powershell
kubectl get pods -o wide
# NAME                         READY   STATUS    RESTARTS   AGE    IP       NODE
# nginx-lrs-5fc6787dff-wk99x   0/1     Pending   0          107s   <none>   <none>
```

Check Pod events

```powershell
kubectl describe pod | grep Warning
# Warning  FailedScheduling  20s (x6 over 5m47s)  default-scheduler  0/3 nodes are available: 1 node(s) were unschedulable, 2 node(s) had volume node affinity conflict.
```

The problem here is that the PV (Azure Disk) is zonal (uses 1 single availability zone (AZ)). 
It could be detached from the VM and mounted into another VM. But that VM must be within the same AZ.
If it is not within then same AZ, it will fail. And the pod will not be able to mount the disk.

## 3. Resolving the issue (adding nodes in the same AZ)

What if we did have another VM inside the same Availability Zone ?

Adding nodes to the availability zones

```powershell
az aks scale -n $AKS_NAME -g $AKS_RG --node-count 6
```

Check the created Nodes (note the missing node we deleted earlier!)

```powershell
kubectl get nodes
# NAME                                STATUS   ROLES   AGE    VERSION
# aks-nodepool1-49785470-vmss000000   Ready    agent   5h3m   v1.23.12
# aks-nodepool1-49785470-vmss000002   Ready    agent   5h3m   v1.23.12
# aks-nodepool1-49785470-vmss000003   Ready    agent   100s   v1.23.12
# aks-nodepool1-49785470-vmss000004   Ready    agent   100s   v1.23.12
# aks-nodepool1-49785470-vmss000005   Ready    agent   102s   v1.23.12
```

Verify we have nodes in all 3 availability zones (including AZ-2 where we have the Disk/PV)

```powershell
kubectl describe nodes | grep topology.kubernetes.io/zone
# topology.kubernetes.io/zone=westeurope-1
# topology.kubernetes.io/zone=westeurope-3
# topology.kubernetes.io/zone=westeurope-1
# topology.kubernetes.io/zone=westeurope-2
# topology.kubernetes.io/zone=westeurope-3
```

Check pod is now rescheduled into a node within AZ-2

```powershell
kubectl get pods -o wide
# NAME                         READY   STATUS    RESTARTS   AGE   IP           NODE
# nginx-lrs-5fc6787dff-wk99x   1/1     Running   0          29m   10.244.5.2   aks-nodepool1-49785470-vmss000004
```

Verify the node is in availability zone 2

```powershell
$NODE_NAME=$(kubectl get pods -l app=nginx-lrs -o jsonpath='{.items[0].spec.nodeName}')
$NODE_NAME
# aks-nodepool1-49785470-vmss000004

kubectl get nodes $NODE_NAME -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'
# westeurope-2
```

## Conclusion

An Azure Disk of type LRS (`Local Redundant Storage`) is 'zonal resource'.
This means it is available only within the same availability where it is created.
LRS Disk cannot be moved to another AZ.
This is not suitable for pods using multiple AZ.
 The solution would be :
+ Choose another storage option that supports multiple AZ like Azure Files or Storage Blob.
+ Use Azure Disk with ZRS (`Zone Redundant Storage`), instead of LRS.
We'll explore this last option in the next lab.