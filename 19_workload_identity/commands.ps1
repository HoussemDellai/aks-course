# Update an AKS cluster with OIDC Issuer
az aks update -n aks -g myResourceGroup --enable-oidc-issuer
# Output the OIDC issuer URL
az aks show --resource-group <resource_group> --name <cluster_name> --query "oidcIssuerProfile.issuerUrl" -otsv

# environment variables for the Azure Key Vault resource
$KEYVAULT_NAME="kvaksdemo"
$KEYVAULT_SECRET_NAME="secret-workload-identity"
$RESOURCE_GROUP="rg-aks-cluster"
$LOCATION="westeurope"

# environment variables for the AAD application
$APPLICATION_NAME="workload-identity-aks-cluster"

# environment variables for the Kubernetes service account & federated identity credential
$SERVICE_ACCOUNT_NAMESPACE="default"
$SERVICE_ACCOUNT_NAME="workload-identity-sa"
$SERVICE_ACCOUNT_ISSUER="https://oidc.prod-aks.azure.com/2e2163f5-68a6-4da8-94b9-1ae572255e67/" # see section 1.1 on how to get the service account issuer url

az ad sp create-for-rbac --name $APPLICATION_NAME
# The output includes credentials that you must protect. Be sure that you do not include these credentials in your code or check the credentials into your source control. For more information, see https://aka.ms/azadsp-cli
# {
#   "appId": "a539149e-7fc7-4239-b81e-c0361ebb79bf",
#   "displayName": "workload-identity-aks-cluster",
#   "password": "2hFgGj7Ojwl~FPQGOCqc8Pz09ZC~_MYtmr",
#   "tenant": "72f988bf-86f1-41af-91ab-2d7cd011db47"
# }

$APPLICATION_CLIENT_ID="<appId>"

$sa=@"
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: $APPLICATION_CLIENT_ID
  labels:
    azure.workload.identity/use: "true"
  name: $SERVICE_ACCOUNT_NAME
  namespace: $SERVICE_ACCOUNT_NAMESPACE
"@

$sa | kubectl apply -f -

$APPLICATION_OBJECT_ID="$(az ad app show --id $APPLICATION_CLIENT_ID --query objectId -o tsv)"

$body=@"
{
  "name": "kubernetes-federated-credential",
  "issuer": $SERVICE_ACCOUNT_ISSUER,
  "subject": "system:serviceaccount:${SERVICE_ACCOUNT_NAMESPACE}:${SERVICE_ACCOUNT_NAME}",
  "description": "Kubernetes service account federated credential",
  "audiences": [
    "api://AzureADTokenExchange"
  ]
}"@

$body > body.json

az rest --method POST --uri "https://graph.microsoft.com/beta/applications/${APPLICATION_OBJECT_ID}/federatedIdentityCredentials" --body @body.json
