# Demo for scaling Pods in AKS based on number of messages in a Queue (Azure Service Bus) using Keda.
# https://keda.sh/

# install KEDA in Kubernetes using Helm Charts
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
kubectl create namespace keda
helm install keda kedacore/keda --namespace keda

# create Azure Service Bus and Queue
$RG="rg-keda"
$LOCATION="westeurope"
$SERVICEBUS_NAMESPACE="servicebus-keda-aks-01" # should be unique
$QUEUE="my-queue"
$AUTH_RULE="keda-aks-01"

# create Azure Resource Group
az group create --name $RG --location $LOCATION

# Create Azure Service Bus Namespace
az servicebus namespace create --resource-group $RG --name $SERVICEBUS_NAMESPACE --location $LOCATION

# Create Queue
az servicebus queue create --resource-group $RG --namespace-name $SERVICEBUS_NAMESPACE --name $QUEUE

# create Authorisation Rule for the Queue
az servicebus queue authorization-rule create --resource-group $RG --namespace-name $SERVICEBUS_NAMESPACE --queue-name $QUEUE --name $AUTH_RULE --rights Listen Manage Send

# list Authorisation Rule keys
az servicebus queue authorization-rule keys list --resource-group $RG --namespace-name $SERVICEBUS_NAMESPACE --queue-name $QUEUE --name $AUTH_RULE

# replace the primaryConnectionString in the YAML file 

# deploy the app
kubectl apply -f nginx-deploy.yaml
kubectl apply -f scaledObject.yaml

# watch the deployment number of pods
kubectl get deploy -w

# add and remove messages in the queue and watch the number of pods
