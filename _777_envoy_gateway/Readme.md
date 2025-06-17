# Envoy Gateway External Processing

Src: https://gateway.envoyproxy.io/docs/tasks/extensibility/ext-proc/

```sh
az group create -n rg-aks-cluster -l swedencentral
az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay -k 1.32.4 --node-vm-size standard_d2ads_v5
az aks get-credentials -n aks-cluster -g rg-aks-cluster --overwrite-existing
```

Follow the steps below to install Envoy Gateway and the example manifest. Before proceeding, you should be able to query the example backend using HTTP.

Install the Gateway API CRDs and Envoy Gateway using Helm:

```sh
helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.4.1 -n envoy-gateway-system --create-namespace
```

Install the GatewayClass, Gateway, HTTPRoute and example app:

```sh
kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v1.4.1/quickstart.yaml -n default
```

Get the External IP of the Gateway:

```sh
$GATEWAY_HOST = kubectl get gateway/eg -o jsonpath="{.status.addresses[0].value}"
echo $GATEWAY_HOST
```

Curl the example app through Envoy proxy:

```sh
curl --verbose --header "Host: www.example.com" http://$GATEWAY_HOST/get
```

The above command should succeed with status code 200.

GRPC External Processing Service
Installation
Install a demo GRPC service that will be used as the external processing service:

```sh
kubectl apply -f https://raw.githubusercontent.com/envoyproxy/gateway/latest/examples/kubernetes/ext-proc-grpc-service.yaml
```

Create a new HTTPRoute resource to route traffic on the path /myapp to the backend service.

```sh
kubectl apply -f .\httproute.yaml
```

Verify the HTTPRoute status:

```sh
kubectl get httproute/myapp -o yaml
```

Configuration

Create a new EnvoyExtensionPolicy resource to configure the external processing service. This EnvoyExtensionPolicy targets the HTTPRoute “myApp” created in the previous step. It calls the GRPC external processing service “grpc-ext-proc” on port 9002 for processing.

By default, requests and responses are not sent to the external processor. The processingMode struct is used to define what should be sent to the external processor. In this example, we configure the following processing modes:

The empty request field configures envoy to send request headers to the external processor.
The response field includes configuration for body processing. As a result, response headers are sent to the external processor. Additionally, the response body is streamed to the external processor.

```sh
kubectl apply -f ext-proc-example.yaml
```

Verify the Envoy Extension Policy configuration:

```sh
kubectl get envoyextensionpolicy/ext-proc-example -o yaml
```

Because the gRPC external processing service is enabled with TLS, a BackendTLSPolicy needs to be created to configure the communication between the Envoy proxy and the gRPC auth service.

```sh
kubectl apply -f grpc-ext-proc-btls.yaml
```

Verify the BackendTLSPolicy configuration:

```sh
kubectl get backendtlspolicy/grpc-ext-proc-btls -o yaml
```

Send a request to the backend service without Authentication header:

```sh
curl -v -H "Host: www.example.com" "http://${GATEWAY_HOST}/myapp"
```
