# https://learn.microsoft.com/en-us/azure/aks/ai-toolchain-operator

```sh
$RG = "rg-aks-kaito-swc1"
$LOCATION = "swedencentral"
$CLUSTER_NAME = "aks-cluster"

az group create --name $RG --location $LOCATION

az aks create -g $RG -n $CLUSTER_NAME --enable-oidc-issuer 
# --enable-ai-toolchain-operator

# add nodepool to the cluster with sku Standard_NC24ads_A100_v4 and type spot
# enable managed GPU Nodepool through tag `EnableManagedGPUExperience=true`
az aks nodepool add --name nc24adsa100g `
    --resource-group $RG `
    --cluster-name $CLUSTER_NAME `
    --node-vm-size Standard_NC24ads_A100_v4 `
    --tags EnableManagedGPUExperience=true `
    --node-count 1 `
    --enable‐cluster‐autoscaler `
    --min‐count 1 `
    --max‐count 3 `
    --priority Spot `
    --eviction-policy Delete

az aks get-credentials -g $RG -n $CLUSTER_NAME --overwrite-existing

kubectl get nodes

# install KAITO
helm repo add kaito https://kaito-project.github.io/kaito/charts/kaito
helm repo update
helm upgrade --install kaito-workspace kaito/workspace `
  --namespace kaito-workspace `
  --create-namespace `
  --set clusterName="aks-cluster" `
  --set defaultNodeImageFamily="ubuntu" `
  --set featureGates.gatewayAPIInferenceExtension=true `
  --set featureGates.disableNodeAutoProvisioning=false `
  --set gpu-feature-discovery.nfd.enabled=true `
  --set gpu-feature-discovery.gfd.enabled=true `
  --set nvidiaDevicePlugin.enabled=true `
  --wait `
  --take-ownership

>Node Image Family could be either `ubuntu` or `azurelinux`.

>`gpu-feature-discovery.nfd.enabled=true`, `gpu-feature-discovery.gfd.enabled=true` and `nvidiaDevicePlugin.enabled=true` are the default values in the chart.

# Verify KAITO Installation
# Check that the KAITO workspace controller is running:

kubectl get pods -n kaito-workspace
kubectl describe deploy kaito-workspace -n kaito-workspace

# View the taints on the new node
kubectl describe node aks-nc24adsa100g-10854801-vmss000000
# Taints:             kubernetes.azure.com/scalesetpriority=spot:NoSchedule

Add Toleration for Spot VMs to:
1. workspace-phi-4-mini StatefulSet
That should be implemented by PG into here: https://github.com/kaito-project/kaito/blob/main/charts/kaito/workspace/templates/kaito.sh_workspaces.yaml
2. nvidia-device-plugin-daemonset DaemonSet : https://github.com/kaito-project/kaito/blob/1e723e307fc390ec8dd42bad55b815a59f2f4019/charts/kaito/workspace/templates/nvidia-device-plugin-ds.yaml#L38

        - key: kubernetes.azure.com/scalesetpriority
          operator: Equal
          value: spot
          effect: NoSchedule

# Deploy the Phi-4 model from the KAITO model repository using the kubectl apply command.
kubectl apply -f .\kaito_workspace_phi_4_mini.yaml -n kaito-workspace

# List your GPU nodes and verify that they are all present and ready.
kubectl get nodes -l accelerator=nvidia
# NAME                                   STATUS   ROLES    AGE   VERSION
# aks-nc24adsa100g-10854801-vmss000000   Ready    <none>   14m   v1.33.7

# The GPU nodes will need a label in order for a KAITO Workspace to select it. We'll use the label apps=phi-4 for this example. Label the nodes you want to use.
kubectl label node aks-nc24adsa100g-10854801-vmss000000 apps=phi-4
# node/aks-nc24adsa100g-10854801-vmss000000 labeled

# Monitor Deployment
# Track the workspace status to see when the model has been deployed successfully:

kubectl get workspace workspace-phi-4-mini
# NAME                   INSTANCE                   RESOURCEREADY   INFERENCEREADY   JOBSTARTED   WORKSPACESUCCEEDED   AGE
# workspace-phi-4-mini   Standard_NC24ads_A100_v4   True            True                          True                 4h15m

# When the WORKSPACESUCCEEDED column becomes True, the model has been deployed successfully.

# Test the Model
# Find the inference service's cluster IP and test it using a temporary curl pod:

# Get the service endpoint
kubectl get svc workspace-phi-4-mini
export CLUSTERIP=$(kubectl get svc workspace-phi-4-mini -o jsonpath="{.spec.clusterIPs[0]}")

# List available models
kubectl run -it --rm --restart=Never curl --image=curlimages/curl -- curl -s http://$CLUSTERIP/v1/models | jq

# Make an Inference Call
# Now make an inference call using the model:

kubectl run -it --rm --restart=Never curl --image=curlimages/curl -- curl -X POST http://$CLUSTERIP/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "phi-4-mini-instruct",
    "messages": [{"role": "user", "content": "What is kubernetes?"}],
    "max_tokens": 50,
    "temperature": 0
  }'
```

## Monitoring

## Important notes

>You need to create GPU nodes in order to run a Workspace with KAITO. There are two mutually exclusive options:

- Bring your own GPU (BYO) nodes: Create your own GPU nodes to run KAITO deployments on. When using BYO nodes, Node Auto Provisioning (NAP) must be disabled.
- Auto-provisioning: Set up automatic GPU node provisioning for your cloud provider. This option cannot be used with BYO nodes.

## Resources

- https://kaito-project.github.io/kaito/docs/installation/