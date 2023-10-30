## 0. Setup demo environment

# Variables
$AKS_RG="rg-aks-cluster"
$AKS_NAME="aks-cluster"
$EVENTGRID_NAMESPACE="eventgrid-aks-weu"
$EVENTGRID_HUB="eventgrid-aks-hub"
$EVENTGRID_SUBSCRIPTION="eventgrid-aks-sub"

# Create and connect to AKS cluster
az group create --name $AKS_RG --location westeurope

az aks create -n $AKS_NAME -g $AKS_RG --node-count 1

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

# Connect to cluster
kubelogin convert-kubeconfig -l azurecli

kubectl get nodes

# Create a namespace and event hub

az eventhubs namespace create --name $EVENTGRID_NAMESPACE -g $AKS_RG
az eventhubs eventhub create --name $EVENTGRID_HUB --namespace-name $EVENTGRID_NAMESPACE -g $AKS_RG

# Subscribe to the AKS events using az eventgrid event-subscription create:

$AKS_ID=$(az aks show -g $AKS_RG -n $AKS_NAME --query id --output tsv)
$ENDPOINT=$(az eventhubs eventhub show -g $AKS_RG -n $EVENTGRID_HUB --namespace-name $EVENTGRID_NAMESPACE --query id --output tsv)

az eventgrid event-subscription create --name $EVENTGRID_SUBSCRIPTION --source-resource-id $AKS_ID --endpoint-type eventhub --endpoint $ENDPOINT

# Verify your subscription to AKS events

az eventgrid event-subscription list --source-resource-id $AKS_ID

# trigger event by adding new nodepool

az aks nodepool add --name nodepool2 --cluster-name $AKS_NAME -g $AKS_RG --node-count 1

# get AKS cluster upgrades

az aks get-upgrades --name $AKS_NAME -g $AKS_RG -o table

# get first upgrade version

$UPGRADE_VERSION=$(az aks get-upgrades --name $AKS_NAME -g $AKS_RG --query controlPlaneProfile.upgrades[0].kubernetesVersion -o tsv)
$UPGRADE_VERSION

# upgrade AKS cluster, control plane only

az aks upgrade -n $AKS_NAME -g $AKS_RG --control-plane-only --kubernetes-version $UPGRADE_VERSION --yes

# upgrade node pool

az aks nodepool upgrade --cluster-name $AKS_NAME -g $AKS_RG --name nodepool1 --kubernetes-version $UPGRADE_VERSION --yes