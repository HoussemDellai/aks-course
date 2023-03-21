# source: https://docs.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-new

# create resource group
az group create --name rg-aks-cluster --location westeurope

# create Aan AKS cluster with AGIC enabled
# this will create a new App Gateway instance
az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --enable-managed-identity -a ingress-appgw --appgw-name myApplicationGateway --appgw-subnet-cidr "10.2.0.0/16" --generate-ssh-keys

# deploy a sample app: Pod + Service + Ingress
kubectl apply -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml
# pod/aspnetapp created
# service/aspnetapp created
# ingress.networking.k8s.io/aspnetapp created

# # # aspnetapp.yaml
# apiVersion: v1
# kind: Pod
# metadata:
#   name: aspnetapp
#   labels:
#     app: aspnetapp
# spec:
#   containers:
#   - image: "mcr.microsoft.com/dotnet/core/samples:aspnetapp"
#     name: aspnetapp-image
#     ports:
#     - containerPort: 80
#       protocol: TCP

# ---

# apiVersion: v1
# kind: Service
# metadata:
#   name: aspnetapp
# spec:
#   selector:
#     app: aspnetapp
#   ports:
#   - protocol: TCP
#     port: 80
#     targetPort: 80

# ---

# apiVersion: networking.k8s.io/v1
# kind: Ingress
# metadata:
#   name: aspnetapp
#   annotations:
#     kubernetes.io/ingress.class: azure/application-gateway
# spec:
#   rules:
#   - http:
#       paths:
#       - path: /
#         backend:
#           service:
#             name: aspnetapp
#             port:
#               number: 80
#         pathType: Exact

# Check that the application is reachable
kubectl get ingress
# NAME        CLASS    HOSTS   ADDRESS        PORTS   AGE
# aspnetapp   <none>   *       20.101.12.46   80      8s

# from the browser, navigate to the IP adress 20.101.12.46 to access the application.

# important notes:
# There are two ways to deploy AGIC for your AKS cluster. The first way is through Helm; the second is through AKS as an add-on.
# AGIC addon and Helm charts could be enabled or disabled on new and existing clusters.
# AGIC deployed via Helm supports ProhibitedTargets, which means AGIC can configure the Application Gateway specifically for AKS clusters without affecting other existing backends. AGIC add-on doesn't currently support this.
# Customers can only deploy one AGIC add-on per AKS cluster, and each AGIC add-on currently can only target one Application Gateway. 
# For deployments that require more than one AGIC per cluster or multiple AGICs targeting one Application Gateway, please continue to use AGIC deployed through Helm.
# App Gateway could be hosted within another resource group and another VNET (other than the AKS VNET).
# Source: https://docs.microsoft.com/en-us/azure/application-gateway/ingress-controller-overview#difference-between-helm-deployment-and-aks-add-on

# more resources:
https://azure.github.io/application-gateway-kubernetes-ingress