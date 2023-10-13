## Restrict Egress/Outbound Layer 3 traffic using Calico Network Policy

## 1. Create demo environment

$RG_NAME = "rg-aks-cluster-calico"
$AKS_NAME = "aks-cluster-calico"

# create an azure rsource group
az group create -n $RG_NAME --location westeurope

# create AKS cluster with Calico enabled
az aks create -g $RG_NAME -n $AKS_NAME --network-plugin azure --network-policy calico

# get AKS credentials
az aks get-credentials -g $RG_NAME -n $AKS_NAME --overwrite-existing

# deploy sample online service, just to get public IP
$EXTERNAL_IP=(az container create -g $RG_NAME -n aci-app --image nginx:latest --ports 80  --ip-address public --query ipAddress.ip --output tsv)
$EXTERNAL_IP
# 20.76.101.193

# deploy nginx pod
kubectl run nginx --image=nginx

# access the external service from nginx pod
kubectl exec -it nginx -- curl http://$EXTERNAL_IP
# <title>Welcome to nginx!</title>
# access is allowed

## 2. Restrict all ingress and egress traffic

# deny all ingress and egress traffic
kubectl apply -f deny-all.yaml

kubectl exec -it nginx -- curl http://$EXTERNAL_IP --max-time 5
# timeout

## 3. Allow egress traffic to external service IP address

# get pods with labels
kubectl get pods --show-labels

# replace IP address in allow-egress-ip.yaml with the IP address of the external service and pod labels

# allow egress traffic to external service IP address
# replace IP address in allow-egress-ip.yaml with the IP address of the external service and pod labels
kubectl apply -f allow-egress-ip.yaml

# access the external service from nginx pod
kubectl exec -it nginx -- curl http://$EXTERNAL_IP
# <title>Welcome to nginx!</title>

## 4. Verify that egress traffic to external IP is blocked to other pods

# verify with another pod with different labels
kubectl run nginx1 --image=nginx

kubectl exec -it nginx1 -- curl http://$EXTERNAL_IP --max-time 5
# access denied

## 5. Logging denied traffic

# Calico enables logging denied and allowed traffic to syslog
# you need to use the Calico Network Policy instead of Kubernetes Network Policy
# you need to install Calico API Server to deploy Calico Network Policy using kubectl instead of calicoctl
# Src: https://docs.tigera.io/calico/latest/operations/install-apiserver

kubectl apply -f calico-apiserver.yaml
# apiserver.operator.tigera.io/default created

kubectl get tigerastatus apiserver
# NAME        AVAILABLE   PROGRESSING   DEGRADED   SINCE
# apiserver   True        False         False      119s

# deploy Calico Network Policy that denies egress traffic en logs it to syslog

# Once the API server has been installed, you can use kubectl to interact with the Calico APIs.

# deploy calico network policy to enable logging

kubectl apply -f logging-traffic.yaml



az aks enable-addons -a monitoring --enable-syslog -g $RG_NAME -n $AKS_NAME

kubectl exec -it nginx1 -- curl http://$EXTERNAL_IP --max-time 5

# check generated logs in Log Analytics
# run this KQL query:
# Syslog 
# | project TimeGenerated, SyslogMessage
# | where SyslogMessage has "20.126.233.217"
# // | where SyslogMessage has "calico-packet"