az group create -n rg-aks-cluster -l swedencentral

az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay -k 1.29.2 --enable-app-routing

az aks get-credentials -n aks-cluster -g rg-aks-cluster --overwrite-existing

kubectl create namespace hello-web-app-routing

kubectl apply -f app.yaml -n hello-web-app-routing

kubectl get ingress -n hello-web-app-routing

kubectl apply -f nginx-public-controller.yaml

kubectl apply -f nginx-internal-controller.yaml