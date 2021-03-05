$ mkdir WebApp
$ dotnet new mvc
$ dotnet run
$ dotnet add package prometheus-net
$ dotnet add package prometheus-net.AspNetCore
# Addthe following code to Startup.cs class in the Configure method
# to enable Prometheus metrics
#   app.UseMetricServer(url: "/metrics");
$ dotnet run
# Open the web app on https://localhost:5001/metrics

# Create a docker container
$ docker build -t houssemdocker/webappmonitoring:prometheus .
$ docker run -d -p 5555:80/tcp houssemdocker/webappmonitoring:prometheus
$ docker push houssemdocker/webappmonitoring:prometheus

# deploy the container into Kubernetes
$ kubectl apply -f web-deploy-svc.yaml

# Install Prometheus using Helm charts
$ helm install stable/prometheus --name my-prometheus --set server.service.type=LoadBalancer --set rbac.create=false

# Prometheus dashboard IP address
$ kubectl get services

# Check default Prometheus configuration in prometheus.yml
$ kubectl exec -it <your-prometheus-server> -c prometheus-server -- cat /etc/config/prometheus.yml
# Check default Prometheus configuration in ConfigMap
$ kubectl get configmaps
$ kubectl describe configmap <your-prometheus-server-configmap>

# Add and edit values.yaml
$ helm upgrade my-prometheus stable/prometheus --set server.service.type=LoadBalancer --set rbac.create=false  -f prometheus.values.yaml


# Check new Prometheus configuration in prometheus.yml
$ kubectl exec -it <your-prometheus-server> -c prometheus-server -- cat /etc/config/prometheus.yml
# Check new Prometheus configuration in ConfigMap
$ kubectl get configmaps
$ kubectl describe configmap <your-prometheus-server-configmap>
