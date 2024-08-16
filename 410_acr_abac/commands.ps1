$RG_NAME = "rg-aks-acr-abac"
$ACR_NAME = "acrabac"
$AKS_NAME = "aks-cluster"
$ACA_FRONTEND_NAME = "aca-frontend"
$ACA_BACKEND_NAME = "aca-backend"


az acr create -n $ACR_NAME -g $RG_NAME --sku Basic --admin-enabled true

az acr update -n $ACR_NAME -g $RG_NAME --role-assignment-mode AbacRepositoryPermissions

az acr import -n $ACR_NAME --source docker.io/library/nginx:latest -t acrabac.azurecr.io/frontend/nginx:latest
az acr import -n $ACR_NAME --source docker.io/library/nginx:latest -t acrabac.azurecr.io/backend/nginx:latest

# create a  Container App

