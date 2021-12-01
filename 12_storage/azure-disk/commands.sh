# src: https://docs.microsoft.com/en-us/azure/aks/azure-disks-dynamic-pv
# Deploy a Pod with Azure Disk
kubectl apply -f azure-disk-pvc.yaml
kubectl apply -f pod.yaml
kubectl describe pod mypod
kubectl get pvc azure-managed-disk

# List the deployed Azure Disk from the AKS node resource group
az disk list -o table

# Create a Snapshot from the Disk (replace values)
az snapshot create \
    --resource-group MC_myResourceGroup_myAKSCluster_eastus \
    --name pvcSnapshot \
    --source /subscriptions/<guid>/resourceGroups/MC_myResourceGroup_myAKSCluster_eastus/providers/MicrosoftCompute/disks/kubernetes-dynamic-pvc-faf0f176-8b8d-11e8-923b-deb28c58d242

# Create a Disk from the Snapshot
az disk create --resource-group MC_myResourceGroup_myAKSCluster_eastus --name pvcRestored --source pvcSnapshot

# Check the created Disk
az disk show --resource-group MC_myResourceGroup_myAKSCluster_eastus --name pvcRestored --query id -o tsv