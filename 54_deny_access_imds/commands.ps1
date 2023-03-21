# AKS Security: Deny access to IMDS metadata endpoint

# 1. Setup environment

$AKS_RG="rg-aks-cluster"
$AKS_NAME="aks-cluster"

az group create -n $AKS_RG -l westeurope

az aks create -g $AKS_RG -n $AKS_NAME `
              --kubernetes-version "1.25.5" `
              --node-count 3 `
              --network-plugin azure

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

# 2. Get AKS Managed Identities attached to the cluster (VMSS)

az vmss identity show -g rg-spoke-aks-nodes -n aks-poolsystem-97210295-vmss # replace with your vmss name & rg

# 3. View IMDS metadata endpoint and exposed information

# create azure-cli pod

kubectl run azure-cli -it --rm --image=mcr.microsoft.com/azure-cli:latest -- bash

# inside azure-cli pod, access IMDS metadata endpoint and view information

curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-12-13" | jq

# 4. Get the MSI Kubelet Client ID from the tagsList

curl -s -H Metadata:true --noproxy "*" \
  "http://169.254.169.254/metadata/instance?api-version=2021-12-13" \
  | jq .compute.tagsList[3].value

MSI_KUBELET_CLIENT_ID=$(curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-12-13" | jq .compute.tagsList[3].value --raw-output)
echo $MSI_KUBELET_CLIENT_ID

# 5. Get the access token for the MSI Kubelet Client ID

curl -s -H Metadata:true --noproxy "*" \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2021-12-13&resource=https://management.azure.com/&client_id=$MSI_KUBELET_CLIENT_ID" \
  | jq

# decode accessToken on jwt.io

# 6. Hack demo: use attached MSI to create and destroy resources in Azure

# get the resource ID (or client ID or Object ID) for any attached MSI

MSI_RESOURCE_ID="/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourcegroups/rg-spoke-aks-nodes/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ingressapplicationgateway-aks-cluster" # REPLACE WITH YOUR MSI ATTACHED TO AKS VMSS

# login to Azure using MSI

az login --identity -u $MSI_RESOURCE_ID

az resource list

az resource list -o table

# Create a storage account

az storage account create -n stortobedeletedbyhacker -g rg-spoke-aks-nodes
# successfuly created

az resource list -o table

# Delete the storage account

az storage account delete -n stortobedeletedbyhacker -g rg-spoke-aks-nodes

# exit from azure-cli pod

# 7. Network Policy to the rescue; deny access to IMDS endpoint

kubectl apply -f network-policy-deny-imds.yaml

# 8. Validate that access to IMDS is now denied

kubectl run azure-cli -it --rm --image=mcr.microsoft.com/azure-cli:latest -- bash

# run these commands inside azure-cli pod

# try access to IMDS endpoint; it should fail

curl -s -H Metadata:true --noproxy "*" \
  "http://169.254.169.254/metadata/instance?api-version=2021-12-13" \
  | jq

# login to Azure using MSI; it should fail

az login --identity -u $MSI_RESOURCE_ID

# this also should fail

az resource list -o table

# 9. Additional notes

# We can allow access to IMDS endpoint only for specific pods like Secret Store CSI, AGIC, OMS agent, etc.

# InspectorGadget is a pod that can detect access to IMDS endpoint: https://github.com/jelledruyts/InspectorGadget
