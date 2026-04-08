# Testing websockets with Azure Application Gateway and AKS

This repository contains a sample application and configuration for testing WebSocket support with Azure Application Gateway and Azure Kubernetes Service (AKS). The sample application is a simple WebSocket echo server that can be deployed to AKS, and the Application Gateway is configured to route WebSocket traffic to the AKS cluster.

## Instructions

1. Deploy the AKS cluster and Application Gateway (AGIC) using the provided Terraform configuration in the `infra` directory.

```sh
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

This will create an AKS cluster and enable AGIC addon on the cluster, which will automatically configure the Application Gateway to route traffic to the AKS cluster based on Kubernetes Ingress resources.

![](./images/resources1.png)
![](./images/resources2.png)

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

4. Deploy the WebSocket echo server and client application to the AKS cluster.

```sh
kubectl apply -f ./kubernetes/
# deployment.apps/websocket-echo-client created
# deployment.apps/websocket-echo-server created
# service/websocket-echo-server created
# ingress.networking.k8s.io/websocket-echo-server created
# deployment.apps/inspectorgadget created
# service/inspectorgadget created
# ingress.networking.k8s.io/inspectorgadget created
```

5. Test the WebSocket connection

When all pods are running, this means the WebSocket echo server is up and running and also the client is running and connecting to the server. You can check the logs of the client pod to see the WebSocket connection status and messages.

```sh
kubectl logs -f deployment/websocket-echo-client
# 2026-04-07 17:07:18,144  Connected to ws://websocket-echo-server:80/websocket-echo-server
# 2026-04-07 17:07:18,144  Sent: Hello #1
# 2026-04-07 17:07:28,147  Received: echo from server ('10.244.0.86', 8765) : Hello #1
# 2026-04-07 17:07:29,149  Sent: Hello #2
# 2026-04-07 17:07:39,153  Received: echo from server ('10.244.0.86', 8765) : Hello #2
# ...
```

You can also check the logs from the server pod to see the incoming WebSocket connections and messages.

```sh
kubectl logs -f deployment/websocket-echo-server
```

## Testing Application Gateway behaviour during Pod termination

To test the behavior of the Application Gateway during Pod termination, you can follow these steps:

1. Identify one of the Pod names of the WebSocket echo server.

```sh
kubectl get pods
# NAME                                     READY   STATUS    RESTARTS   AGE
# websocket-echo-client-7b5494c85f-rkp57   1/1     Running   0          4m52s
# websocket-echo-server-f4b679d55-cpms5    1/1     Running   0          4m51s
# websocket-echo-server-f4b679d55-zztpn    1/1     Running   0          4m51s
# ...
```

2. Delete the identified Pod to simulate a termination scenario.

```sh
kubectl delete pod websocket-echo-server-f4b679d55-b7gkt
# pod "websocket-echo-server-f4b679d55-b7gkt" deleted
```

3. Monitor the logs of the WebSocket echo client to observe how it handles the termination of the server Pod and whether it can reconnect to another healthy Pod.

```sh
kubectl logs -f deployment/websocket-echo-client
```

## Important notes:

- If one of the Pod's containers has defined a preStop hook and the terminationGracePeriodSeconds in the Pod spec is not set to 0, the kubelet runs that hook inside of the container. The default terminationGracePeriodSeconds setting is 30 seconds.

- If the preStop hook is still running after the grace period expires, the kubelet requests a small, one-off grace period extension of 2 seconds.

- If the preStop hook needs longer to complete than the default grace period allows, you must modify terminationGracePeriodSeconds to suit this.

Src: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination-flow

- AGIC annonations: https://azure.github.io/application-gateway-kubernetes-ingress/annotations/

- WebSocket connection is bound to the specific server instance that accepted it, unless you explicitly design around that.

Why WebSocket connections are “bound” to a server
A WebSocket connection is:

A long‑lived, stateful TCP connection
Upgraded from HTTP via a handshake
Maintained between one client socket and one server socket

Once the handshake is complete:

* The TCP connection stays open
* All messages flow over that same socket
* Only the server process that owns that socket can read/write to it

If the server Restarts, Crashes, Is scaled down or Loses network connectivity then the WebSocket connection drops.

- It is important to configure correctly the health probes for the WebSocket server, to ensure that the Application Gateway can detect when the server is healthy and route traffic to it. If the health probes are not configured correctly, the Application Gateway may consider the server unhealthy and stop routing traffic to it, which can cause WebSocket connections to drop. AGIC configures the health probes based on the Kubernetes Ingress resource through annotation `appgw.ingress.kubernetes.io/health-probe-path: "/health"` and the Application Gateway will use that path to check the health of the WebSocket server. And the `server.py` app exposes the health endpoint at `/health` that returns a 200 OK status code when the server is healthy.

- The backend server must respond to the application gateway probes, which are described in the health probe overview section. Application gateway health probes are HTTP/HTTPS only. Each backend server must respond to HTTP probes for application gateway to route WebSocket traffic to the server.

- WebSockets are only supported when using Gateway API for Application Gateway for Containers, "but they work also for Gateway API": https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/websockets#health-probes