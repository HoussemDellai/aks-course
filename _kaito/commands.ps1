# https://learn.microsoft.com/en-us/azure/aks/ai-toolchain-operator

$AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
$AZURE_RESOURCE_GROUP="rg-aks-cluster"
$AZURE_LOCATION="swedencentral"
$CLUSTER_NAME="aks-cluster"

az group create --name $AZURE_RESOURCE_GROUP --location $AZURE_LOCATION

az aks create -g $AZURE_RESOURCE_GROUP -n $CLUSTER_NAME --enable-oidc-issuer --enable-ai-toolchain-operator --network-plugin azure --network-plugin-mode overlay -k 1.34.2 --node-vm-size standard_d2ads_v6 --node-osdisk-type Ephemeral --node-osdisk-size 64 --enable-apiserver-vnet-integration

az aks get-credentials -g $AZURE_RESOURCE_GROUP -n $CLUSTER_NAME --overwrite-existing

kubectl get nodes

# Deploy a default hosted AI model

kubectl apply -f https://raw.githubusercontent.com/kaito-project/kaito/refs/heads/main/examples/inference/kaito_workspace_phi_4_mini.yaml

# Track the live resource changes in your workspace using the kubectl get command.

kubectl get workspace workspace-phi-4-mini -w

# Check your inference service and get the service IP address using the kubectl get svc command.

export SERVICE_IP=$(kubectl get svc workspace-phi-4-mini -o jsonpath='{.spec.clusterIP}')

# Test the Phi-4-mini instruct inference service with a sample input of your choice using the OpenAI chat completions API format:

kubectl run -it --rm --restart=Never curl --image=curlimages/curl -- curl -X POST http://$SERVICE_IP/v1/completions -H "Content-Type: application/json" -d '{
        "model": "phi-4-mini-instruct",
        "prompt": "How should I dress for the weather today?",
        "max_tokens": 10
       }'