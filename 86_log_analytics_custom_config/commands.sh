# Enabling logging in kube-system namespace

# create an AKS cluster

$AKS_RG="rg-aks-cluster-log-analytics"
$AKS_NAME="aks-cluster"

az group create --name $AKS_RG --location westeurope

az aks create -g $AKS_RG -n $AKS_NAME --network-plugin azure --node-vm-size "Standard_B2als_v2" --enable-addons monitoring

az aks get-credentials -g $AKS_RG -n $AKS_NAME --overwrite-existing

# check log analytics pods called ama-logs

kubectl get pods -n kube-system -l component=ama-logs-agent

# check logs from kube-system namespace

kubectl get pods -n kube-system

kubectl logs -n kube-system -l k8s-app=kube-dns

# check logs from kube-system namespace in Log Analytics

# check the configuration of the log analytics agent

kubectl get configmap container-azm-ms-aks-k8scluster -n kube-system -o yaml

kubectl get configmap container-azm-ms-agentconfig -n kube-system -o yaml

# apply custom configuration for the log analytics agent

# sample configuration file: https://raw.githubusercontent.com/microsoft/Docker-Provider/ci_prod/kubernetes/container-azm-ms-agentconfig.yaml

# remove "kube-system" from the list of excluded namespaces

# apply the new configuration

kubectl apply -f container-azm-ms-agentconfig.yaml

# Then all Azure Monitor Agent pods in the cluster will restart. 
# The restart is a rolling restart for all Azure Monitor Agent pods, so not all of them restart at the same time.

kubectl get pods -n kube-system -l component=ama-logs-agent

# check the logs from kube-system namespace in Log Analytics

