# https://learn.microsoft.com/en-us/azure/aks/ai-toolchain-operator

$RG = "rg-aks-kaito-swc"
$LOCATION = "swedencentral"
$CLUSTER_NAME = "aks-cluster"

az group create --name $RG --location $LOCATION

az aks create -g $RG -n $CLUSTER_NAME --enable-oidc-issuer --enable-ai-toolchain-operator --generate-ssh-keys

az aks get-credentials -g $RG -n $CLUSTER_NAME --overwrite-existing

kubectl get nodes

kubectl get deployment -n kube-system | grep kaito

# Deploy the Falcon 7B-instruct model from the KAITO model repository using the kubectl apply command.
kubectl apply -f https://raw.githubusercontent.com/Azure/kaito/main/examples/inference/kaito_workspace_falcon_7b-instruct.yaml

kubectl get workspace workspace-falcon-7b-instruct -w

# add nodepool to the cluster with sku Standard_NC24ads_A100_v4 and type spot
az aks nodepool add  --name nc24adsa100g `
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

# View the taints on the new node
kubectl describe node aks-nc24adsa100g-10854801-vmss000000
# Taints:             kubernetes.azure.com/scalesetpriority=spot:NoSchedule

# add this toleration to kaito-nvidia-device-plugin-daemonset to allow it to run on the spot nodepool: 
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

# The GPU nodes will need a label in order for a KAITO Workspace to select it. We'll use the label apps=llm-inference for this example. Label the nodes you want to use.
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