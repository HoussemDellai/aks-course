# create an AKS cluster
RG="rg-aks-we"
AKS="aks-cluster"

az group create -n $RG -l westeurope

az aks create -g $RG -n $AKS --network-plugin azure --kubernetes-version "1.25.2" --node-count 2

az aks get-credentials --name $AKS -g $RG --overwrite-existing

# verify connection to the cluster
kubectl get nodes

# install Nginx ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

NAMESPACE_INGRESS="ingress-nginx"

helm install ingress-nginx ingress-nginx/ingress-nginx --create-namespace --namespace $NAMESPACE_INGRESS

kubectl get services ingress-nginx-controller --namespace $NAMESPACE_INGRESS -o wide

INGRESS_PUPLIC_IP=$(kubectl get services ingress-nginx-controller -n $NAMESPACE_INGRESS -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

NAMESPACE_APP_01="app-01"
kubectl create namespace $NAMESPACE_APP_01

# cat <<EOF | kubectl apply -f -
cat <<EOF >aks-helloworld-one.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aks-helloworld-one  
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aks-helloworld-one
  template:
    metadata:
      labels:
        app: aks-helloworld-one
    spec:
      containers:
      - name: aks-helloworld-one
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
        env:
        - name: TITLE
          value: "Welcome to Azure Kubernetes Service (AKS)"
---
apiVersion: v1
kind: Service
metadata:
  name: aks-helloworld-one  
spec:
  type: ClusterIP
  ports:
  - port: 80
  selector:
    app: aks-helloworld-one
EOF

kubectl apply -f aks-helloworld-one.yaml --namespace $NAMESPACE_APP_01
# deployment.apps/aks-helloworld-one created
# service/aks-helloworld-one created

cat <<EOF >aks-helloworld-two.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aks-helloworld-two  
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aks-helloworld-two
  template:
    metadata:
      labels:
        app: aks-helloworld-two
    spec:
      containers:
      - name: aks-helloworld-two
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
        env:
        - name: TITLE
          value: "AKS Ingress Demo"
---
apiVersion: v1
kind: Service
metadata:
  name: aks-helloworld-two  
spec:
  type: ClusterIP
  ports:
  - port: 80
  selector:
    app: aks-helloworld-two
EOF

kubectl apply -f aks-helloworld-two.yaml --namespace $NAMESPACE_APP_01
# deployment.apps/aks-helloworld-two created
# service/aks-helloworld-two created

cat <<EOF >hello-world-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /hello-world-one(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: aks-helloworld-one
            port:
              number: 80
      - path: /hello-world-two(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: aks-helloworld-two
            port:
              number: 80
      - path: /(.*)
        pathType: Prefix
        backend:
          service:
            name: aks-helloworld-one
            port:
              number: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world-ingress-static
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /static/$2
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /static(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: aks-helloworld-one
            port: 
              number: 80
EOF

kubectl apply -f hello-world-ingress.yaml --namespace $NAMESPACE_APP_01
# ingress.networking.k8s.io/hello-world-ingress created
# ingress.networking.k8s.io/hello-world-ingress-static created

kubectl get pods --namespace $NAMESPACE_APP_01
NAME                                  READY   STATUS    RESTARTS   AGE
aks-helloworld-one-749789b6c5-8wktc   1/1     Running   0          13m
aks-helloworld-two-5b8d45b8bf-pg4wh   1/1     Running   0          12m

kubectl get svc --namespace $NAMESPACE_APP_01
# NAME                                 TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)                      AGE
# aks-helloworld-one                   ClusterIP      10.0.165.18   <none>         80/TCP                       19s
# aks-helloworld-two                   ClusterIP      10.0.236.83   <none>         80/TCP                       18s
# ingress-nginx-controller             LoadBalancer   10.0.44.194   20.73.235.13   80:31750/TCP,443:31529/TCP   92s
# ingress-nginx-controller-admission   ClusterIP      10.0.94.172   <none>         443/TCP                      92s

kubectl get ingress --namespace $NAMESPACE_APP_01
# NAME                         CLASS   HOSTS   ADDRESS          PORTS   AGE
# hello-world-ingress          nginx   *       20.126.201.249   80      11m
# hello-world-ingress-static   nginx   *       20.126.201.249   80      11m

# check app is running behind Nginx Ingress Controller (with no HTTPS)
curl http://$INGRESS_PUPLIC_IP
curl http://$INGRESS_PUPLIC_IP/aks-helloworld-one
curl http://$INGRESS_PUPLIC_IP/aks-helloworld-two