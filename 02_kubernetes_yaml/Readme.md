## Re Introduction to Kubernetes / AKS


### Create an AKS cluster (RBAC disabled) using Azure CLI
```bash
az group create --name rg-aks-cluster --location westeurope
# create the cluster, takes about 5 minutes...
az aks create -g rg-aks-cluster -n aks-cluster --node-count 3 --network-plugin azure
```

### Connect to the cluster
```bash
az aks get-credentials --resource-group rg-aks-cluster --name aks-cluster --overwrite-existing
kubectl get nodes
kubectl get nodes -o wide
```

### Create a YAML manifest file for a Pod using the command line:
```bash
kubectl run nginx --image=nginx -o yaml --dry-run=client > nginx-pod.yaml
```

### View Pods configuration
```bash
kubectl apply -f nginx-pod.yaml
kubectl get pods
# view pod IP address 
kubectl get pods -o wide
```

### Create a YAML manifest file for a Deployment using the command line:
```bash
kubectl create deployment nginx-deploy --image=nginx --replicas=3  -o yaml --dry-run=client > nginx-deploy.yaml
```

### View Deployment configuration
```bash
kubectl apply -f nginx-deploy.yaml
kubectl get deploy 
# view pods IP addresses and assigned Nodes
kubectl get pods -o wide
```

### Run inside Nginx Pod and connect to other pods
```bash
kubectl exec -it nginx -- /bin/sh
# when connected, view files inside container
ls
# connect to another pod using IP address
curl <Pod IP address>
exit
```

### Scale up and down Pods from deployment and note IP changes
```bash
kubectl scale --replicas=5 deployment/nginx-deploy
kubectl get pods -o wide
kubectl scale --replicas=3 deployment/nginx-deploy
kubectl get pods -o wide
```

### Create a YAML manifest file for a Service using the command line:
```bash
kubectl expose deployment nginx-deploy --name=nginx-svc --port=80 --dry-run=client -o yaml > nginx-svc.yaml
# note the use of Pod labels instead of Deployment name
cat nginx-svc.yaml
```

### View Service configuration
```bash
kubectl apply -f nginx-svc.yaml
kubectl get svc -w
# note IP addresses of backend Pods
kubectl describe svc nginx
```

### Pods in the cluster communicate with each others
### Run inside Nginx Pod and connect to a Service through its name
```bash
kubectl exec -it nginx -- /bin/sh
# connect to service
curl http://nginx-svc
exit
```

### Expose application Pods to external/public
```bash
kubectl edit service nginx-svc
# change service type to LoadBalancer instead of ClusterIP and save changes
kubectl get svc -w
# note the Public IP, created as an Azure resource
```