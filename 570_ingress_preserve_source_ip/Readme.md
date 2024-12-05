# Preserving the IP address of the client

## Introduction

In this section, you will learn how to preserve the IP address of the client when using an Ingress Controller. This is useful when you need to know the client's IP address in your application.
By deafault, the LoadBalancer service type uses the Azure Standard Load Balancer, which does not preserve the client's IP address. Instead, it replaces it with the IP address of the Load Balancer. To preserve the client's IP address, you need to apply the following spec to the Nginx Ingress Controller service:

```yaml
spec.externalTrafficPolicy: Local
```

This way the original IP address of the client will be carried by the headers: `X-Forwarded-For` and `X-Real-IP`.

Here is a step-by-step guide to demonstrate how to preserve the client's IP address.

```sh
# create an AKS cluster
$AKS_RG="rg-aks-cluster"
$AKS_NAME="aks-cluster"

az group create -n $AKS_RG -l swedencentral

az aks create -g $AKS_RG -n $AKS_NAME --network-plugin azure --network-plugin-mode overlay

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

# verify connection to the cluster
kubectl get nodes

# install Nginx ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

NAMESPACE_INGRESS="ingress-nginx"

helm install ingress-nginx ingress-nginx/ingress-nginx `
     --create-namespace `
     --namespace $NAMESPACE_INGRESS `
     --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz `
     --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-port"=80 

kubectl get pods,deployments,services --namespace $NAMESPACE_INGRESS

$INGRESS_PUPLIC_IP=$(kubectl get services ingress-nginx-controller -n $NAMESPACE_INGRESS -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $INGRESS_PUPLIC_IP
# 20.103.25.154

kubectl apply -f app.yaml

curl $INGRESS_PUPLIC_IP

# check the "X-Forwarded-For" header in the response. It should contain the SNAT'd IP address of the client, which become the IP address of the node/vm.

# Enable "externalTrafficPolicy: Local" in the ingress controller service

kubectl patch svc ingress-nginx-controller -n $NAMESPACE_INGRESS -p '{\"spec\":{\"externalTrafficPolicy\":\"Local\"}}'

# use the following if using Linux
# kubectl patch svc ingress-nginx-controller -n $NAMESPACE_INGRESS -p '{"spec":{"externalTrafficPolicy":"Local"}}'

curl $INGRESS_PUPLIC_IP

# check the "X-Forwarded-For" and "X-Real-IP" headers in the response. They should contain the original client IP address.
```

## More resources

https://kubernetes.io/docs/tutorials/services/source-ip/
https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip