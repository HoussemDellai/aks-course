$RG="rg-aks-ml"
$AKS_NAME="aks-cluster"
$LOCATION="westeurope"
$AKS_VERSION="1.27.3" # "1.28.0"
$AML_NAMESPACE="aml-workspace"

# Create the resource group
az group create --name $RG --location $LOCATION

# Create the AKS cluster
az aks create -n $AKS_NAME -g $RG --kubernetes-version $AKS_VERSION --network-plugin azure

# Get the AKS cluster credentials
az aks get-credentials -n $AKS_NAME -g $RG --overwrite-existing

# Connect to cluster
kubelogin convert-kubeconfig -l azurecli

# Create a namespace for the Azure Machine Learning deployment
kubectl create namespace azureml

# Create extension instance
# Create a new extension instance with k8s-extension create, passing in values for the mandatory parameters. This example command creates an Azure Machine Learning extension instance on your AKS cluster:

az extension update --name k8s-extension

az k8s-extension create --name azureml `
   --extension-type Microsoft.AzureML.Kubernetes `
   --scope cluster `
   --cluster-name $AKS_NAME `
   --resource-group $RG `
   --cluster-type managedClusters `
   --configuration-settings enableTraining=True internalLoadBalancerProvider=azure enableInference=True allowInsecureConnections=True inferenceRouterServiceType=LoadBalancer




az ml registry create --resource-group $RG --name acraml13579