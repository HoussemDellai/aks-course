# Testing websockets with Azure Application Gateway and AKS

This repository contains a sample application and configuration for testing WebSocket support with Azure Application Gateway and Azure Kubernetes Service (AKS). The sample application is a simple WebSocket echo server that can be deployed to AKS, and the Application Gateway is configured to route WebSocket traffic to the AKS cluster.

## Instructions

1. Deploy the AKS cluster and Application Gateway using the provided Terraform configuration in the `08_aks_terraform` directory.

2. Build and push the WebSocket echo server Docker image to ACR

```sh
# Build the Docker image
az acr build --registry acr4aks08 --image websocket-echo-server:1.0.0 ./server
```

3. Build and push the WebSocket echo client Docker image to ACR

```sh
# Build the Docker image
az acr build --registry acr4aks08 --image websocket-echo-client:1.0.0 ./client
```

3. Deploy the WebSocket echo server application to the AKS cluster.