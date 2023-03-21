# Kubernetes Node Affinity and Pod Affinity

## Introduction

## 0. Setup demo environment

# Variables
$AKS_RG="rg-aks-cluster"
$AKS_NAME="aks-cluster"

# Create and connect to AKS cluster
az group create --name $AKS_RG --location westeurope

az aks create --name $AKS_NAME --resource-group $AKS_RG --node-count 3 --zones 1 2 3 --kubernetes-version "1.24.6" --network-plugin azure

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes

# Add 3 nodepools, each in an Availability Zone
az aks nodepool add `
       --resource-group $AKS_RG `
       --cluster-name $AKS_NAME `
       --name userpoolaz1 `
       --node-count 2 `
       --zones 1 `
       --mode User `
       --no-wait

az aks nodepool add `
       --resource-group $AKS_RG `
       --cluster-name $AKS_NAME `
       --name userpoolaz2 `
       --node-count 2 `
       --zones 2 `
       --mode User `
       --no-wait

az aks nodepool add `
       --resource-group $AKS_RG `
       --cluster-name $AKS_NAME `
       --name userpoolaz3 `
       --node-count 2 `
       --zones 3 `
       --mode User `
       --no-wait

# Add new System nodepool using 3 availability zones and with taint
az aks nodepool add `
       --resource-group $AKS_RG `
       --cluster-name $AKS_NAME `
       --name systempool `
       --node-count 3 `
       --zones 1, 2, 3 `
       --mode System `
       --node-taints CriticalAddonsOnly=true:NoSchedule `
       --no-wait

# Delete old default system nodepool
az aks nodepool delete `
       --resource-group $AKS_RG `
       --cluster-name $AKS_NAME `
       --name nodepool1 `
       --no-wait

kubectl get nodes
# NAME                                  STATUS   ROLES   AGE    VERSION
# aks-systempool-24368087-vmss000000    Ready    agent   93m    v1.25.2
# aks-systempool-24368087-vmss000001    Ready    agent   93m    v1.25.2
# aks-systempool-24368087-vmss000002    Ready    agent   93m    v1.25.2
# aks-userpoolaz1-15251645-vmss000000   Ready    agent   93s    v1.25.2
# aks-userpoolaz1-15251645-vmss000001   Ready    agent   92s    v1.25.2
# aks-userpoolaz2-24227208-vmss000000   Ready    agent   83s    v1.25.2
# aks-userpoolaz2-24227208-vmss000001   Ready    agent   113s   v1.25.2
# aks-userpoolaz3-25604691-vmss000000   Ready    agent   23s    v1.25.2
# aks-userpoolaz3-25604691-vmss000001   Ready    agent   46s    v1.25.2

Set-Alias -Name grep -Value select-string # if using powershell
kubectl describe nodes | grep topology.kubernetes.io/zone
# topology.kubernetes.io/zone=westeurope-1
# topology.kubernetes.io/zone=westeurope-2
# topology.kubernetes.io/zone=westeurope-3
# topology.kubernetes.io/zone=westeurope-1
# topology.kubernetes.io/zone=westeurope-1
# topology.kubernetes.io/zone=westeurope-2
# topology.kubernetes.io/zone=westeurope-2
# topology.kubernetes.io/zone=westeurope-3

kubectl get nodes -o='custom-columns=NodeName:.metadata.name,AvailabilityZone:.metadata.labels.\topology\.kubernetes\.io\/zone,AgentPool:.metadata.labels.agentpool,Mode:.metadata.labels.\kubernetes\.azure\.com\/mode'
# NodeName                              AvailabilityZone   AgentPool     Mode
# aks-systempool-24368087-vmss000000    westeurope-1       systempool    system
# aks-systempool-24368087-vmss000001    westeurope-2       systempool    system
# aks-systempool-24368087-vmss000002    westeurope-3       systempool    system
# aks-userpoolaz1-15251645-vmss000000   westeurope-1       userpoolaz1   user
# aks-userpoolaz1-15251645-vmss000001   westeurope-1       userpoolaz1   user
# aks-userpoolaz2-24227208-vmss000000   westeurope-2       userpoolaz2   user
# aks-userpoolaz2-24227208-vmss000001   westeurope-2       userpoolaz2   user
# aks-userpoolaz3-25604691-vmss000000   westeurope-3       userpoolaz3   user
# aks-userpoolaz3-25604691-vmss000001   westeurope-3       userpoolaz3   user

## Scenario 1: deploy apps without Pod/Node affinity

kubectl create deployment nginx --image=nginx --replicas=3
# deployment.apps/nginx created

kubectl get pods -o wide
# NAME                    READY   STATUS    RESTARTS   AGE   IP             NODE                               
# nginx-76d6c9b8c-6qxp7   1/1     Running   0          15s   10.224.0.5     aks-userpoolaz1-15251645-vmss000000
# nginx-76d6c9b8c-flv56   1/1     Running   0          15s   10.224.0.63    aks-userpoolaz2-24227208-vmss000000
# nginx-76d6c9b8c-lqdhl   1/1     Running   0          15s   10.224.0.158   aks-userpoolaz3-25604691-vmss000001


# Note how the 3 pods are deployed into the 3 availability zones.
# Kubernetes will always try to spread pods across many different nodes and availability zones.

kubectl scale deployment nginx --replicas=6
# deployment.apps/nginx scaled

kubectl get pods -o wide
# NAME                    READY   STATUS    RESTARTS   AGE   IP             NODE                               
# nginx-76d6c9b8c-6qxp7   1/1     Running   0          61s   10.224.0.5     aks-userpoolaz1-15251645-vmss000000
# nginx-76d6c9b8c-flv56   1/1     Running   0          61s   10.224.0.63    aks-userpoolaz2-24227208-vmss000000
# nginx-76d6c9b8c-lqdhl   1/1     Running   0          61s   10.224.0.158   aks-userpoolaz3-25604691-vmss000001
# nginx-76d6c9b8c-qm6lv   1/1     Running   0          15s   10.224.0.124   aks-userpoolaz3-25604691-vmss000000
# nginx-76d6c9b8c-rbh2k   1/1     Running   0          15s   10.224.0.97    aks-userpoolaz2-24227208-vmss000001
# nginx-76d6c9b8c-wqb5x   1/1     Running   0          15s   10.224.0.35    aks-userpoolaz1-15251645-vmss000001

# Note how each pod is deployed in a different node.

# Scenario 2: Simulate availability zone failure

# Drain all nodes in a given availability zone

kubectl drain -l topology.kubernetes.io/zone=westeurope-3 --force --delete-emptydir-data --ignore-daemonsets
# node/aks-systempool-24368087-vmss000002 cordoned
# node/aks-userpoolaz3-25604691-vmss000000 cordoned
# node/aks-userpoolaz3-25604691-vmss000001 cordoned
# Warning: ignoring DaemonSet-managed Pods: kube-system/azure-ip-masq-agent-df7vw, kube-system/cloud-node-manager-tbrdb, kube-system/csi-azuredisk-node-r52vn, kube-system/csi-azurefile-node-tw446, kube-system/kube-proxy-9pfh9
# evicting pod kube-system/metrics-server-dd54b56c-tm429
# evicting pod kube-system/coredns-77f75ff65d-snblz
# evicting pod kube-system/konnectivity-agent-7795b4fbb4-4tcmz
# pod/konnectivity-agent-7795b4fbb4-4tcmz evicted
# pod/coredns-77f75ff65d-snblz evicted
# pod/metrics-server-dd54b56c-tm429 evicted
# node/aks-systempool-24368087-vmss000002 drained
# Warning: ignoring DaemonSet-managed Pods: kube-system/azure-ip-masq-agent-kqzzq, kube-system/cloud-node-manager-kqnrk, kube-system/csi-azuredisk-node-mvd7t, kube-system/csi-azurefile-node-b7vtf, kube-system/kube-proxy-964r6
# evicting pod default/nginx-76d6c9b8c-qm6lv
# pod/nginx-76d6c9b8c-qm6lv evicted
# node/aks-userpoolaz3-25604691-vmss000000 drained
# Warning: ignoring DaemonSet-managed Pods: kube-system/azure-ip-masq-agent-whh5w, kube-system/cloud-node-manager-rvc99, kube-system/csi-azuredisk-node-6gvd6, kube-system/csi-azurefile-node-4zhdw, kube-system/kube-proxy-5szc5
# evicting pod default/nginx-76d6c9b8c-lqdhl
# pod/nginx-76d6c9b8c-lqdhl evicted
# node/aks-userpoolaz3-25604691-vmss000001 drained

kubectl get pods -o wide
# NAME                    READY   STATUS    RESTARTS   AGE     IP            NODE                               
# nginx-76d6c9b8c-6qxp7   1/1     Running   0          2m59s   10.224.0.5    aks-userpoolaz1-15251645-vmss000000
# nginx-76d6c9b8c-flv56   1/1     Running   0          2m59s   10.224.0.63   aks-us to the newer machineserpoolaz2-24227208-vmss000000
# nginx-76d6c9b8c-lqjmg   1/1     Running   0          41s     10.224.0.53   aks-userpoolaz1-15251645-vmss000001
# nginx-76d6c9b8c-rbh2k   1/1     Running   0          2m13s   10.224.0.97   aks-userpoolaz2-24227208-vmss000001
# nginx-76d6c9b8c-tbzq5   1/1     Running   0          44s     10.224.0.74   aks-userpoolaz2-24227208-vmss000000
# nginx-76d6c9b8c-wqb5x   1/1     Running   0          2m13s   10.224.0.35   aks-userpoolaz1-15251645-vmss000001

# Note how pods got rescheduled 'evenly' into other availability zones; zone 1 and 2.

# Let us 'restore' the availability zone

kubectl uncordon -l topology.kubernetes.io/zone=westeurope-3
# node/aks-systempool-24368087-vmss000002 uncordoned
# node/aks-userpoolaz3-25604691-vmss000000 uncordoned
# node/aks-userpoolaz3-25604691-vmss000001 uncordoned

kubectl get nodes -o='custom-columns=NodeName:.metadata.name,AvailabilityZone:.metadata.labels.\topology\.kubernetes\.io\/zone,AgentPool:.metadata.labels.agentpool,Mode:.metadata.labels.\kubernetes\.azure\.com\/mode'
# NodeName                              AvailabilityZone   AgentPool     Mode
# aks-systempool-24368087-vmss000000    westeurope-1       systempool    system
# aks-systempool-24368087-vmss000001    westeurope-2       systempool    system
# aks-systempool-24368087-vmss000002    westeurope-3       systempool    system
# aks-userpoolaz1-15251645-vmss000000   westeurope-1       userpoolaz1   user
# aks-userpoolaz1-15251645-vmss000001   westeurope-1       userpoolaz1   user
# aks-userpoolaz2-24227208-vmss000000   westeurope-2       userpoolaz2   user
# aks-userpoolaz2-24227208-vmss000001   westeurope-2       userpoolaz2   user
# aks-userpoolaz3-25604691-vmss000000   westeurope-3       userpoolaz3   user
# aks-userpoolaz3-25604691-vmss000001   westeurope-3       userpoolaz3   user

kubectl get pods -o wide
# NAME                    READY   STATUS    RESTARTS   AGE   IP            NODE                               
# nginx-76d6c9b8c-6qxp7   1/1     Running   0          47m   10.224.0.5    aks-userpoolaz1-15251645-vmss000000
# nginx-76d6c9b8c-flv56   1/1     Running   0          47m   10.224.0.63   aks-userpoolaz2-24227208-vmss000000
# nginx-76d6c9b8c-lqjmg   1/1     Running   0          45m   10.224.0.53   aks-userpoolaz1-15251645-vmss000001
# nginx-76d6c9b8c-rbh2k   1/1     Running   0          46m   10.224.0.97   aks-userpoolaz2-24227208-vmss000001
# nginx-76d6c9b8c-tbzq5   1/1     Running   0          45m   10.224.0.74   aks-userpoolaz2-24227208-vmss000000
# nginx-76d6c9b8c-wqb5x   1/1     Running   0          46m   10.224.0.35   aks-userpoolaz1-15251645-vmss000001

# Note how the pods are still running in the same nodes and are not rescheduled to the newer nodes. That is expected in kubernetes.

## Scenario 3: Statefulset and Azure Disk (LRS, ZRS)

# frontend connects to backend, both deployed in the same AZ.

# affinity: 
# nodeAffinity:
#   requiredDuringSchedulingIgnoredDuringExecution:
#     nodeSelectorTerms:
#     - matchExpressions:
#       - key: topology.kubernetes.io/zone
#         operator: In
#         values:
#         - westus2-1
#         - westus2-2
#         - westus2-3
#   requiredDuringSchedulingIgnoredDuringExecution:
#     nodeSelectorTerms:
#     - matchExpressions:
#       - key: agentpool
#         operator: In
#         values:
#         - espoolz1
#         - espoolz2
#         - espoolz3