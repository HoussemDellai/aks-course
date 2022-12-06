# Worksload Identity with AKS

```bash
# environment variables for the Azure Key Vault resource
export AKS_NAME="aks-cluster"
export KEYVAULT_NAME="azwi-kv-demo-013"
export KEYVAULT_SECRET_NAME="my-secret"
export RESOURCE_GROUP="aks-wi-oidc"
export LOCATION="westcentralus"

# environment variables for the Kubernetes Service account & federated identity credential
export SERVICE_ACCOUNT_NAMESPACE="default"
export SERVICE_ACCOUNT_NAME="workload-identity-sa"

# environment variables for the Federated Identity
export SUBSCRIPTION="{your subscription ID}"
# user assigned identity name
export UAID="fic-test-ua"
# federated identity name
export FICID="fic-test-fic-name"
```

```bash
# create resource group and AKS clsuter with OIDC and Workload Identity enabled
az group create --name ${RESOURCE_GROUP} --location ${LOCATION}
az aks create -g ${RESOURCE_GROUP} -n ${AKS_NAME} \
              --node-count 1 \
              --generate-ssh-keys \
              --enable-oidc-issuer \
              --enable-workload-identity
```

```bash
# get the OIDC Issuer URL
export AKS_OIDC_ISSUER="$(az aks show -n ${AKS_NAME} -g ${RESOURCE_GROUP} --query "oidcIssuerProfile.issuerUrl" -otsv)"
echo "${AKS_OIDC_ISSUER}"
```

```bash
# create user assigned managed identity
az identity create --name "${UAID}" --resource-group "${RESOURCE_GROUP}" \
                   --location "${LOCATION}" \
                   --subscription "${SUBSCRIPTION}"

export USER_ASSIGNED_CLIENT_ID="$(az identity show --resource-group ${RESOURCE_GROUP} --name ${UAID} --query 'clientId' -otsv)"
```

```bash
# create keyvault and secret
az keyvault create --resource-group ${RESOURCE_GROUP} --location ${LOCATION} --name ${KEYVAULT_NAME}
az keyvault secret set --vault-name ${KEYVAULT_NAME} --name ${KEYVAULT_SECRET_NAME} --value 'Hello!'
```

```bash
# give managed identity access to key vault secrets
az keyvault set-policy --name "${KEYVAULT_NAME}" --secret-permissions get --spn "${USER_ASSIGNED_CLIENT_ID}"
```

```bash
# connect to the AKS cluster
az aks get-credentials -n "${AKS_NAME}" -g "${RESOURCE_GROUP}"

# create a Kubernetes service account and annotate it with the client ID of the Managed Identity
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${USER_ASSIGNED_CLIENT_ID}
  labels:
    azure.workload.identity/use: "true"
  name: ${SERVICE_ACCOUNT_NAME}
  namespace: ${SERVICE_ACCOUNT_NAMESPACE}
EOF
```

```bash
# Use the az identity federated-credential create command to create the federated identity credential 
# between the managed identity, the service account issuer, and the subject.
az identity federated-credential create --name ${FICID} --identity-name ${UAID} \
            --resource-group ${RESOURCE_GROUP} \
            --issuer ${AKS_OIDC_ISSUER} \
            --subject system:serviceaccount:${SERVICE_ACCOUNT_NAMESPACE}:${SERVICE_ACCOUNT_NAME}
# wait few minutes for the federation to propagate...
```

```bash
# deploy a pod that references the service account
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: quick-start
  namespace: ${SERVICE_ACCOUNT_NAMESPACE}
spec:
  serviceAccountName: ${SERVICE_ACCOUNT_NAME}
  containers:
    - image: ghcr.io/azure/azure-workload-identity/msal-go
      name: oidc
      env:
      - name: KEYVAULT_URL
        value: ${KEYVAULT_NAME}
      - name: SECRET_NAME
        value: ${KEYVAULT_SECRET_NAME}
  nodeSelector:
    kubernetes.io/os: linux
EOF
```
# Note: Newer version of the sample image will only need KEYVAULT_URL variable.

```bash
kubectl describe pod quick-start
kubectl logs quick-start
# outputs: "successfully got secret" secret="Hello!"
```

```bash
# cleanup resources
kubectl delete pod quick-start
kubectl delete sa "${SERVICE_ACCOUNT_NAME}" --namespace "${SERVICE_ACCOUNT_NAMESPACE}"
az group delete --name "${RESOURCE_GROUP}"
```
