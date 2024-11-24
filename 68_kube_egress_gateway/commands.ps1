$AKS_NAME = "aks-cluster"
$AKS_RG = "rg-aks-cluster-egress-gateway"
$NODEPOOL_NAME = "npegress"
$GW_PREFIX_SIZE = 30

az group create --name $AKS_RG --location swedencentral

az aks create -g $AKS_RG -n $AKS_NAME --enable-static-egress-gateway --network-plugin azure --network-plugin-mode overlay -k 1.30.5 --node-vm-size standard_d2pds_v6 --vm-set-type VirtualMachineScaleSets

az aks get-credentials -g $AKS_RG -n $AKS_NAME --overwrite-existing

# check default egress IP
# that is load balancer's outbound IP
kubectl run nginx --image=nginx
kubectl exec nginx -it -- curl ifconf.me
# 74.241.184.101

az aks nodepool add -g $AKS_RG --cluster-name $AKS_NAME --name $NODEPOOL_NAME --mode gateway --node-count 2 --gateway-prefix-size $GW_PREFIX_SIZE --node-vm-size standard_d2pds_v6

# create public IP prefix

az network public-ip prefix create -g $AKS_RG -n pip-prefix-egress --length $GW_PREFIX_SIZE
# get prefix
az network public-ip prefix show -g $AKS_RG -n pip-prefix-egress --query ipPrefix -o tsv
$IP_PREFIX_ID=$(az network public-ip prefix show -g $AKS_RG -n pip-prefix-egress --query id -o tsv)
echo $IP_PREFIX_ID

@"
apiVersion: egressgateway.kubernetes.azure.com/v1alpha1
kind: StaticGatewayConfiguration
metadata:
  name: my-static-egress-gateway
  namespace: default
spec:
  gatewayNodepoolName: $NODEPOOL_NAME
  publicIpPrefixId: $IP_PREFIX_ID
  excludeCidrs:  # Optional
  - 10.0.0.0/8
  - 172.16.0.0/12
  - 169.254.169.254/32
"@ > static_gateway_config.yaml

# grant "Network Contributor" role to AKS cluster's identity

$AKS_PRINCIPAL_ID=$(az aks show -g $AKS_RG -n $AKS_NAME --query identity.principalId -o tsv)

az role assignment create --role "Network Contributor" --assignee $AKS_PRINCIPAL_ID --scope $IP_PREFIX_ID

kubectl apply -f static_gateway_config.yaml

kubectl get staticgatewayconfigurations my-static-egress-gateway -n default -o yaml

kubectl apply -f nginx-deployment.yaml

kubectl get pods

kubectl exec <pod name> -it -- curl ifconfig.me

# test private IP

az aks nodepool add -g $AKS_RG --cluster-name $AKS_NAME --name npegresspr --mode gateway --node-count 2 --gateway-prefix-size $GW_PREFIX_SIZE --node-vm-size standard_d2pds_v6

kubectl apply -f static_gateway_config_private.yaml