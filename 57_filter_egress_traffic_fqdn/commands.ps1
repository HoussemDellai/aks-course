## Restrict Egress/Outbound Layer 7 traffic using Cilium Network Policy

## 1. Create demo environment

$RG_NAME="rg-aks-cluster-cilium"
$AKS_NAME="aks-cluster-cilium"

az group create -n $RG_NAME -l westeurope
az aks create -n $AKS_NAME -g $RG_NAME --network-plugin none

az aks get-credentials -n $AKS_NAME -g $RG_NAME --overwrite-existing

helm repo add cilium https://helm.cilium.io/

helm upgrade --install cilium cilium/cilium --version 1.14.2 `
  --namespace kube-system `
  --set aksbyocni.enabled=true `
  --set nodeinit.enabled=true `
  --set sctp.enabled=true `
  --set hubble.enabled=true `
  --set hubble.metrics.enabled="{dns,drop,tcp,flow,icmp,http}" `
  --set hubble.relay.enabled=true `
  --set hubble.ui.enabled=true `
  --set hubble.ui.service.type=NodePort `
  --set hubble.relay.service.type=NodePort
  # --set gatewayAPI.enabled=true

# Restart unmanaged Pods (required by new Cilium install)
kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xaRG_NAMEs -L 1 -r kubectl delete pod

# make sure cilium CLI is installed on your machine (https://github.com/cilium/cilium-cli/releases/tag/v0.15.0)
cilium version --client

# make sure cilium CLI is installed on aks cluster
cilium status --wait

# validate that your cluster has proper network connectivity
cilium connectivity test

# deploy sample online service, just to get public IP
$FQDN=(az container create -g $RG_NAME -n aci-app --image nginx:latest --ports 80  --ip-address public --dns-name-label aci-app-931 --query ipAddress.fqdn --output tsv)
$FQDN
# aci-app-931.westeurope.azurecontainer.io

## 2. Deploy Network Policy to deny all traffic

kubectl apply -f deny-all.yaml

kubectl get networkpolicy
# NAME               POD-SELECTOR   AGE
# default-deny-all   <none>         160m

# access the external service FQDN from nginx pod
kubectl run nginx --image=nginx
kubectl exec -it nginx -- curl http://$FQDN --max-time 5 
# curl: (6) Could not resolve host: aci-app-931.westeurope.azurecontainer.io
# access denied

# allow access to external service FQDN
# replace FQDN in allow-egress-fqdn.yaml with the FQDN of the external service and pod labels
kubectl apply -f allow-egress-fqdn.yaml

kubectl get ciliumnetworkpolicy
# NAME                AGE
# allow-egress-fqdn   4m50s

kubectl exec -it nginx -- curl http://$FQDN --max-time 5
# <title>Welcome to nginx!</title>

kubectl exec -it nginx -- curl http://api.github.com --max-time 5
# success

kubectl exec -it nginx -- curl http://api.twitter.com --max-time 5
# curl: (28) Connection timed out after 5000 milliseconds

# verify that egress traffic to external FQDN is blocked to other pods with different labels
kubectl run nginx1 --image=nginx

kubectl exec -it nginx1 -- curl http://$FQDN --max-time 5
# curl: (28) Resolving timed out after 5000 milliseconds

## 3. Logging the dropped traffic

# get nginx pod node name
kubectl get pods -o wide

# get Cilium pods
kubectl get pods -n kube-system -l k8s-app=cilium -o wide

# view dropped traffic by Cilium
kubectl -n kube-system exec -it cilium-hjb8l -- cilium monitor --type drop 
# xx drop (Policy denied) flow 0xe7142f72 to endpoint 0, ifindex 32, file bpf_lxc.c:1276, , identity 9655->world: 10.0.1.51:60738 -> 104.244.42.66:80 tcp SYN

## 3. Exploring Hubble UI

# open Hubble UI
cilium hubble ui
# ℹ️  Opening "http://localhost:12000" in your browser...

## Cleanup resources
az group delete --name $RG_NAME --yes --no-wait

## Resources
# https://docs.cilium.io/en/stable/installation/k8s-install-helm/


# Deny policies take precedence over allow policies, 
# regardless of whether they are a Cilium Network Policy, a Clusterwide Cilium Network Policy or even a Kubernetes Network Policy.

# Deny policies do not support: policy enforcement at L7, i.e., specifically denying an URL and toFQDNs, i.e., specifically denying traffic to a specific domain name.