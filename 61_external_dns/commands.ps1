# External DNS for Azure DNS & AKS

# This tutorial describes how to setup ExternalDNS for Azure DNS with AKS.

# src: https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/azure.md

# 1. Setup environment

# create AKS cluster

$AKS_RG="rg-aks-cluster"
$AKS_NAME="aks-cluster"

az group create -n $AKS_RG -l westeurope

az aks create -g $AKS_RG -n $AKS_NAME `
              --kubernetes-version "1.25.5" `
              --node-count 3 `
              --network-plugin azure

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

# install nginx ingress controller

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx `
     --create-namespace `
     --namespace ingress-nginx `
     --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz

# 2. Create Azure DNS Zone, or use existing one

$DNS_ZONE_NAME="houssemd.com"
$DNS_ZONE_RG="rg-dns"

az group create -n $DNS_ZONE_RG -l westeurope

az network dns zone create -g $DNS_ZONE_RG -n $DNS_ZONE_NAME

# 3. Create a service principal for external DNS

$EXTERNALDNS_SPN_NAME="spn-external-dns-aks"

# Create the service principal
$DNS_SPN=$(az ad sp create-for-rbac --name $EXTERNALDNS_SPN_NAME)
$EXTERNALDNS_SPN_APP_ID=$(echo $DNS_SPN | jq -r '.appId')
$EXTERNALDNS_SPN_PASSWORD=$(echo $DNS_SPN | jq -r '.password')

# 4. Assign the RBAC for the service principal

# Grant access to Azure DNS zone for the service principal.

# fetch DNS id and RG used to grant access to the service principal
$DNS_ZONE_ID=$(az network dns zone show -n $DNS_ZONE_NAME -g $DNS_ZONE_RG --query "id" -o tsv)
$DNS_ZONE_RG_ID=$(az group show -g $DNS_ZONE_RG --query "id" -o tsv)

# assign reader to the resource group
az role assignment create --role "Reader" --assignee $EXTERNALDNS_SPN_APP_ID --scope $DNS_ZONE_RG_ID

# assign contributor to DNS Zone itself
az role assignment create --role "DNS Zone Contributor" --assignee $EXTERNALDNS_SPN_APP_ID --scope $DNS_ZONE_ID
# az role assignment create --role "Contributor" --assignee $EXTERNALDNS_SPN_APP_ID --scope $DNS_ID

# verify role assignments

az role assignment list --all --assignee $EXTERNALDNS_SPN_APP_ID -o table

# 5. Create a Kubernetes secret for the service principal

@"
{
  "tenantId": "$(az account show --query tenantId -o tsv)",
  "subscriptionId": "$(az account show --query id -o tsv)",
  "resourceGroup": "$DNS_ZONE_RG",
  "aadClientId": "$EXTERNALDNS_SPN_APP_ID",
  "aadClientSecret": "$EXTERNALDNS_SPN_PASSWORD"
}
"@ > azure.json

cat azure.json

kubectl create namespace external-dns

kubectl create secret generic azure-config-file -n external-dns --from-file azure.json

# verify secret created

kubectl describe secret azure-config-file -n external-dns

# 6. Deploy External DNS

# 6.1. Deploy using yaml file

# change the namespace name in ClusterRoleBinding in external-dns.yaml

kubectl apply -f external-dns.yaml -n external-dns

# 6.2. Deploy using Helm chart

# you can also use Helm charts to deploy External DNS
# https://artifacthub.io/packages/helm/bitnami/external-dns
# https://github.com/bitnami/charts/tree/main/bitnami/external-dns/#installing-the-chart
             

# verify deployment

kubectl get pods,sa,secret -n external-dns

# 7. Create a sample exposed through public load balancer

kubectl apply -f app-lb.yaml 

kubectl get pods,svc

# check what is happening in the external DNS pod

kubectl get pods -n external-dns
$POD_NAME=$(kubectl get pods -n external-dns -l app=external-dns -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME -n external-dns

# check the DNS record is created by external DNS

az network dns record-set a list -g $DNS_ZONE_RG --zone-name $DNS_ZONE_NAME

# 8. Create a sample exposed through ingress

kubectl apply -f app-ingress.yaml

kubectl get pods,svc,ingress

# check the DNS record is created by external DNS

az network dns record-set a list -g $DNS_ZONE_RG --zone-name $DNS_ZONE_NAME