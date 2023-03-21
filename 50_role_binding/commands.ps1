# Kubernetes Role and RoleBinding

## Introduction

# Kubernetes exposes a REST API to manage its objects like pods, deployments, services, secrets, ingress, etc.
# It uses the RBAC model to create and assign roles to users, groups and service accounts.

## 0. Setup demo environment

# Variables
$AKS_RG="rg-aks-serviceaccount"
$AKS_NAME="aks-cluster"

# Create and connect to AKS cluster
az group create --name $AKS_RG --location westeurope

az aks create --name $AKS_NAME --resource-group $AKS_RG --node-count 3 --zones 1 2 3 --kubernetes-version "1.25.2" --network-plugin azure

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes

## 1. Explore Kbernetes API Resources

kubectl api-resources

# View Kubernetes existing roles

kubectl get roles -A

kubectl get clusterroles -A

# View Kubernetes existing rolebindings

kubectl get rolebindings -A

kubectl get clusterrolebindings -A

## 2. Using Role and RoleBinding to assign roles to users and groups

kubectl create namespace my-namespace

kubectl create role pod-reader-role --verb=get --verb=list --verb=watch --resource=pods -n my-namespace -o yaml --dry-run=client > pod-reader-role.yaml

cat pod-reader-role.yaml

kubectl apply -f pod-reader-role.yaml

# Create a role binding for user1, user2, and group1 using the pod reader role
kubectl create rolebinding user-pod-reader-binding --role=pod-reader-role --user=user1 --user=user2 --group=group1 -n my-namespace -o yaml --dry-run=client > user-pod-reader-binding.yaml

cat user-pod-reader-binding.yaml

kubectl apply -f user-pod-reader-binding.yaml

# Verify the created role and role binding

kubectl get role,rolebinding -n my-namespace

## 3. Verify user access using impersonation

kubectl auth can-i get pods --namespace my-namespace --as user1

kubectl create deployment nginx --image=nginx -n my-namespace --replicas=2 # as myself

kubectl get pods --namespace my-namespace --as user1

# Verify with not allowed user
kubectl auth can-i get pods --namespace my-namespace --as user3

kubectl get pods --namespace my-namespace --as user3
# Error from server (Forbidden): pods is forbidden: User "user3" cannot list resource "pods" in API group "" in the namespace "my-namespace" Error from server (Forbidden): pods is forbidden: User "user3" cannot list resource "pods" in API group "" in the namespace "default"

# Verify with not allowed resource
kubectl auth can-i get secrets --namespace my-namespace --as user1

# Verify with not allowed namespace
kubectl auth can-i get pods --namespace default --as user1