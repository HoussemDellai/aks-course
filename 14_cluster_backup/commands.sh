# src: https://docs.microsoft.com/en-us/azure/aks/azure-disk-csi

# Deploy a Pod with Azure Disk
kubectl apply -f pvc-azure-disk.yaml
kubectl apply -f pod-nginx-azure-disk.yaml
kubectl describe pod mypod
kubectl get pvc

# After the pod is in the running state, create a new file called test.txt.
kubectl exec nginx-azuredisk -- touch /mnt/azuredisk/test.txt

# You can now validate that the disk is correctly mounted 
# by running the following command and verifying you see 
# the test.txt file in the output:
kubectl exec nginx-azuredisk -- ls /mnt/azuredisk
# lost+found
# outfile
# test.txt

# Create a custom storage class (optional)
kubectl apply -f sc-azure-disk-csi.yaml

# create a volume snapshot class 
kubectl apply -f vsc-azure-disk.yaml

# create a volume snapshot from the PVC that we dynamically created 
kubectl apply -f vs-azure-disk.yaml

# check the created Azure Disk
az disk list -o table

# check that the snapshot was created correctly:
kubectl describe volumesnapshot azuredisk-volume-snapshot

# check the Snapshot in Azure
az snapshot list -o table

# create a new PVC based on a volume snapshot. 
# Use the snapshot created in the previous step, 
# and create a new PVC and a new pod to consume it.
kubectl apply -f pvc-snapshot-restored.yaml
kubectl apply -f pod-restored.yaml

# Finally, let's make sure it's the same PVC created before by checking the contents
kubectl exec nginx-restored -- ls /mnt/azuredisk