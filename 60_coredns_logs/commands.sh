# Enable logging DNS queries in CoreDNS

# create an AKS cluster

$AKS_RG="rg-aks-cluster-dns-logs"
$AKS_NAME="aks-cluster"

az group create --name $AKS_RG --location westeurope

az aks create -g $AKS_RG -n $AKS_NAME --network-plugin azure --node-vm-size "Standard_B2als_v2"

az aks get-credentials -g $AKS_RG -n $AKS_NAME --overwrite-existing

# create demo application

kubectl run nginx --image=nginx

kubectl exec -it nginx -- apt update
kubectl exec -it nginx -- apt install dnsutils -y

kubectl exec -it nginx -- nslookup microsoft.com

# Did CoreDNS logged this DNS request ?

# check CoreDNS logs

kubectl get pods -n kube-system -l k8s-app=kube-dns

kubectl logs coredns-789789675-5mq2l -n kube-system

kubectl logs coredns-789789675-j55lz -n kube-system

# nothing was logged !

# Is logging enabled in CoreDNS ?

kubectl get configmap -n kube-system -l k8s-app=kube-dns

kubectl describe configmap coredns -n kube-system

kubectl describe cm coredns-custom -n kube-system

# enable logging for CoreDNS

code coredns-custom.yaml

kubectl apply -f coredns-custom.yaml

# Force CoreDNS to reload the ConfigMap

kubectl -n kube-system rollout restart deployment coredns

kubectl get pods -n kube-system -l k8s-app=kube-dns

# create DNS query

kubectl exec -it nginx -- nslookup microsoft.com

# View the CoreDNS logs

kubectl logs --namespace kube-system -l k8s-app=kube-dns
# [INFO] 10.224.0.10:47320 - 15830 "A IN microsoft.com. udp 31 false 512" NOERROR qr,rd,ra 176 0.001047529s
# [INFO] 10.224.0.10:47575 - 61320 "AAAA IN microsoft.com. udp 31 false 512" NOERROR qr,rd,ra 236 0.001028862s