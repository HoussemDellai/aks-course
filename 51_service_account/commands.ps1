# Kubernetes Service Account

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

## 1. Creating role to only get/list pods

# Create namespace for testing

kubectl create namespace my-namespace

# Create role for pod reader

kubectl create role sa-pod-reader-role --verb=get --verb=list --verb=watch --resource=pods --namespace my-namespace -o yaml --dry-run=client > sa-pod-reader-role.yaml

cat sa-pod-reader-role.yaml

kubectl apply -f sa-pod-reader-role.yaml

## 2. Creating Service Account

kubectl create serviceaccount my-service-account --namespace my-namespace -o yaml --dry-run=client > my-service-account.yaml

cat my-service-account.yaml

kubectl apply -f my-service-account.yaml

kubectl get serviceaccount -n my-namespace

## 3. Assign role to service account using rolebinding object

kubectl create rolebinding sa-pod-reader-binding --role=sa-pod-reader-role --serviceaccount=my-namespace:my-service-account --namespace my-namespace -o yaml --dry-run=client > sa-pod-reader-binding.yaml

cat sa-pod-reader-binding.yaml

kubectl apply -f sa-pod-reader-binding.yaml

## 5. Verifying access to API Server resources using impersonation

# Verify with all satisfied constraints: service account, namespace, resource, action

kubectl auth can-i get pods --namespace my-namespace --as system:serviceaccount:my-namespace:my-service-account

kubectl create deployment nginx --image=nginx -n my-namespace --replicas=2 # as myself

kubectl get pods --namespace my-namespace --as system:serviceaccount:my-namespace:my-service-account

# Verify with not allowed namespace
kubectl auth can-i get pods --namespace default --as system:serviceaccount:my-namespace:my-service-account

# Verify with not allowed resource
kubectl get secrets --namespace my-namespace --as system:serviceaccount:my-namespace:my-service-account

## 6. Accessing the API Server REST API from a Pod

# Assign the Service Account to Deployment; add: serviceAccountName: my-service-account

kubectl create deployment nginx-sa --image=nginx --replicas=2 -n my-namespace --dry-run=client -o yaml > deployment.yaml

cat deployment.yaml

kubectl apply -f deployment.yaml

kubectl get pods -n my-namespace

# Get the pods using '-v 6' to show the REST API endpoint

kubectl get pods -n my-namespace -v 6

# Get a pod that uses my-service-account

$POD_NAME=$(kubectl get pods -l app=nginx-sa -n my-namespace -o jsonpath='{.items[0].metadata.name}')
echo $POD_NAME

kubectl exec -it $POD_NAME -n my-namespace -- bash
# root@nginx-sa-8595cf7d74-9pxfp:/#

# From inside this pod, we want to access the REST API to retrieve Pods in the namespace my-namespace

# Run the following commands inside the pod shell

# Path to ServiceAccount token
ls /var/run/secrets/kubernetes.io/serviceaccount

# Read this Pod's namespace
NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
echo $NAMESPACE

# Read the ServiceAccount bearer token
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
echo $TOKEN

# Reference the internal certificate authority (CA)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
cat $CACERT

# Explore the API with TOKEN
curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET https://kubernetes.default.svc/api

# Get the pods from API Server REST endpoint 
curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET https://kubernetes.default.svc/api/v1/namespaces/my-namespace/pods