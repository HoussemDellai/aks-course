# Using Azure Blob Fuse with Managed Identity in AKS

## Introduction

## 0. Setup demo environment

# Variables
$AKS_RG="rg-aks-cluster"
$AKS_NAME="aks-cluster"
$STORAGE_ACCOUNT_NAME="storage4aks013"
$CONTAINER_NAME="container01"
$IDENTITY_NAME="identity-storage-account"

# Create and connect to AKS cluster
az group create --name $AKS_RG --location westeurope

az aks create --name $AKS_NAME --resource-group $AKS_RG --node-count 3 --zones 1 2 3 --kubernetes-version "1.25.4" --network-plugin azure  --enable-blob-driver

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes

# Verify the blob driver (DaemonSet) was installed

Set-Alias -Name grep -Value select-string # if using powershell
kubectl get pods -n kube-system | grep csi

# Create Storage Account 

az storage account create -n $STORAGE_ACCOUNT_NAME -g $AKS_RG -l westeurope --sku Premium_ZRS --kind BlockBlobStorage

# Create a SA container

az storage container create --account-name $STORAGE_ACCOUNT_NAME -n $CONTAINER_NAME

# Upload a file into the SA container

$STORAGE_ACCOUNT_KEY=$(az storage account keys list --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

az storage blob upload `
           --account-name $STORAGE_ACCOUNT_NAME `
           -c $CONTAINER_NAME `
           --name blobfile.html `
           --file blobfile.html `
           --auth-mode key `
           --account-key $STORAGE_ACCOUNT_KEY

# Assign admin role to my self

$CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)
$STORAGE_ACCOUNT_ID=$(az storage account show -n $STORAGE_ACCOUNT_NAME --query id)

az role assignment create --assignee $CURRENT_USER_ID `
        --role "Storage Account Contributor" `
        --scope $STORAGE_ACCOUNT_ID

# Verify the resources are created on the Azure portal

# Create Managed Identity

az identity create -g $AKS_RG -n $IDENTITY_NAME

# Assign RBAC role

$IDENTITY_CLIENT_ID=$(az identity show -g $AKS_RG -n $IDENTITY_NAME --query "clientId" -o tsv)

az role assignment create --assignee $IDENTITY_CLIENT_ID `
        --role "Storage Blob Data Owner" `
        --scope $STORAGE_ACCOUNT_ID

# Attach Managed Identity to AKS VMSS

$IDENTITY_ID=$(az identity show -g $AKS_RG -n $IDENTITY_NAME --query "id" -o tsv)

$NODE_RG=$(az aks show -g $AKS_RG -n $AKS_NAME --query nodeResourceGroup -o tsv)

$VMSS_NAME=$(az vmss list -g $NODE_RG --query [0].name -o tsv)

az vmss identity assign -g $NODE_RG -n $VMSS_NAME --identities $IDENTITY_ID

# Configure Persistent Volume (PV) with managed identity

@"
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-blob
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: azureblob-fuse-premium
  mountOptions:
    - -o allow_other
    - --file-cache-timeout-in-seconds=120
  csi:
    driver: blob.csi.azure.com
    readOnly: false
    volumeHandle: $STORAGE_ACCOUNT_NAME-$CONTAINER_NAME
    volumeAttributes:
      resourceGroup: $AKS_RG
      storageAccount: $STORAGE_ACCOUNT_NAME
      containerName: $CONTAINER_NAME
      # refer to https://github.com/Azure/azure-storage-fuse#environment-variables
      AzureStorageAuthType: msi  # key, sas, msi, spn
      AzureStorageIdentityResourceID: $IDENTITY_ID
"@ > pv-blobfuse.yaml

# Deploy the app

kubectl apply -f pv-blobfuse.yaml -f pvc-blobfuse.yaml -f nginx-pod-blob.yaml

kubectl get pods,svc,pvc,pv

# verify the Blob storage mounted

$POD_NAME=$(kubectl get pods -l app=nginx-app -o jsonpath='{.items[0].metadata.name}')

kubectl exec -it $POD_NAME -- df -h

kubectl exec -it $POD_NAME -- ls /usr/share/nginx/html

# Navigate to http://<PUBLIC_SERVICE_IP>/blobfile.html to view web app running the uploaded blobfile.html file.

# Additional resources
# src: https://github.com/qxsch/Azure-Aks/tree/master/aks-blobfuse-mi
# src: https://github.com/kubernetes-sigs/blob-csi-driver/blob/master/docs/driver-parameters.md