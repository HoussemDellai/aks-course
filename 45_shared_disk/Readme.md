
# Using Azure Shared Disk in AKS

## Introduction

Azure Shared Disk could be mounted to more than one node simultaneously.  
Use ReadWriteMany (RWX) accessMode and Raw Block Device with Block volumeMode.  
One single node can write at a time.  
Container will see a device instead of a file system.  
Can be used with applications that can manage writes, reads, locks, caches, fencing on raw block volumes.  
Can be used with PPG for lowest latency.  
Supports Ultra Disk, Premium SSD & Standard SSD.  
Supports LRS and ZRS disks.  

<img src="images/architecture-manual.png">

## Setup demo environment

```powershell
# Variables
$AKS_RG="rg-aks-shared-disk"
$AKS_NAME="aks-cluster"

# Create and connect to AKS cluster
az group create --name $AKS_RG --location westeurope

az aks create --name $AKS_NAME --resource-group $AKS_RG --node-count 6 --zones 1 2 3 --kubernetes-version "1.25.2" --network-plugin azure

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes
# NAME                                STATUS   ROLES   AGE   VERSION
# aks-nodepool1-39303592-vmss000000   Ready    agent   67m   v1.25.2
# aks-nodepool1-39303592-vmss000001   Ready    agent   66m   v1.25.2
# aks-nodepool1-39303592-vmss000002   Ready    agent   67m   v1.25.2
# aks-nodepool1-39303592-vmss000003   Ready    agent   54m   v1.25.2
# aks-nodepool1-39303592-vmss000004   Ready    agent   54m   v1.25.2
# aks-nodepool1-39303592-vmss000005   Ready    agent   54m   v1.25.2
```

## Deploy a sample deployment with StorageClass and PVC (ZRS Shared Azure Disk)

```powershell
kubectl apply -f zrs-shared-disk-pvc-sc.yaml,zrs-shared-disk-deploy.yaml
# storageclass.storage.k8s.io/zrs-shared-managed-csi created
# persistentvolumeclaim/zrs-shared-pvc-azuredisk created
# deployment.apps/deployment-azuredisk created
```

Verify resources deployed successfully

```powershell
kubectl get pods,pv,pvc,sc
# NAME                        READY   STATUS    RESTARTS   AGE
# pod/nginx-79f645c46-6vzq4   1/1     Running   0          5m19s
# pod/nginx-79f645c46-jpjtl   1/1     Running   0          5m19s
# pod/nginx-79f645c46-l5slj   1/1     Running   0          5m19s

# NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM
#   STORAGECLASS             REASON   AGE
# persistentvolume/pvc-b1d0fc7c-6c48-4020-b830-5c9a33c116c1   256Gi      RWX            Delete           Bound    default/zrs-shared-pvc-azuredisk   zrs-shared-managed-csi            5m17s

# NAME                                             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS             AGE
# persistentvolumeclaim/zrs-shared-pvc-azuredisk   Bound    pvc-b1d0fc7c-6c48-4020-b830-5c9a33c116c1   256Gi      RWX            zrs-shared-managed-csi   5m19s
```

Verify the pods are deployed in multiple nodes

```powershell
kubectl get pods -o wide
# NAME                    READY   STATUS    RESTARTS   AGE     IP             NODE                             
# nginx-79f645c46-6vzq4   1/1     Running   0          6m24s   10.224.0.123   aks-nodepool1-39303592-vmss000000
# nginx-79f645c46-jpjtl   1/1     Running   0          6m24s   10.224.0.61    aks-nodepool1-39303592-vmss000004
# nginx-79f645c46-l5slj   1/1     Running   0          6m24s   10.224.0.126   aks-nodepool1-39303592-vmss000005
```

Verify the pods are deployed in multiple availability zones

```powershell
Set-Alias -Name grep -Value select-string # if using powershell
kubectl describe nodes | grep topology.kubernetes.io/zone
# topology.kubernetes.io/zone=westeurope-1
# topology.kubernetes.io/zone=westeurope-2
# topology.kubernetes.io/zone=westeurope-3
# topology.kubernetes.io/zone=westeurope-1
# topology.kubernetes.io/zone=westeurope-2
# topology.kubernetes.io/zone=westeurope-3

$NODE_RG=$(az aks show -g $AKS_RG -n $AKS_NAME --query nodeResourceGroup -o tsv)
echo $NODE_RG
# MC_rg-aks-shared-disk_aks-cluster_westeurope

az disk list -g $NODE_RG -o table
# Name                                      ResourceGroup                                 Location    Zones    Sku          SizeGb    ProvisioningState
# ----------------------------------------  --------------------------------------------  ----------  -------  -----------  --------  -------------------
# pvc-8ed6c59d-4de5-44ba-9f25-00e58992daea  MC_rg-aks-shared-disk_aks-cluster_westeurope  westeurope           Premium_ZRS  256       Succeeded
```

Check the Disk config on the Azure portal

<img src="images/shared-disk.png">

Verify the Disk is accessible by 3 nodes

```powershell
az disk list -g $NODE_RG --query [0].managedByExtended
# [
#   "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/mc_rg-aks-shared-disk_aks-cluster_westeurope/providers/Microsoft.Compute/virtualMachineScaleSets/aks-nodepool1-39303592-vmss/virtualMachines/aks-nodepool1-39303592-vmss_5",
#   "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/mc_rg-aks-shared-disk_aks-cluster_westeurope/providers/Microsoft.Compute/virtualMachineScaleSets/aks-nodepool1-39303592-vmss/virtualMachines/aks-nodepool1-39303592-vmss_4",
#   "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/mc_rg-aks-shared-disk_aks-cluster_westeurope/providers/Microsoft.Compute/virtualMachineScaleSets/aks-nodepool1-39303592-vmss/virtualMachines/aks-nodepool1-39303592-vmss_0"
# ]
```

Verify access to Shared Disk on Pod #1

```powershell
$POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')
echo $POD_NAME
# nginx-79f645c46-b4vd6

kubectl exec -it $POD_NAME -- dd if=/dev/zero of=/dev/sdx bs=1024k count=100
# 100+0 records in
# 100+0 records out
# 104857600 bytes (105 MB, 100 MiB) copied, 0.047578 s, 2.2 GB/s
```

Verify access to Shared Disk on Pod #2

```powershell
$POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[1].metadata.name}')
echo $POD_NAME
# nginx-79f645c46-jp9r8

kubectl exec -it $POD_NAME -- dd if=/dev/zero of=/dev/sdx bs=1024k count=100
# 100+0 records in
# 100+0 records out
# 104857600 bytes (105 MB, 100 MiB) copied, 0.0502999 s, 2.1 GB/s
```

## Resources
https://github.com/kubernetes-sigs/azuredisk-csi-driver/blob/master/deploy/example/failover/README.md