# Azure Custom RBAC Role

## 0. Setup demo environment

# Variables
$AKS_RG="rg-aks-cluster"
$AKS_NAME="aks-cluster"

# Create and connect to AKS cluster
az group create --name $AKS_RG --location westeurope

az aks create -n $AKS_NAME -g $AKS_RG --enable-aad --enable-azure-rbac

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

# Connect to cluster
kubelogin convert-kubeconfig -l azurecli

kubectl get nodes
# Error from server (Forbidden): nodes is forbidden: 
# User "99b281c9-823c-4633-xxxxxx" cannot list resource "nodes" in API group "" 
# at the cluster scope: User does not have access to the resource in Azure.
# Update role assignment to allow access.

$AKS_ID=$(az aks show -n $AKS_NAME -g $AKS_RG --query id -o tsv)

$USER_ID=$(az ad signed-in-user show --query id -o tsv)

az role assignment create --role "Azure Kubernetes Service RBAC Writer" --assignee $USER_ID --scope $AKS_ID/namespaces/default

kubectl get nodes

kubectl get pods
# No resources found in default namespace.

kubectl get pods -n kube-system
# Error from server (Forbidden): pods is forbidden: 
# User "99b281c9-823c-4633-af92-8ac556a19bee" cannot list resource "pods" in API group "" 
# in the namespace "kube-system": User does not have access to the resource in Azure. 
# Update role assignment to allow access.

kubectl get deploy -n kube-system
# no access to deployments

# create Azure RBAC custom role for AKS
# Here is an example:
# {
#     "Name": "AKS Deployment Reader",
#     "Description": "Lets you view all deployments in cluster/namespace.",
#     "Actions": [],
#     "NotActions": [],
#     "DataActions": [
#         "Microsoft.ContainerService/managedClusters/apps/deployments/read"
#     ],
#     "NotDataActions": [],
#     "assignableScopes": [
#         "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910"
#     ]
# }

az role definition create --role-definition deployment-reader.json

az role definition list --name "AKS Deployment Reader"

$SUBSCRIPTION_ID=$(az account show --query id -o tsv)
$SUBSCRIPTION_ID

az role assignment create --role "AKS Deployment Reader" --assignee $USER_ID --scope $AKS_ID/namespaces/kube-system

# wait for about 5 minutes for role propagation

kubectl get deploy -n kube-system
# NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
# coredns              2/2     2            2           43m
# coredns-autoscaler   1/1     1            1           43m
# konnectivity-agent   2/2     2            2           43m
# metrics-server       2/2     2            2           43m

## cleanup resources

az group delete -n $AKS_RG --yes --no-wait

az role definition delete -n "AKS Deployment Reader"