# Create an AKS cluster with CSI Disk Driver and Snapshot Controller

# 0. Prerequisites

az provider register --namespace Microsoft.KubernetesConfiguration
az feature register --namespace "Microsoft.ContainerService" --name "TrustedAccessPreview"

# 1. Setup environment variables

$AKS_NAME_01="aks-1"
$AKS_RG_01="rg-aks-1"

$AKS_NAME_02="aks-2"
$AKS_RG_02="rg-aks-2"

$VAULT_NAME="backup-vault"
$VAULT_RG="rg-backup-vault"

$SA_NAME="storage4aks1backup1357"
$SA_RG="rg-backup-storage"
$BLOB_CONTAINER_NAME="aks-backup"
$SUBSCRIPTION_ID=$(az account list --query [?isDefault].id -o tsv)

# 2. Create Backup Vault resource group and Backup Vault

az group create --name $VAULT_RG --location westeurope

az dataprotection backup-vault create `
   --vault-name $VAULT_NAME `
   -g $VAULT_RG `
   --storage-setting "[{type:'LocallyRedundant',datastore-type:'VaultStore'}]"
   
# 3. Create storage acount and Blob container for storing Backup data

az group create --name $SA_RG --location westeurope

az storage account create `
   --name $SA_NAME `
   --resource-group $SA_RG `
   --sku Standard_LRS

$ACCOUNT_KEY=$(az storage account keys list --account-name $SA_NAME -g $SA_RG --query "[0].value" -o tsv)

az storage container create `
   --name $BLOB_CONTAINER_NAME `
   --account-name $SA_NAME `
   --account-key $ACCOUNT_KEY

# 4. Create first AKS cluster with CSI Disk Driver and Snapshot Controller

az group create --name $AKS_RG_01 --location westeurope

az aks create -g $AKS_RG_01 -n $AKS_NAME_01 -k "1.25.5" --zones 1 2 3

# Verify that CSI Disk Driver and Snapshot Controller are installed

az aks show -g $AKS_RG_01 -n $AKS_NAME_01 --query storageProfile

# If not installed, you ca install it with this command:
# az aks update -g $AKS_RG_01 -n $AKS_NAME_01 --enable-disk-driver --enable-snapshot-controller

# 5. Create second AKS cluster with CSI Disk Driver and Snapshot Controller

az group create --name $AKS_RG_02 --location westeurope

az aks create -g $AKS_RG_02 -n $AKS_NAME_02 -k "1.25.5" --zones 1 2 3

# Verify that CSI Disk Driver and Snapshot Controller are installed

az aks show -g $AKS_RG_02 -n $AKS_NAME_02 --query storageProfile

# If not installed, you ca install it with this command:

# az aks update -g $AKS_RG_02 -n $AKS_NAME_02 --enable-disk-driver --enable-snapshot-controller

# 6. Install the Backup extension in first AKS cluster

az extension add --name k8s-extension

az k8s-extension create --name azure-aks-backup `
   --extension-type Microsoft.DataProtection.Kubernetes `
   --scope cluster `
   --cluster-type managedClusters `
   --cluster-name $AKS_NAME_01 `
   --resource-group $AKS_RG_01 `
   --release-train stable `
   --configuration-settings `
   blobContainer=$BLOB_CONTAINER_NAME `
   storageAccount=$SA_NAME `
   storageAccountResourceGroup=$SA_RG `
   storageAccountSubscriptionId=$SUBSCRIPTION_ID

# View Backup Extension installation status

az k8s-extension show --name azure-aks-backup --cluster-type managedClusters --cluster-name $AKS_NAME_01 -g $AKS_RG_01

# Enable Trusted Access in AKS

$BACKUP_VAULT_ID=$(az dataprotection backup-vault show --vault-name $VAULT_NAME -g $VAULT_RG --query id -o tsv)

az aks trustedaccess rolebinding create –n trustedaccess `
   -g $AKS_RG_01 `
   --cluster-name $AKS_NAME_01 `
   --source-resource-id $BACKUP_VAULT_ID `
   --roles Microsoft.DataProtection/backupVaults/backup-operator
#    {
#     "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-cluster-01/providers/Microsoft.ContainerService/managedClusters/aks-cluster-01/trustedAccessRoleBindings/trustedaccess",
#     "name": "trustedaccess",
#     "provisioningState": "Updating",
#     "resourceGroup": "rg-aks-cluster-01",
#     "roles": [
#       "Microsoft.DataProtection/backupVaults/backup-operator"
#     ],
#     "sourceResourceId": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-backup-vault/providers/Microsoft.DataProtection/backupVaults/backup-vault",
#     "systemData": null,
#     "type": "Microsoft.ContainerService/managedClusters/trustedAccessRoleBindings"
#   }

az aks trustedaccess rolebinding list -g $AKS_RG_01 --cluster-name $AKS_NAME_01
#    [
#      {
#        "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-aks-cluster-01/providers/Microsoft.ContainerService/managedClusters/aks-cluster-01/trustedAccessRoleBindings/trustedaccess",
#        "name": "trustedaccess",
#        "provisioningState": "Succeeded",
#        "resourceGroup": "rg-aks-cluster-01",
#        "roles": [
#          "Microsoft.DataProtection/backupVaults/backup-operator"
#        ],
#        "sourceResourceId": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-backup-vault/providers/Microsoft.DataProtection/backupVaults/backup-vault",
#        "systemData": null,
#        "type": "Microsoft.ContainerService/managedClusters/trustedAccessRoleBindings"
#      }
#    ]

# 7. Install the Backup extension in second AKS cluster

az k8s-extension create --name azure-aks-backup `
   --extension-type Microsoft.DataProtection.Kubernetes `
   --scope cluster `
   --cluster-type managedClusters `
   --cluster-name $AKS_NAME_02 `
   --resource-group $AKS_RG_02 `
   --release-train stable `
   --configuration-settings `
   blobContainer=$BLOB_CONTAINER_NAME `
   storageAccount=$SA_NAME `
   storageAccountResourceGroup=$SA_RG `
   storageAccountSubscriptionId=$SUBSCRIPTION_ID

# View Backup Extension installation status

az k8s-extension show --name azure-aks-backup --cluster-type managedClusters --cluster-name $AKS_NAME_02 -g $AKS_RG_02

# Enable Trusted Access in AKS

$BACKUP_VAULT_ID=$(az dataprotection backup-vault show --vault-name $VAULT_NAME -g $VAULT_RG --query id -o tsv)

az aks trustedaccess rolebinding create `
   -g $AKS_RG_02 `
   --cluster-name $AKS_NAME_02 `
   –n trustedaccess `
   -s $BACKUP_VAULT_ID `
   --roles Microsoft.DataProtection/backupVaults/backup-operator

# 8. Create a Backup Policy

az dataprotection backup-instance create -g MyResourceGroup --vault-name MyVault --backup-instance backupinstance.json

# az backup policy create -n "aks-backup-policy" -g $VAULT_RG `
#    --vault-name $VAULT_NAME `
#    --subscription $SUBSCRIPTION_ID `
#    --policy '{ 
#     "properties": 
#     { 
#         "backupManagementType": "AzureKubernetesService", 
#         "workloadType": "AzureKubernetesService", 
#         "schedulePolicy": 
#         { 
#             "schedulePolicyType": "SimpleSchedulePolicy", 
#             "scheduleRunDays": [ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" ], 
#             "scheduleRunFrequency": "Daily", 
#             "scheduleRunTimes": [ "2021-10-01T00:00:00Z" ], 
#             "scheduleWeeklyFrequency": 1 
#         }, 
#         "retentionPolicy": 
#         { 
#             "retentionPolicyType": "SimpleRetentionPolicy", 
#             "retentionDuration": 
#             { 
#                 "count": 30, 
#                 "durationType": "Days" 
#             } 
#         }, 
#         "timeZone": "UTC" 
#     } 
# }'

# 9. Create a Backup Instance

az backup container register --resource-group $AKS_RG_01 --vault-name $VAULT_NAME --subscription $SUBSCRIPTION_ID --backup-management-type AzureKubernetesService --workload-type AzureKubernetesService --query properties.friendlyName -o tsv

$CONTAINER_NAME=$(az backup container list --resource-group $AKS_RG_01 --vault-name $VAULT_NAME --subscription $SUBSCRIPTION_ID --backup-management-type AzureKubernetesService --query "[0].name" -o tsv)

az backup item set-policy --resource-group $AKS_RG_01 --vault-name $VAULT_NAME --subscription $SUBSCRIPTION_ID --container-name $CONTAINER_NAME --item-name $CONTAINER_NAME --policy-name "aks-backup-policy"

# 10. Create a Backup Instance

az backup container register --resource-group $AKS_RG_02 --vault-name $VAULT_NAME --subscription $SUBSCRIPTION_ID --backup-management-type AzureKubernetesService --workload-type AzureKubernetesService --query properties.friendlyName -o tsv

$CONTAINER_NAME=$(az backup container list --resource-group $AKS_RG_02 --vault-name $VAULT_NAME --subscription $SUBSCRIPTION_ID --backup-management-type AzureKubernetesService --query "[0].name" -o tsv)

az backup item set-policy --resource-group $AKS_RG_02 --vault-name $VAULT_NAME --subscription $SUBSCRIPTION_ID --container-name $CONTAINER_NAME --item-name $CONTAINER_NAME --policy-name "aks-backup-policy"

# 11. Create a Backup Job

az backup job start --resource-group $AKS_RG_01 --vault-name $VAULT_NAME --subscription $SUBSCRIPTION_ID --container-name $CONTAINER_NAME --item-name $CONTAINER_NAME --backup-management-type AzureKubernetesService --workload-type AzureKubernetesService --operation TriggerBackup

# 12. Create a Backup Job

az backup job start --resource-group $AKS_RG_02 --vault-name $VAULT_NAME --subscription $SUBSCRIPTION_ID --container-name $CONTAINER_NAME --item-name $CONTAINER_NAME --backup-management-type AzureKubernetesService --workload-type AzureKubernetesService --operation TriggerBackup




az aks get-credentials -n aks-01 -g rg-aks-01 --overwrite-existing
# Merged "aks-01" as current context in C:\Users\hodellai\.kube\config

kubectl get pods -n dataprotection-microsoft
# NAME                                                         READY   STATUS    RESTARTS      AGE
# dataprotection-microsoft-controller-7b8977698c-v2rl7         2/2     Running   0             94m
# dataprotection-microsoft-geneva-service-6c8457bbd-jgw49      2/2     Running   0             94m
# dataprotection-microsoft-kubernetes-agent-5558dbbf8f-5tdkc   2/2     Running   2 (94m ago)   94m






az aks get-credentials -n aks-01 -g rg-aks-01 --overwrite-existing
# Merged "aks-01" as current context in C:\Users\hodellai\.kube\config

kubectl get nodes
# NAME                                 STATUS   ROLES   AGE   VERSION
# aks-systempool-20780455-vmss000000   Ready    agent   28m   v1.25.5
# aks-systempool-20780455-vmss000001   Ready    agent   28m   v1.25.5
# aks-systempool-20780455-vmss000002   Ready    agent   28m   v1.25.5

kubectl apply -f deploy_disk_lrs.yaml
# deployment.apps/nginx-lrs created
# persistentvolumeclaim/azure-managed-disk-lrs created

kubectl apply -f deploy_disk_zrs_sc.yaml
# deployment.apps/nginx-zrs created
# storageclass.storage.k8s.io/managed-csi-zrs created
# persistentvolumeclaim/azure-managed-disk-zrs created

kubectl get pods,svc,pv,pvc
# NAME                             READY   STATUS    RESTARTS   AGE
# pod/nginx-lrs-7db4886f8c-x4hzz   1/1     Running   0          90s
# pod/nginx-zrs-5567fd9ddc-hbtfs   1/1     Running   0          80s

# NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
# service/kubernetes   ClusterIP   10.0.0.1     <none>        443/TCP   30m

# NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                            STORAGECLASS      REASON   AGE
# persistentvolume/pvc-c3fc20ea-2922-477c-a337-895b8b503a9b   5Gi        RWO            Delete           Bound    default/azure-managed-disk-lrs   managed-csi                86s
# persistentvolume/pvc-f1055e1c-b8e1-4604-8567-1f288daced02   5Gi        RWO            Delete           Bound    default/azure-managed-disk-zrs   managed-csi-zrs            76s

# NAME                                           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
# persistentvolumeclaim/azure-managed-disk-lrs   Bound    pvc-c3fc20ea-2922-477c-a337-895b8b503a9b   5Gi        RWO            managed-csi       90s
# persistentvolumeclaim/azure-managed-disk-zrs   Bound    pvc-f1055e1c-b8e1-4604-8567-1f288daced02   5Gi        RWO            managed-csi-zrs   80s

kubectl exec nginx-lrs-7db4886f8c-x4hzz -it -- cat /mnt/azuredisk/outfile
# Tue Mar 21 15:00:14 UTC 2023
# Tue Mar 21 15:01:14 UTC 2023
# Tue Mar 21 15:02:14 UTC 2023
# Tue Mar 21 15:03:14 UTC 2023

kubectl exec nginx-zrs-5567fd9ddc-hbtfs -it -- cat /mnt/azuredisk/outfile
# Tue Mar 21 15:00:48 UTC 2023
# Tue Mar 21 15:01:48 UTC 2023
# Tue Mar 21 15:02:48 UTC 2023
# Tue Mar 21 15:03:48 UTC 2023
