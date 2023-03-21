# Custom domain names using Kubernetes CoreDNS

kubectl get pods -n kube-system -l=k8s-app=kube-dns
# NAME                       READY   STATUS    RESTARTS   AGE
# coredns-77f75ff65d-sx9mf   1/1     Running   0          85m
# coredns-77f75ff65d-z7f52   1/1     Running   0          89m

kubectl get configmap -n kube-system -l=k8s-app=kube-dns
# NAME                                 DATA   AGE
# coredns                              1      88m
# coredns-autoscaler                   1      83m
# coredns-custom                       0      88m

kubectl describe configmap coredns -n kube-system  
# Name:         coredns
# Namespace:    kube-system
# Labels:       addonmanager.kubernetes.io/mode=Reconcile
#               k8s-app=kube-dns
#               kubernetes.io/cluster-service=true
# Annotations:  <none>

# Data
# ====
# Corefile:
# ----
# .:53 {
#     errors
#     ready
#     health
#     kubernetes cluster.local in-addr.arpa ip6.arpa {
#       pods insecure
#       fallthrough in-addr.arpa ip6.arpa
#     }
#     prometheus :9153
#     forward . /etc/resolv.conf
#     cache 30
#     loop
#     reload
#     loadbalance
#     import custom/*.override
# }
# import custom/*.server


# BinaryData
# ====

# Events:  <none>

kubectl describe configmap coredns-custom -n kube-system
# Name:         coredns-custom
# Namespace:    kube-system
# Labels:       addonmanager.kubernetes.io/mode=EnsureExists
#               k8s-app=kube-dns
#               kubernetes.io/cluster-service=true
# Annotations:  <none>

# Data
# ====

# BinaryData
# ====

# Events:  <none>

kubectl create deployment nginx --image=nginx --replicas=3
# deployment.apps/nginx created

kubectl expose deployment nginx --name nginx --port=80
# service/nginx exposed

kubectl get deploy,svc
# NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/nginx   3/3     3            3           36s

# NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
# service/kubernetes   ClusterIP   10.0.0.1       <none>        443/TCP   7h30m
# service/nginx        ClusterIP   10.0.235.219   <none>        80/TCP    16s

kubectl apply -f custom-coredns.yaml
# configmap/coredns-custom configured

kubectl run nginx --image=nginx
# pod/nginx created

kubectl exec -it nginx -- curl http://nginx
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
# ...

kubectl exec -it nginx -- curl http://nginx.default.svc.cluster.local
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
# ...

# resolve the custom service name (but with namespace)
kubectl exec -it nginx -- curl http://nginx.default.aks.com 
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>

# resolve the custom service name (but without namespace)

# replace `rewrite stop` block with the following:
# rewrite stop {
#   name regex (.*)\.aks\.com\.$ {1}.default.svc.cluster.local.
#   answer name (.*).\default\.svc\.cluster\.local\.$ {1}.aks.com.
# }

# aply the new custom CoreDNS configmap
kubectl apply -f custom-coredns.yaml

# delete CoreDNS pods after updating the custom configmap to reload the new configmap
kubectl delete pod --namespace kube-system -l k8s-app=kube-dns

# resolving with '.aks.com'
kubectl exec -it nginx -- curl http://nginx.aks.com
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>