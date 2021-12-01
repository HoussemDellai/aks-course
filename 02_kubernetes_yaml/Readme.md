## Generating YAML files using kubectl

### Create a YAML manifest file for a Pod using the command line:
```bash
kubectl run nginx --image=nginx -o yaml --dry-run=client > nginx-pod.yaml
```

### Create a YAML manifest file for a Deployment using the command line:
```bash
kubectl create deployment nginx-dep --image=nginx --replicas=3  -o yaml --dry-run=client > nginx-deploy.yaml
```

### Create a YAML manifest file for a Service using the command line:
```bash
kubectl expose deployment nginx-dep --type=LoadBalancer --port=80 --dry-run=client -o yaml > nginx-svc.yaml
```