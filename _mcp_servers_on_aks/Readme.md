# Running MCP Servers on AKS

This sample shows how to run MCP servers on Azure Kubernetes Service (AKS). It uses the Open-WebSearch.


## Creating an AKS cluster

Let's start by creating an AKS cluster in Azure. This cluster will be used to deploy and manage your applications.

```sh
az group create --name rg-aks-cluster --location swedencentral

az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay -k 1.34.3 --node-vm-size Standard_D2ads_v6 --os-sku Ubuntu --node-osdisk-type Ephemeral --node-osdisk-size 64 --enable-apiserver-vnet-integration

az aks get-credentials -n aks-cluster -g rg-aks-cluster --overwrite-existing
```

## Install KMCP Operator

### Install KMCP CRDs

Deploy the KMCP CustomResourceDefinitions using the published Helm chart so the cluster understands MCPServer resources.

```sh
helm upgrade --install kmcp-crds oci://ghcr.io/kagent-dev/kmcp/helm/kmcp-crds --namespace kmcp-system --create-namespace

helm upgrade --install "${KMCP_CRDS_RELEASE_NAME}" \
  oci://ghcr.io/kagent-dev/kmcp/helm/kmcp-crds \
  --namespace "${KMCP_NAMESPACE}" \
  --create-namespace
```

kubectl get crd | grep mcp || echo "MCP CRDs not detected"


Install KMCP controller
Install or upgrade the KMCP controller, which reconciles MCPServer resources by creating Deployments and Services for the MCP servers.

```sh
kmcp install ${KMCP_VERSION:+--version "${KMCP_VERSION}"} || true
kubectl get pods -n "${KMCP_NAMESPACE}"
```