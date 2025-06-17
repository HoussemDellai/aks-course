# Running Envoy Gateway on AKS

## Creating an AKS cluster

```sh
az group create --name rg-aks-cluster --location francecentral
az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay -k 1.31.3 --node-vm-size standard_d2ads_v5 --enable-apiserver-vnet-integration
az aks get-credentials -n aks-cluster -g rg-aks-cluster --overwrite-existing
```

## Install Envoy on Kubernetes using Envoy Gateway

You can run Envoy as a Kubernetes Ingress Gateway by installing Envoy Gateway on your Kubernetes cluster.

The following commands will: - Install the Gateway API CRDs and Envoy Gateway - Wait for Envoy Gateway to become available - Install the GatewayClass, Gateway, HTTPRoute and an example app.

```sh
helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.4.1 -n envoy-gateway-system --create-namespace
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available
```

Install and example app:

```sh
kubectl apply -f app.yaml
kubectl get all
```

Insttall the GatewayClass, Gateway, and HTTPRoute:

```sh
kubectl apply -f gateway-class.yaml,gateway.yaml,http-route.yaml
```

Check the deployed components:

```sh
kubectl get all -n envoy-gateway-system
# NAME                                             READY   STATUS    RESTARTS   AGE
# pod/envoy-default-eg-e41e7b31-54c4d844f8-9kjkj   2/2     Running   0          30m
# pod/envoy-gateway-5bdfcfc754-b8dp4               1/1     Running   0          31m

# NAME                                TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)                                            AGE
# service/envoy-default-eg-e41e7b31   LoadBalancer   10.0.142.9    172.189.14.196   80:31442/TCP                                       17h
# service/envoy-gateway               ClusterIP      10.0.231.86   <none>           18000/TCP,18001/TCP,18002/TCP,19001/TCP,9443/TCP   17h

# NAME                                        READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/envoy-default-eg-e41e7b31   1/1     1            1           17h
# deployment.apps/envoy-gateway               1/1     1            1           17h

# NAME                                                   DESIRED   CURRENT   READY   AGE
# replicaset.apps/envoy-default-eg-e41e7b31-54c4d844f8   1         1         1       30m
# replicaset.apps/envoy-default-eg-e41e7b31-7b59cc47cc   0         0         0       17h
# replicaset.apps/envoy-gateway-5bdfcfc754               1         1         1       31m
# replicaset.apps/envoy-gateway-858b6dd7bf               0         0         0       17h
```

## Get the External IP of the Gateway

```sh
kubectl get svc -n envoy-gateway-system
# NAME                        TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)                                            AGE
# envoy-default-eg-e41e7b31   LoadBalancer   10.0.142.9    172.189.14.196   80:31442/TCP                                       17h
# envoy-gateway               ClusterIP      10.0.231.86   <none>           18000/TCP,18001/TCP,18002/TCP,19001/TCP,9443/TCP   17h

$GATEWAY_HOST=$(kubectl get svc/envoy-default-eg-e41e7b31 -n envoy-gateway-system -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
```

Try accessing the exposed service through Envoy Gateway eitheir using the IP address or the DNS name of the service:

```sh
curl --verbose --header "Host: www.example.com" http://$GATEWAY_HOST/get
# *   Trying 172.189.14.196:80...
# * Connected to 172.189.14.196 (172.189.14.196) port 80
# * using HTTP/1.x
# > GET /get HTTP/1.1
# > Host: www.example.com
# > User-Agent: curl/8.12.1
# > Accept: */*
# >
# * Request completely sent off
# < HTTP/1.1 200 OK
# < content-type: application/json
# < x-content-type-options: nosniff
# < date: Sat, 14 Jun 2025 03:56:14 GMT
# < content-length: 475
# <
# {
#  "path": "/get",
#  "host": "www.example.com",
#  "method": "GET",
#  "proto": "HTTP/1.1",
#  "headers": {
#   "Accept": [
#    "*/*"
#   ],
#   "User-Agent": [
#    "curl/8.12.1"
#   ],
#   "X-Envoy-External-Address": [
#    "176.177.25.47"
#   ],
#   "X-Forwarded-For": [
#    "176.177.25.47"
#   ],
#   "X-Forwarded-Proto": [
#    "http"
#   ],
#   "X-Request-Id": [
#    "93f2377c-2692-41c6-8035-407907c2298d"
#   ]
#  },
#  "namespace": "default",
#  "ingress": "",
#  "service": "",
#  "pod": "backend-765694d47f-xgbct"
# }* Connection #0 to host 172.189.14.196 left intact
```

You can also open the IP address in a web browser to see the response.

## Explore the Envoy Gateway Traffic Policies

Explore the traffic policies found here: https://gateway.envoyproxy.io/docs/tasks/traffic/