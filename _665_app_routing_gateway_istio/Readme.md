# Gateway API with meshless Istio

This example shows how to use the Gateway API with meshless Istio.

```sh
az group create --name rg-aks-cluster --location swedencentral

az aks create --resource-group rg-aks-cluster --name aks-cluster --enable-gateway-api --enable-app-routing-istio

az aks get-credentials -n aks-cluster -g rg-aks-cluster --overwrite-existing
```

After a moment, you should see istiod running in aks-istio-system:

```sh
kubectl get pods -n aks-istio-system
```

Deploy a sample app, Gateway, and HTTPRoute
First, deploy the httpbin sample application:

```sh
kubectl apply -f httpbin.yaml
```

Then create a Gateway using the approuting-istio GatewayClass and attach an HTTPRoute to it:

```sh
kubectl apply -f gateway_istio.yaml
kubectl apply -f http_route.yaml
```

Finally, get the public IP address of the Gateway:

```sh
kubectl get svc
# NAME                               TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)                        AGE
# httpbin                            ClusterIP      10.0.250.83   <none>         8000/TCP                       51s
# httpbin-gateway-approuting-istio   LoadBalancer   10.0.32.93    4.223.234.10   15021:32017/TCP,80:31474/TCP   32s
# kubernetes                         ClusterIP      10.0.0.1      <none>         443/TCP                        4m6s
```

```sh
curl -s -I -H "Host: httpbin.example.com" "http://4.223.234.10/get"
# HTTP/1.1 200 OK
# access-control-allow-credentials: true
# access-control-allow-origin: *
# content-type: application/json; charset=utf-8
# date: Fri, 27 Mar 2026 07:40:40 GMT
# x-envoy-upstream-service-time: 0
# server: istio-envoy
# transfer-encoding: chunked
```

## Resources

- https://blog.aks.azure.com/2026/03/18/app-routing-gateway-api



