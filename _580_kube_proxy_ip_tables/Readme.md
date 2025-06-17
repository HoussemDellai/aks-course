# Demystifying kube-proxy and iptables in Kubernetes

This document provides an overview of kube-proxy and iptables in Kubernetes, including their roles, configurations, and how they work together to manage network traffic within a Kubernetes cluster.

## Creating the cluster

```sh
az group create -n rg-aks-cluster -l swedencentral
az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay -k 1.32.4 --node-vm-size standard_d2ads_v5
az aks get-credentials -n aks-cluster -g rg-aks-cluster --overwrite-existing
```

## Checking kube-proxy and iptables

```sh
kubectl get pods -n kube-system -l component=kube-proxy
# NAME               READY   STATUS    RESTARTS   AGE
# kube-proxy-4qv64   1/1     Running   0          6m51s
# kube-proxy-5m8kj   1/1     Running   0          6m56s
# kube-proxy-8wrmr   1/1     Running   0          6m57s

kubectl exec -it -n kube-system kube-proxy-4qv64 -- iptables -L -n -v
# Defaulted container "kube-proxy" out of: kube-proxy, kube-proxy-bootstrap (init)
# Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
#  pkts bytes target     prot opt in     out     source               destination
#  1818  109K KUBE-PROXY-FIREWALL  0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW /* kubernetes load balancer firewall */
#  260K  340M KUBE-NODEPORTS  0    --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes health check service ports */
#  1818  109K KUBE-EXTERNAL-SERVICES  0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW /* kubernetes externally-visible service portals */
#  267K  561M KUBE-FIREWALL  0    --  *      *       0.0.0.0/0            0.0.0.0/0

# Chain FORWARD (policy ACCEPT 221 packets, 25977 bytes)
#  pkts bytes target     prot opt in     out     source               destination
#   221 25977 KUBE-PROXY-FIREWALL  0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW /* kubernetes load balancer firewall */
#  5939 1887K KUBE-FORWARD  0    --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes forwarding rules */
#   221 25977 KUBE-SERVICES  0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW /* kubernetes service portals */
#   221 25977 KUBE-EXTERNAL-SERVICES  0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW /* kubernetes externally-visible service portals */
#     0     0 DROP       6    --  *      *       0.0.0.0/0            168.63.129.16        tcp dpt:32526
#     0     0 DROP       6    --  *      *       0.0.0.0/0            168.63.129.16        tcp dpt:80

# Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
#  pkts bytes target     prot opt in     out     source               destination
#  4950  300K KUBE-PROXY-FIREWALL  0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW /* kubernetes load balancer firewall */
#  4950  300K KUBE-SERVICES  0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW /* kubernetes service portals */
# 68793   12M KUBE-FIREWALL  0    --  *      *       0.0.0.0/0            0.0.0.0/0

# Chain KUBE-EXTERNAL-SERVICES (2 references)
#  pkts bytes target     prot opt in     out     source               destination

# Chain KUBE-FIREWALL (2 references)
#  pkts bytes target     prot opt in     out     source               destination
#     0     0 DROP       0    --  *      *      !127.0.0.0/8          127.0.0.0/8          /* block incoming localnet connections */ ! ctstate RELATED,ESTABLISHED,DNAT

# Chain KUBE-FORWARD (1 references)
#  pkts bytes target     prot opt in     out     source               destination
#     0     0 DROP       0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate INVALID nfacct-name  ct_state_invalid_dropped_pkts
#     0     0 ACCEPT     0    --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes forwarding rules */ mark match 0x4000/0x4000
#  5224 1531K ACCEPT     0    --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes forwarding conntrack rule */ ctstate RELATED,ESTABLISHED

# Chain KUBE-KUBELET-CANARY (0 references)
#  pkts bytes target     prot opt in     out     source               destination

# Chain KUBE-NODEPORTS (1 references)
#  pkts bytes target     prot opt in     out     source               destination

# Chain KUBE-PROXY-CANARY (0 references)
#  pkts bytes target     prot opt in     out     source               destination

# Chain KUBE-PROXY-FIREWALL (3 references)
#  pkts bytes target     prot opt in     out     source               destination

# Chain KUBE-SERVICES (2 references)
#  pkts bytes target     prot opt in     out     source               destination

kubectl create deployment nginx --image=nginx --replicas=3
# deployment.apps/nginx created

kubectl get pods -o wide
# NAME                                                    READY   STATUS      RESTARTS   AGE   IP             NODE                                NOMINATED NODE   READINESS GATES
# nginx-5869d7778c-bcgsv                                  1/1     Running     0          7s    10.244.1.221   aks-nodepool1-29209556-vmss000001   <none>           <none>
# nginx-5869d7778c-jf6pr                                  1/1     Running     0          7s    10.244.2.136   aks-nodepool1-29209556-vmss000002   <none>           <none>
# nginx-5869d7778c-srnqk                                  1/1     Running     0          7s    10.244.0.126   aks-nodepool1-29209556-vmss000000   <none>           <none>

kubectl expose deployment nginx --name=nginx --port=80 --target-port=80 --type=ClusterIP
# service/nginx exposed

kubectl get svc
# NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
# kubernetes   ClusterIP   10.0.0.1       <none>        443/TCP   52m
# nginx        ClusterIP   10.0.111.189   <none>        80/TCP    13s
```	

All Pod-to-Service packets get intercepted by the PREROUTING chain:

```sh
kubectl exec -it -n kube-system kube-proxy-4qv64 -- iptables -t nat -nvL PREROUTING
# Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
#  pkts bytes target     prot opt in     out     source               destination
#   887 82613 KUBE-SERVICES  0    --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service portals */
```

These packets get redirected to the KUBE-SERVICES chain, where they get matched against all configured ClusterIPs, eventually reaching these lines:

```sh
kubectl exec -it -n kube-system kube-proxy-4qv64 -- iptables -t nat -nvL KUBE-SERVICES
# Chain KUBE-SERVICES (2 references)
#  pkts bytes target     prot opt in     out     source               destination
#    50  7460 KUBE-SVC-TCOU7JCQXEZGVUNU  17   --  *      *       0.0.0.0/0            10.0.0.10            /* kube-system/kube-dns:dns cluster IP */ udp dpt:53
#     0     0 KUBE-SVC-ERIFXISQEP7F7OF4  6    --  *      *       0.0.0.0/0            10.0.0.10            /* kube-system/kube-dns:dns-tcp cluster IP */ tcp dpt:53
#     0     0 KUBE-SVC-QMWWTXBG7KFJQKLO  6    --  *      *       0.0.0.0/0            10.0.136.241         /* kube-system/metrics-server cluster IP */ tcp dpt:443
#     0     0 KUBE-SVC-NPX46M4PTMTKRN6Y  6    --  *      *       0.0.0.0/0            10.0.0.1             /* default/kubernetes:https cluster IP */ tcp dpt:443
#     0     0 KUBE-SVC-2CMXP7HKUVJN7L6M  6    --  *      *       0.0.0.0/0            10.0.111.189         /* default/nginx cluster IP */ tcp dpt:80
#  1102 66159 KUBE-NODEPORTS  0    --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service nodeports; NOTE: this must be the last rule in this chain */ ADDRTYPE match dst-type LOCAL
```

Since the sourceIP of the packet belongs to a Pod (10.244.0.0/16 is the PodCIDR range), the second line gets matched and the lookup continues in the service-specific chain. Here we have two Pods matching the same label-selector (--replicas=2) and both chains are configured with equal distribution probability:

```sh
kubectl exec -it -n kube-system kube-proxy-4qv64 -- iptables -t nat -nvL KUBE-SVC-2CMXP7HKUVJN7L6M
Defaulted container "kube-proxy" out of: kube-proxy, kube-proxy-bootstrap (init)
Chain KUBE-SVC-2CMXP7HKUVJN7L6M (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 KUBE-MARK-MASQ  6    --  !azv+  *       0.0.0.0/0            10.0.111.189         /* default/nginx cluster IP */ tcp dpt:80
    0     0 KUBE-SEP-6WVWGAPSOX73WQLV  0    --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/nginx -> 10.244.0.126:80 */ statistic mode random probability 0.33333333349
    0     0 KUBE-SEP-SZEPRK2MPZRFAUE2  0    --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/nginx -> 10.244.1.221:80 */ statistic mode random probability 0.50000000000
    0     0 KUBE-SEP-EQWDXNDQNTKEXYHG  0    --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/nginx -> 10.244.2.136:80 */
```	

## Resources

https://www.tkng.io/services/clusterip/dataplane/iptables/

https://help.ubuntu.com/community/IptablesHowTo