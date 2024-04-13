$AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
$AZURE_RESOURCE_GROUP="rg-kaito"
$AZURE_LOCATION="swedencentral"
$CLUSTER_NAME="aks-cluster"

az group create --name $AZURE_RESOURCE_GROUP --location $AZURE_LOCATION

az aks create -g $AZURE_RESOURCE_GROUP -n $CLUSTER_NAME --enable-oidc-issuer --enable-ai-toolchain-operator

az aks get-credentials -g $AZURE_RESOURCE_GROUP -n $CLUSTER_NAME --overwrite-existing

kubectl get nodes

$MC_RESOURCE_GROUP=$(az aks show --resource-group $AZURE_RESOURCE_GROUP --name $CLUSTER_NAME --query nodeResourceGroup -o tsv)
$PRINCIPAL_ID=$(az identity show --name ai-toolchain-operator-$CLUSTER_NAME --resource-group $MC_RESOURCE_GROUP --query 'principalId' -o tsv)
$KAITO_IDENTITY_NAME="ai-toolchain-operator-$CLUSTER_NAME"


# Get the AKS OpenID Connect (OIDC) Issuer URL
$AKS_OIDC_ISSUER=$(az aks show --resource-group "${AZURE_RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --query "oidcIssuerProfile.issuerUrl" -o tsv)

# Get the AKS OpenID Connect (OIDC) Issuer
$AKS_OIDC_ISSUER=$(az aks show --resource-group $AZURE_RESOURCE_GROUP --name $CLUSTER_NAME --query "oidcIssuerProfile.issuerUrl" -o tsv)

# Create role assignment for the service principal
az role assignment create --role "Contributor" --assignee $PRINCIPAL_ID --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourcegroups/$AZURE_RESOURCE_GROUP"

# Establish a federated identity credential
az identity federated-credential create --name "kaito-federated-identity" --identity-name "${KAITO_IDENTITY_NAME}" -g "${MC_RESOURCE_GROUP}" --issuer "${AKS_OIDC_ISSUER}" --subject system:serviceaccount:"kube-system:kaito-gpu-provisioner" --audience api://AzureADTokenExchange

# Restart the KAITO GPU provisioner deployment on your pods using the kubectl rollout restart command
kubectl rollout restart deployment/kaito-gpu-provisioner -n kube-system

kubectl get deployment -n kube-system | grep kaito

# Deploy the Falcon 7B-instruct model from the KAITO model repository using the kubectl apply command.
kubectl apply -f https://raw.githubusercontent.com/Azure/kaito/main/examples/kaito_workspace_falcon_7b-instruct.yaml

kubectl get workspace workspace-falcon-7b-instruct -w