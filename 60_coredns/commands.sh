# Custom domain names using Kubernetes CoreDNS

kubectl get pods -n kube-system -l=k8s-app=kube-dns

kubectl get configmap -n kube-system -l=k8s-app=kube-dns

kubectl describe configmap coredns -n kube-system  

kubectl describe configmap coredns-custom -n kube-system

kubectl create deployment nginx --image=nginx --replicas=3

kubectl expose deployment nginx --name nginx --port=80

kubectl get deploy,svc

kubectl apply -f custom-coredns.yaml

kubectl run nginx --image=nginx

kubectl exec -it nginx -- curl http://nginx

kubectl exec -it nginx -- curl http://nginx.default.svc.cluster.local

# resolve the custom service name (but with namespace)

kubectl exec -it nginx -- curl http://nginx.default.aks.com 

# apply the new custom CoreDNS configmap

kubectl apply -f custom-coredns.yaml

# delete CoreDNS pods after updating the custom configmap to reload the new configmap

kubectl delete pod --namespace kube-system -l k8s-app=kube-dns

# resolving with '.aks.com'

kubectl exec -it nginx -- curl http://nginx.aks.com
