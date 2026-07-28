# AKS Blobfuse ADLS with Workload Identity

## Introduction

This example demonstrates how to use Azure Blobfuse with Workload Identity in AKS. The example uses Terraform to deploy the infrastructure and Kubernetes manifests to deploy the resources.

## Deploying the infrastructure

Run the following Terraform commands from the root folder.

```powershell
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

## Deploying Kubernetes resources

```powershell
$SERVICE_ACCOUNT_NAME=$(terraform output -raw service_account_name)
$SERVICE_ACCOUNT_NAMESPACE=$(terraform output -raw service_account_namespace)

$STORAGE_ACCOUNT_RG=$(terraform output -raw storage_account_rg)
$STORAGE_ACCOUNT_NAME=$(terraform output -raw storage_account_name)
$CONTAINER_NAME=$(terraform output -raw container_name)

$IDENTITY_CLIENT_ID=$(terraform output -raw identity_wi_client_id)
```

<!-- ```powershell
$SERVICE_ACCOUNT_NAME="service-account-01"
$SERVICE_ACCOUNT_NAMESPACE="default"

$STORAGE_ACCOUNT_RG="rg-aks-blob-adls-wi-48"
$STORAGE_ACCOUNT_NAME="stor4adls4aks48"
$CONTAINER_NAME="container-01"

$IDENTITY_CLIENT_ID="a4b7b9fd-ca18-4261-ba79-d9da4b751d74"
``` -->

```powershell
@"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $SERVICE_ACCOUNT_NAME
  namespace: $SERVICE_ACCOUNT_NAMESPACE
"@ > ./kubernetes/service_account_01.yaml
```

```powershell
@"
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: blob.csi.azure.com
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
    # make sure volumeHandle is unique for every storage blob container in the cluster
    volumeHandle: $STORAGE_ACCOUNT_NAME-$CONTAINER_NAME
    volumeAttributes:
      protocol: fuse
      resourceGroup: $STORAGE_ACCOUNT_RG
      storageAccount: $STORAGE_ACCOUNT_NAME
      containerName: $CONTAINER_NAME
      # refer to https://github.com/Azure/azure-storage-fuse#environment-variables
      # AzureStorageAuthType: msi  # key, sas, msi, spn
      clientID: $IDENTITY_CLIENT_ID
      # AzureStorageIdentityResourceID: $IDENTITY_ID
      mountWithWorkloadIdentityToken: "true"   # uncomment for token-only mode (supported from v1.27.0); requires Storage Blob Data Contributor role
"@ > ./kubernetes/pv_blobfuse.yaml
```

```powershell
@"
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc-blob
  namespace: $SERVICE_ACCOUNT_NAMESPACE
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  volumeName: pv-blob
  storageClassName: azureblob-fuse-premium
"@ > ./kubernetes/pvc_blobfuse.yaml
```

```powershell
@"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-blob
  namespace: $SERVICE_ACCOUNT_NAMESPACE
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      serviceAccountName: $SERVICE_ACCOUNT_NAME   # required for workload identity
      nodeSelector:
        kubernetes.io/os: linux
      containers:
        - name: deployment-blob
          image: mcr.microsoft.com/oss/nginx/nginx:1.17.3-alpine
          command:
            - "/bin/sh"
            - "-c"
            - while true; do echo $(date) >> /mnt/blob/outfile; sleep 30; done
          volumeMounts:
            - name: blob
              mountPath: /mnt/blob
      volumes:
        - name: blob
          persistentVolumeClaim:
            claimName: pvc-blob
  strategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
    type: RollingUpdate
"@ > ./kubernetes/deployment_blob.yaml
```

```powershell
kubectl apply -f ./kubernetes/
```

## Important Notes

* NFS mount is not supported — NFS does not require credentials during mount, so workload identity is not applicable.
* By default, this feature retrieves the storage account key using federated identity credentials.
* Mount with workload identity token only: Supported from v1.27.0. To enable:
  * Set mountWithWorkloadIdentityToken: "true" in parameters of the StorageClass or volumeAttributes of the PersistentVolume
  * Grant Storage Blob Data Contributor role (instead of Storage Account Contributor) to the managed identity
* Supports both Static and Dynamic provisioning of Persistent Volumes.
* The following types of storage accounts support Data Lake Storage capabilities: `Standard general-purpose v2` and `Premium block blob`.


## Resources

* https://github.com/kubernetes-sigs/blob-csi-driver/blob/master/docs/workload-identity-static-pv-mount.md
* https://learn.microsoft.com/en-us/azure/aks/create-volume-azure-blob-storage?tabs=NFS%2Cblobfuse