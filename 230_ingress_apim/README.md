# Exposing AKS applications using API Management

## Introduction

Mutual TLS authentication is natively supported by API Management and can be enabled in Kubernetes by installing an Ingress Controller. As a result, authentication will be performed in the Ingress Controller, which simplifies the microservices. Additionally, you can add the IP addresses of API Management to the allowed list by Ingress to make sure only API Management has access to the cluster.

![architecture](images/architecture.png)

Pros:

- Easy configuration on the API Management side because it doesn't need to be injected into the cluster VNet and mTLS is natively supported
- Centralizes protection for inbound cluster traffic at the Ingress Controller layer
- Reduces security risk by minimizing publicly visible cluster endpoints

Cons:

- Increases complexity of cluster configuration due to extra work to install, configure and maintain the Ingress Controller and manage certificates used for mTLS
- Security risk due to public visibility of Ingress Controller endpoint(s)

When you publish APIs through API Management, it's easy and common to secure access to those APIs by using subscription keys. Developers who need to consume the published APIs must include a valid subscription key in HTTP requests when they make calls to those APIs. Otherwise, the calls are rejected immediately by the API Management gateway. They aren't forwarded to the back-end services.

To get a subscription key for accessing APIs, a subscription is required. A subscription is essentially a named container for a pair of subscription keys. Developers who need to consume the published APIs can get subscriptions. And they don't need approval from API publishers. API publishers can also create subscriptions directly for API consumers.

Official documentation here: https://learn.microsoft.com/en-us/azure/api-management/api-management-kubernetes

## Lab: Exposing AKS applications using API Management

In this lab, you will learn how to expose an AKS application using API Management. You will go through the following steps:

1. Deploy an AKS cluster
2. Deploy an internal Nginx Ingress Controller to the AKS cluster
3. Deploy an application to the cluster
4. Deploy an API Management instance
5. Expose the application using API Management

### Deploying the resources

You will use `terraform` to deploy the resources.

To deploy the resources, run the following commands from the `terraform` directory:

```sh
cd terraform
terraform init
terraform apply -auto-approve
```

This will take about 22 minutes to complete.
The following resources will be deployed: ![](images/resources.png)

Then, you will need to deploy an `ingress controller` like `nginx` to the AKS cluster. To do this, run the following commands:

```sh
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --version 4.11.0 \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"=true \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz

kubectl get pods,deployments,services --namespace ingress-nginx

kubectl get services ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

> Note how we are using the static IP address `10.10.0.7` for the Ingress Controller. This IP will be used to configure the API Management API backend.

After that, you will need to deploy an application to the AKS cluster. To do this, run the following commands from the `kubernetes` directory:

```sh
kubectl apply -f app.yaml
```

The application should be exposed using the Ingress Controller.

```sh
kubectl run nginx --image=nginx
# pod/nginx created
root@nginx:/# curl 10.10.0.10/albums
[{"id":1,"title":"You, Me and an App Id","artist":"Daprize","price":10.99,"image_url":"https://aka.ms/albums-daprlogo"},{"id":2,"title":"Seven Revision Army","artist":"The Blue-Green Stripes","price":13.99,"image_url":"https://aka.ms/albums-containerappslogo"},{"id":3,"title":"Scale It Up","artist":"KEDA Club","price":13.99,"image_url":"https://aka.ms/albums-kedalogo"},{"id":4,"title":"Lost in Translation","artist":"MegaDNS","price":12.99,"image_url":"https://aka.ms/albums-envoylogo"},{"id":5,"title":"Lock Down Your Love","artist":"V is for VNET","price":12.99,"image_url":"https://aka.ms/albums-vnetlogo"},{"id":6,"title":"Sweet Container O' Mine","artist":"Guns N Probeses","price":14.99,"image_url":"https://aka.ms/albums-containerappslogo"}]
```

Now you