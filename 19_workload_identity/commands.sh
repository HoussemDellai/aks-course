# source: https://azure.github.io/azure-workload-identity/docs/quick-start.html

# only for the preview feature
az feature register --name EnableOIDCIssuerPreview --namespace Microsoft.ContainerService
az extension add --name aks-preview

az group create -n rg-aks-cluster -l westeurope
az aks create --resource-group rg-aks-cluster --name aks-cluster --generate-ssh-keys

# enable OIDC Issuer in the cluster
az aks update -g rg-aks-cluster -n aks-cluster --enable-oidc-issuer
az aks show --resource-group rg-aks-cluster --name aks-cluster --query "oidcIssuerProfile.issuerUrl" -otsv

# environment variables for the Azure Key Vault resource
export KEYVAULT_NAME="keyvaultakswi"
export KEYVAULT_SECRET_NAME="my-secret"
export RESOURCE_GROUP="rg-aks-cluster"
export LOCATION="westeurope"

# environment variables for the AAD application
export APPLICATION_NAME="workload-identity-aks"

# environment variables for the Kubernetes service account & federated identity credential
export SERVICE_ACCOUNT_NAMESPACE="default"
export SERVICE_ACCOUNT_NAME="workload-identity-sa"
export SERVICE_ACCOUNT_ISSUER="$(az aks show --resource-group rg-aks-cluster --name aks-cluster --query "oidcIssuerProfile.issuerUrl" -otsv)"

# Create an Azure Key Vault:
az keyvault create --resource-group "${RESOURCE_GROUP}" \
   --location "${LOCATION}" \
   --name "${KEYVAULT_NAME}"

# Create a secret:
az keyvault secret set --vault-name "${KEYVAULT_NAME}" \
   --name "${KEYVAULT_SECRET_NAME}" \
   --value "Hello\!"

# Create an AAD application and grant permissions to access the secret:
az ad sp create-for-rbac --name "${APPLICATION_NAME}"

# Set access policy for the AAD application to access the keyvault secret:
export APPLICATION_CLIENT_ID="$(az ad sp list --display-name "${APPLICATION_NAME}" --query '[0].appId' -otsv)"
az keyvault set-policy --name "${KEYVAULT_NAME}" \
  --secret-permissions get \
  --spn "${APPLICATION_CLIENT_ID}"

# 5. Create a Kubernetes service account
# Create a Kubernetes service account and annotate it with the client ID of the AAD application 
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${APPLICATION_CLIENT_ID}
  labels:
    azure.workload.identity/use: "true"
  name: ${SERVICE_ACCOUNT_NAME}
  namespace: ${SERVICE_ACCOUNT_NAMESPACE}
EOF

# 6. Establish federated identity credential between the AAD application and the service account issuer & subject
# Get the object ID of the AAD application
export APPLICATION_OBJECT_ID="$(az ad app show --id ${APPLICATION_CLIENT_ID} --query objectId -otsv)"

# Add the federated identity credential:
cat <<EOF > body.json
{
  "name": "kubernetes-federated-credential",
  "issuer": "${SERVICE_ACCOUNT_ISSUER}",
  "subject": "system:serviceaccount:${SERVICE_ACCOUNT_NAMESPACE}:${SERVICE_ACCOUNT_NAME}",
  "description": "Kubernetes service account federated credential",
  "audiences": [
    "api://AzureADTokenExchange"
  ]
}
EOF

az rest --method POST --uri "https://graph.microsoft.com/beta/applications/${APPLICATION_OBJECT_ID}/federatedIdentityCredentials" --body @body.json

# 7. Deploy workload
# Deploy a pod that references the service account created in the last step:
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: quick-start
  namespace: ${SERVICE_ACCOUNT_NAMESPACE}
spec:
  serviceAccountName: ${SERVICE_ACCOUNT_NAME}
  containers:
    - image: ghcr.io/azure/azure-workload-identity/msal-go:latest
      name: oidc
      env:
      - name: KEYVAULT_NAME
        value: ${KEYVAULT_NAME}
      - name: SECRET_NAME
        value: ${KEYVAULT_SECRET_NAME}
  nodeSelector:
    kubernetes.io/os: linux
EOF

# To check whether all properties are injected properly by the webhook:
kubectl describe pod quick-start

kubectl logs quick-start

# 8. Cleanup
kubectl delete pod quick-start
kubectl delete sa "${SERVICE_ACCOUNT_NAME}" --namespace "${SERVICE_ACCOUNT_NAMESPACE}"

az group delete --name "${RESOURCE_GROUP}"
az ad sp delete --id "${APPLICATION_CLIENT_ID}"
