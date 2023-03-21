# Encrypting Pod to Pod communication using TLS certificates with Cert Manager and Let's Encrypt

# 1. Create an AKS cluster

$AKS_RG="rg-aks-cluster"
$AKS_NAME="aks-cluster"

az group create -n $AKS_RG -l westeurope

az aks create -g $AKS_RG -n $AKS_NAME `
              --kubernetes-version "1.25.5" `
              --node-count 2 `
              --network-plugin azure

# Connect to the cluster

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes

# 2. Install Cert Manager

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io

# Update your local Helm chart repository cache
helm repo update

# Install the cert-manager Helm chart
helm upgrade cert-manager jetstack/cert-manager `
             --install `
             --create-namespace `
             --namespace cert-manager `
             --set installCRDs=true `
             --set nodeSelector."kubernetes\.io/os"=linux
             Release "cert-manager" does not exist. Installing it now.

# You can view some of the resources that have been installed as follows:
kubectl -n cert-manager get all

# 3. Create a test ClusterIssuer and a Certificate

kubectl apply -f clusterissuer-selfsigned.yaml

kubectl apply -f .\certificate.yaml

kubectl get certificate,secret,ClusterIssuer

kubectl describe secret app01-tls-cert-secret

# 4. Create a deployment with TLS certificate

kubectl apply -f app-deploy-svc.yaml

# 5. Verify the TLS configuration

kubectl run nginx --image=nginx
kubectl exec -it nginx -- curl --insecure https://app01.default.svc.cluster.local

kubectl exec -it nginx -- curl --insecure -v https://app01.default.svc.cluster.local