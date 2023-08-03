# create an AKS cluster with Kubernetes old version like 1.23.12

$AKS_NAME="aks-cluster"
$AKS_RG="rg-aks-cluster"

# get AKS versions

az aks get-versions -l westeurope -o table
# KubernetesVersion    Upgrades
# -------------------  -----------------------
# 1.26.0(preview)      None available
# 1.25.5               1.26.0(preview)
# 1.25.4               1.25.5, 1.26.0(preview)
# 1.24.9               1.25.4, 1.25.5
# 1.24.6               1.24.9, 1.25.4, 1.25.5
# 1.23.15              1.24.6, 1.24.9
# 1.23.12              1.23.15, 1.24.6, 1.24.9

az group create -n $AKS_RG -l westeurope

az aks create -g $AKS_RG `
              -n $AKS_NAME `
              --kubernetes-version "1.23.12" `
              --node-count 3

az aks nodepool show -g $AKS_RG `
                     --cluster-name $AKS_NAME `
                     --nodepool-name nodepool1 `
                     --query nodeImageVersion
# "AKSUbuntu-1804gen2containerd-202303.06.0"

az aks nodepool get-upgrades -g $AKS_RG `
                             --cluster-name $AKS_NAME `
                             --nodepool-name nodepool1
# {
#  "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourcegroups/rg-aks-cluster/providers/Microsoft.ContainerService/managedClusters/aks-1-23-12/agentPools/nodepool1/upgradeProfiles/default",
#  "kubernetesVersion": "1.23.12",
#  "latestNodeImageVersion": "AKSUbuntu-1804gen2containerd-202303.06.0",
#  "name": "default",
#  "osType": "Linux",
#  "resourceGroup": "rg-aks-cluster",
#  "type": "Microsoft.ContainerService/managedClusters/agentPools/upgradeProfiles",
#  "upgrades": null
# }

# start the upgrade for the node images

az aks nodepool upgrade -g $AKS_RG `
                        --cluster-name $AKS_NAME `
                        --nodepool-name nodepool1 `
                        --node-image-only

az aks nodepool show -g $AKS_RG `
                     --cluster-name $AKS_NAME `
                     --nodepool-name nodepool1 `
                     --query nodeImageVersion
# "AKSUbuntu-1804gen2containerd-202303.06.0"

az aks get-upgrades -g $AKS_RG -n $AKS_NAME -o table
# Name     ResourceGroup    MasterVersion    Upgrades
# -------  ---------------  ---------------  -----------------------
# default  rg-aks-cluster   1.23.12          1.23.15, 1.24.6, 1.24.9

az aks upgrade -g $AKS_RG -n $AKS_NAME --kubernetes-version "1.24.9"
# Kubernetes may be unavailable during cluster upgrades.
#  Are you sure you want to perform this operation? (y/N): y
# Since control-plane-only argument is not specified, this will upgrade the control plane AND all nodepools to version 1.24.9. Continue? (y/N): y

kubectl get nodes
# NAME                                STATUS   ROLES   AGE     VERSION
# aks-nodepool1-17418922-vmss000000   Ready    agent   44m     v1.23.12
# aks-nodepool1-17418922-vmss000001   Ready    agent   44m     v1.23.12
# aks-nodepool1-17418922-vmss000002   Ready    agent   44m     v1.23.12
# aks-nodepool1-17418922-vmss000003   Ready    agent   3m26s   v1.24.9

kubectl get nodes
# NAME                                STATUS   ROLES    AGE    VERSION
# aks-nodepool1-17418922-vmss000000   Ready    <none>   26s    v1.24.9
# aks-nodepool1-17418922-vmss000001   Ready    agent    47m    v1.23.12
# aks-nodepool1-17418922-vmss000002   Ready    agent    47m    v1.23.12
# aks-nodepool1-17418922-vmss000003   Ready    agent    6m9s   v1.24.9

kubectl get nodes
# NAME                                STATUS   ROLES   AGE    VERSION
# aks-nodepool1-17418922-vmss000000   Ready    agent   82s    v1.24.9
# aks-nodepool1-17418922-vmss000002   Ready    agent   48m    v1.23.12
# aks-nodepool1-17418922-vmss000003   Ready    agent   7m5s   v1.24.9

kubectl get nodes
# NAME                                STATUS   ROLES   AGE     VERSION
# aks-nodepool1-17418922-vmss000000   Ready    agent   3m29s   v1.24.9
# aks-nodepool1-17418922-vmss000001   Ready    agent   47s     v1.24.9
# aks-nodepool1-17418922-vmss000003   Ready    agent   9m12s   v1.24.9

kubectl get nodes
# NAME                                STATUS   ROLES   AGE     VERSION
# aks-nodepool1-17418922-vmss000000   Ready    agent   6m44s   v1.24.9
# aks-nodepool1-17418922-vmss000001   Ready    agent   4m2s    v1.24.9
# aks-nodepool1-17418922-vmss000002   Ready    agent   2m15s   v1.24.9
# aks-nodepool1-17418922-vmss000003   Ready    agent   12m     v1.24.9

kubectl get nodes
# NAME                                STATUS   ROLES   AGE     VERSION
# aks-nodepool1-17418922-vmss000000   Ready    agent   10m     v1.24.9
# aks-nodepool1-17418922-vmss000001   Ready    agent   7m33s   v1.24.9
# aks-nodepool1-17418922-vmss000002   Ready    agent   5m46s   v1.24.9

az aks nodepool show -g $AKS_RG `
                     --cluster-name $AKS_NAME `
                     --nodepool-name nodepool1 `
                     --query nodeImageVersion
# "AKSUbuntu-1804gen2containerd-202303.06.0"