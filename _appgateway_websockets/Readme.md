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

## Important notes:

- If one of the Pod's containers has defined a preStop hook and the terminationGracePeriodSeconds in the Pod spec is not set to 0, the kubelet runs that hook inside of the container. The default terminationGracePeriodSeconds setting is 30 seconds.

- If the preStop hook is still running after the grace period expires, the kubelet requests a small, one-off grace period extension of 2 seconds.

- If the preStop hook needs longer to complete than the default grace period allows, you must modify terminationGracePeriodSeconds to suit this.

Src: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination-flow