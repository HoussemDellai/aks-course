# Connecting Streamlit app in AKS to Azure OpenAI Service

# Create environment variables
$RG_NAME = "rg-aks-cluster"
$AKS_NAME = "aks-cluster"
$LOCATION = "swedencentral"
$ACR_NAME = "acr4aks173"
$AI_SERVICE_NAME = "ai-service-aks173"

# Create resource group
az group create -n $RG_NAME -l $LOCATION

# Create Azure Container Registry (ACR)
az acr create -g $RG_NAME -n $ACR_NAME --sku Standard -l $LOCATION

# Create AKS cluster
az aks create -n $AKS_NAME -g $RG_NAME --network-plugin azure --network-plugin-mode overlay -k 1.32.0 --node-vm-size standard_d2ads_v5

# Attach ACR to AKS
az aks update -n $AKS_NAME -g $RG_NAME --attach-acr $ACR_NAME

# Get AKS credentials
az aks get-credentials -n $AKS_NAME -g $RG_NAME --overwrite-existing

# Login to ACR
az acr login -n $ACR_NAME --expose-token

# Build docker image in ACR
az acr build -r $ACR_NAME -t streamlit-app:1.0.0 ./streamlit-app

# Create an Azure AI Services resource
az cognitiveservices account create -n $AI_SERVICE_NAME -g $RG_NAME --kind AIServices --sku S0 --location $LOCATION --custom-domain $AI_SERVICE_NAME

# Creating deployment for ChatGPT 4o model
az cognitiveservices account deployment create -n $AI_SERVICE_NAME -g $RG_NAME `
    --deployment-name "gpt-4o" `
    --model-name "gpt-4o" `
    --model-version "2024-08-06" `
    --model-format OpenAI `
    --sku-capacity "150" `
    --sku-name "GlobalStandard"

$AZURE_OPENAI_ENDPOINT=$(az cognitiveservices account show -n $AI_SERVICE_NAME -g $RG_NAME --query properties.endpoint)
$AZURE_OPENAI_API_KEY=$(az cognitiveservices account keys list -n $AI_SERVICE_NAME -g $RG_NAME --query key1)

# write to file using UTF-8 encoding
$envFileContent = @"
AZURE_OPENAI_ENDPOINT=$AZURE_OPENAI_ENDPOINT
AZURE_OPENAI_API_KEY=$AZURE_OPENAI_API_KEY
AZURE_OPENAI_CHATGPT_DEPLOYMENT="gpt-4o"
AZURE_OPENAI_API_VERSION="2024-08-06"
"@

Set-Content -Path ./streamlit-app/.env -Value $envFileContent -Encoding UTF8
