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
    --priority Spot `
    --eviction-policy Delete

# az aks nodepool add  --name nc24adsa100g `
#     --resource-group $RG `
#     --cluster-name $CLUSTER_NAME `
#     --node-vm-size Standard_NC24ads_A100_v4 `
#     --node‐taints sku=gpu:NoSchedule `
#     --tags EnableManagedGPUExperience=true `
#     --node-count 1 `
#     --enable‐cluster‐autoscaler `
#     --min‐count 1 `
#     --max‐count 3 `
#     --priority Spot `
#     --eviction-policy Delete

az aks get-credentials -g $RG -n $CLUSTER_NAME --overwrite-existing

kubectl get nodes

kubectl get deployment -n kube-system | grep kaito

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
  --wait `
  --take-ownership

>Node Image Family could be either `ubuntu` or `azurelinux`.

# Verify KAITO Installation
# Check that the KAITO workspace controller is running:

kubectl get pods -n kaito-workspace
kubectl describe deploy kaito-workspace -n kaito-workspace

Add Toleration for Spot VMs to:
1. workspace-phi-4-mini StatefulSet
2. nvidia-device-plugin-daemonset DaemonSet
        - key: kubernetes.azure.com/scalesetpriority
          operator: Equal
          value: spot
          effect: NoSchedule

# # install Nvidia GPU Operator
# kubectl create ns gpu-operator
# kubectl label --overwrite ns gpu-operator pod-security.kubernetes.io/enforce=privileged
# helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
# helm repo update

# helm upgrade --install gpu-operator-1773102157 `
#     --wait `
#     -n gpu-operator `
#     --create-namespace `
#     nvidia/gpu-operator


    # --set node-feature-discovery.worker.tolerations[2].key="kubernetes.azure.com/scalesetpriority" `
    # --set node-feature-discovery.worker.tolerations[2].operator="Equal" `
    # --set node-feature-discovery.worker.tolerations[2].value="spot" `
    # --set node-feature-discovery.worker.tolerations[2].effect="NoSchedule"



  # tolerations:
  # - key: nvidia.com/gpu
  #   operator: Exists
  #   effect: NoSchedule

# Ensure that the GPU operator is installed by running the following command:

# kubectl -n gpu-operator wait pod `
#     --for=condition=Ready `
#     -l app.kubernetes.io/component=gpu-operator `
#     --timeout=300s

# Deploy the Falcon 7B-instruct model from the KAITO model repository using the kubectl apply command.
kubectl apply -f https://raw.githubusercontent.com/Azure/kaito/main/examples/inference/kaito_workspace_falcon_7b-instruct.yaml

kubectl get workspace workspace-falcon-7b-instruct -w

# View the taints on the new node
kubectl describe node aks-nc24adsa100g-10854801-vmss000000
# Taints:             kubernetes.azure.com/scalesetpriority=spot:NoSchedule

# add this toleration to kaito-nvidia-device-plugin-daemonset and also to kaito-workspace-node-feature-discovery-worker to allow it to run on the spot nodepool: 
# kubernetes.azure.com/scalesetpriority=spot:NoSchedule
kubectl -n kube-system patch daemonset kaito-nvidia-device-plugin-daemonset -p '{"spec":{"template":{"spec":{"tolerations":[{"key":"kubernetes.azure.com/scalesetpriority","operator":"Equal","value":"spot","effect":"NoSchedule"}]}}}}'

# apply these tolerations also to the daemonset
# CriticalAddonsOnly op=Exists
#                         nvidia.com/gpu:NoSchedule op=Exists
#                         sku=gpu:NoSchedule


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

## Important notes

>You need to create GPU nodes in order to run a Workspace with KAITO. There are two mutually exclusive options:

- Bring your own GPU (BYO) nodes: Create your own GPU nodes to run KAITO deployments on. When using BYO nodes, Node Auto Provisioning (NAP) must be disabled.
- Auto-provisioning: Set up automatic GPU node provisioning for your cloud provider. This option cannot be used with BYO nodes.

## Resources

- https://kaito-project.github.io/kaito/docs/installation/