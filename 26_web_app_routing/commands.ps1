# create an AKS cluster
az group create -n rg-aks-cluster-we -l westeurope

az aks create -g rg-aks-cluster-we -n aks-cluster --network-plugin azure --kubernetes-version "1.25.2"

az aks get-credentials --name aks-cluster -g rg-aks-cluster-we --overwrite-existing

# verify connection to the cluster
kubectl get nodes

# install Nginx ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

$NAMESPACE="ingress-basic"

helm install ingress-nginx ingress-nginx/ingress-nginx --create-namespace --namespace $NAMESPACE

kubectl apply -f aks-helloworld-one.yaml --namespace $NAMESPACE
# deployment.apps/aks-helloworld-one created
# service/aks-helloworld-one created
kubectl apply -f aks-helloworld-two.yaml --namespace $NAMESPACE
# deployment.apps/aks-helloworld-two created
# service/aks-helloworld-two created
kubectl apply -f hello-world-ingress.yaml --namespace $NAMESPACE
# ingress.networking.k8s.io/hello-world-ingress created
# ingress.networking.k8s.io/hello-world-ingress-static created

kubectl get pods --namespace $NAMESPACE
# NAME                                        READY   STATUS              RESTARTS   AGE
# aks-helloworld-one-749789b6c5-k7x2g         1/1     Running             0          19s
# aks-helloworld-two-5b8d45b8bf-vkw6k         0/1     ContainerCreating   0          18s
# ingress-nginx-controller-8574b6d7c9-7kmqc   1/1     Running             0          92s

kubectl get svc --namespace $NAMESPACE
# NAME                                 TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)                      AGE
# aks-helloworld-one                   ClusterIP      10.0.165.18   <none>         80/TCP                       19s
# aks-helloworld-two                   ClusterIP      10.0.236.83   <none>         80/TCP                       18s
# ingress-nginx-controller             LoadBalancer   10.0.44.194   20.73.235.13   80:31750/TCP,443:31529/TCP   92s
# ingress-nginx-controller-admission   ClusterIP      10.0.94.172   <none>         443/TCP                      92s

kubectl get ingress --namespace $NAMESPACE
# NAME                         CLASS   HOSTS   ADDRESS   PORTS   AGE
# hello-world-ingress          nginx   *                 80      19s
# hello-world-ingress-static   nginx   *                 80      19s


# install cert-manager

# Label the ingress-basic namespace to disable resource validation
kubectl label namespace $NAMESPACE cert-manager.io/disable-validation=true
# namespace/ingress-basic labeled
# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io
# Update your local Helm chart repository cache
helm repo update
# Install the cert-manager Helm chart
helm install cert-manager jetstack/cert-manager --namespace $NAMESPACE --create-namespace --set installCRDs=true

kubectl apply -f cluster-issuer.yaml
# clusterissuer.cert-manager.io/letsencrypt created

kubectl get clusterissuers
# NAME          READY   AGE
# letsencrypt   True    56s

kubectl apply -f hello-world-ingress-tls.yaml --namespace $NAMESPACE
# ingress.networking.k8s.io/hello-world-ingress created
# ingress.networking.k8s.io/hello-world-ingress-static created

kubectl get ingress -n $NAMESPACE
# NAME                         CLASS    HOSTS                                      ADDRESS   PORTS     AGE
# cm-acme-http-solver-qccmx    <none>   aks-app-01.westeurope.cloudapp.azure.com             80        4s
# hello-world-ingress          nginx    aks-app-01.westeurope.cloudapp.azure.com             80, 443   7s
# hello-world-ingress-static   nginx    aks-app-01.westeurope.cloudapp.azure.com             80, 443   7s

kubectl get certificate --namespace $NAMESPACE
# NAME         READY   SECRET       AGE
# tls-secret   False   tls-secret   4m10s



$CERT_NAME="aks-ingress-cert"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 `
    -out aks-ingress-tls.crt `
    -keyout aks-ingress-tls.key `
    -subj "/CN=aks-app-01.westeurope.cloudapp.azure.com/O=aks-ingress-tls"

$AKV_NAME="kvaksingress"
openssl pkcs12 -export -in aks-ingress-tls.crt -inkey aks-ingress-tls.key  -out "${CERT_NAME}.pfx"
# skip Password prompt
# Enter Export Password:
# Verifying - Enter Export Password:

az keyvault certificate import --vault-name $AKV_NAME -n $CERT_NAME -f "${CERT_NAME}.pfx"

$NAMESPACE="ingress-basic"
kubectl create namespace $NAMESPACE


# resources:
# How does HTTPS work? What's a CA? What's a self-signed Certificate?
https://www.youtube.com/watch?v=7K0gAYmWWho&list=PLShDm2AZYnK3cWZpOjV7nOpL7plH2Ztz0&index=1