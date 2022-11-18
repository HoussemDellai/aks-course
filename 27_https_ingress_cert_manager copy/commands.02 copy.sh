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

NAMESPACE_APP_01="app-01"
kubectl create namespace $NAMESPACE_APP_01

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



# Configure HTTPS for Ingress resources

# configure Ingress' Public IP with DNS Name
az network public-ip update -g MC_rg-aks-cluster-we_aks-cluster_westeurope -n kubernetes-a2e03b8de1f78430cb641acf10ada77c --dns-name aks-app-01

# install cert-manager

# Label the ingress-basic namespace to disable resource validation
kubectl label namespace $NAMESPACE_APP_01 cert-manager.io/disable-validation=true
# namespace/ingress-basic labeled
# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io
# Update your local Helm chart repository cache
helm repo update
# Install the cert-manager Helm chart
helm install cert-manager jetstack/cert-manager --namespace  $NAMESPACE_APP_01 --create-namespace --set installCRDs=true

kubectl apply -f issuer.yaml -n $NAMESPACE_APP_01
# issuer.cert-manager.io/letsencrypt created

kubectl get issuer -n  $NAMESPACE_APP_01
# NAME          READY   AGE
# letsencrypt   True    56s

kubectl apply -f hello-world-ingress-tls.yaml --namespace  $NAMESPACE_APP_01
# ingress.networking.k8s.io/hello-world-ingress created
# ingress.networking.k8s.io/hello-world-ingress-static created

kubectl get ingress -n  $NAMESPACE_APP_01
# NAME                         CLASS    HOSTS                                      ADDRESS   PORTS     AGE
# cm-acme-http-solver-qccmx    <none>   aks-app-01.westeurope.cloudapp.azure.com             80        4s
# hello-world-ingress          nginx    aks-app-01.westeurope.cloudapp.azure.com             80, 443   7s
# hello-world-ingress-static   nginx    aks-app-01.westeurope.cloudapp.azure.com             80, 443   7s

kubectl get certificate --namespace  $NAMESPACE_APP_01
# NAME         READY   SECRET       AGE
# tls-secret   False   tls-secret   4m10s


# Set up Secrets Store CSI Driver to enable NGINX Ingress Controller with TLS
# src: https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-nginx-tls

$CERT_NAME="aks-ingress-cert"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 `
    -out aks-ingress-tls.crt `
    -keyout aks-ingress-tls.key `
    -subj "/CN=houssem.cloud/O=aks-ingress-tls-02" `
    -addext "subjectAltName = DNS:houssem.cloud" # added by reco
# $CERT_NAME="aks-ingress-cert"
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 `
#     -out aks-ingress-tls.crt `
#     -keyout aks-ingress-tls.key `
#     -subj "/CN=aks-app-01.westeurope.cloudapp.azure.com/O=aks-ingress-tls" `
#     -addext "subjectAltName = DNS:aks-app-01.westeurope.cloudapp.azure.com" # added by reco

openssl pkcs12 -export -in aks-ingress-tls.crt -inkey aks-ingress-tls.key -out "${CERT_NAME}.pfx"
# skip Password prompt
# Enter Export Password:
# Verifying - Enter Export Password:

$AKV_NAME="kvaksingress01"
az keyvault create -n $AKV_NAME -g $RG
az keyvault certificate import --vault-name $AKV_NAME -n $CERT_NAME -f "${CERT_NAME}.pfx"

 $NAMESPACE_INGRESS="ingress-basic"
kubectl create namespace  $NAMESPACE_INGRESS


az aks enable-addons --addons azure-keyvault-secrets-provider -n $AKS -g rg-aks-cluster-we

kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver, secrets-store-provider-azure)'
# NAME                                     READY   STATUS    RESTARTS   AGE
# aks-secrets-store-csi-driver-knhnr       3/3     Running   0          24m
# aks-secrets-store-csi-driver-mpd6q       3/3     Running   0          24m
# aks-secrets-store-csi-driver-rmlhk       3/3     Running   0          24m
# aks-secrets-store-provider-azure-4ckgq   1/1     Running   0          24m
# aks-secrets-store-provider-azure-88snb   1/1     Running   0          24m
# aks-secrets-store-provider-azure-zcc2z   1/1     Running   0          24m

az aks show -g $RG -n $AKS --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv
# 47744279-8b5e-4c77-9102-7c6c1874587a

az identity create -g $RG -n keyvault-identity 
# {
#     "clientId": "8e660c8d-7f99-44c9-8bf1-f72b62179be7",
#     "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourcegroups/rg-aks-cluster-we/providers/Microsoft.ManagedIdentity/userAssignedIdentities/keyvault-identity",
#     "location": "westeurope",
#     "name": "keyvault-identity",
#     "principalId": "c3a38040-d9bc-4565-abf0-0b880375911e",
#     "resourceGroup": "rg-aks-cluster-we",
#     "tags": {},
#     "tenantId": "16b3c013-d300-468d-ac64-7eda0820b6d3",
#     "type": "Microsoft.ManagedIdentity/userAssignedIdentities"
# }

$identity_id=$(az identity show -g $RG -n keyvault-identity --query "id")
echo $identity_id
# "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourcegroups/rg-aks-cluster-we/providers/Microsoft.ManagedIdentity/userAssignedIdentities/keyvault-identity"

az vmss identity assign -g MC_rg-aks-cluster-we_aks-cluster_westeurope -n aks-nodepool1-85587565-vmss --identities $identity_id
#   {
#     "systemAssignedIdentity": "",
#     "userAssignedIdentities": {
#       "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/MC_rg-aks-cluster-we_aks-cluster_westeurope/providers/Microsoft.ManagedIdentity/userAssignedIdentities/aks-cluster-agentpool": {
#         "clientId": "b4119fe0-112e-4ad2-8f90-1c228f98891a",
#         "principalId": "4d28297a-542f-490e-b8f4-b5830295f4a3"
#       },
#       "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourcegroups/MC_rg-aks-cluster-we_aks-cluster_westeurope/providers/Microsoft.ManagedIdentity/userAssignedIdentities/azurekeyvaultsecretsprovider-aks-cluster": {
#         "clientId": "47744279-8b5e-4c77-9102-7c6c1874587a",
#         "principalId": "d99c0fdd-a15b-4cb4-8631-cc029118063e"
#       },
#       "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourcegroups/rg-aks-cluster-we/providers/Microsoft.ManagedIdentity/userAssignedIdentities/keyvault-identity": {
#         "clientId": "8e660c8d-7f99-44c9-8bf1-f72b62179be7",
#         "principalId": "c3a38040-d9bc-4565-abf0-0b880375911e"
#       }
#     }
#   }

$identity_client_id=$(az identity show -g $RG -n keyvault-identity --query "clientId")
echo $identity_client_id
"8e660c8d-7f99-44c9-8bf1-f72b62179be7"

# set policy to access keys in your key vault
az keyvault set-policy -n $AKV_NAME --key-permissions get --spn $identity_client_id
# set policy to access secrets in your key vault
az keyvault set-policy -n $AKV_NAME --secret-permissions get --spn $identity_client_id
# set policy to access certs in your key vault
az keyvault set-policy -n $AKV_NAME --certificate-permissions get --spn $identity_client_id


kubectl apply -f secretProviderClass.yaml -n  $NAMESPACE_INGRESS
# secretproviderclass.secrets-store.csi.x-k8s.io/azure-tls created

kubectl get secretproviderclass -n  $NAMESPACE_INGRESS
# NAME        AGE
# azure-tls   9s

kubectl get secret -n  $NAMESPACE_INGRESS
# NAME                                  TYPE                 DATA   AGE
# cert-manager-webhook-ca               Opaque               3      3h42m
# ingress-nginx-admission               Opaque               3      3h57m
# ingress-tls-csi                       kubernetes.io/tls    2      7m25s
# letsencrypt                           Opaque               1      3h41m
# sh.helm.release.v1.cert-manager.v1    helm.sh/release.v1   1      3h42m
# sh.helm.release.v1.ingress-nginx.v1   helm.sh/release.v1   1      3h57m
# sh.helm.release.v1.ingress-nginx.v2   helm.sh/release.v1   1      18m
# sh.helm.release.v1.ingress-nginx.v3   helm.sh/release.v1   1      15m
# tls-secret                            kubernetes.io/tls    2      34m

kubectl describe secret ingress-tls-csi -n  $NAMESPACE_INGRESS
# Name:         ingress-tls-csi
# Namespace:    default
# Labels:       secrets-store.csi.k8s.io/managed=true
# Annotations:  <none>
# Type:  kubernetes.io/tls
# Data
# ====
# tls.crt:  1269 bytes
# tls.key:  1675 bytes

kubectl apply -f test-kv-pod.yaml -n  $NAMESPACE_INGRESS
# pod/busybox-secrets-store-inline-user-msi created

kubectl get pods -n  $NAMESPACE_INGRESS
# NAME                                       READY   STATUS    RESTARTS   AGE
# aks-helloworld-one-749789b6c5-jpjl6        1/1     Running   0          3h58m
# aks-helloworld-two-5b8d45b8bf-lnqvc        1/1     Running   0          3h58m
# cert-manager-69b456d85c-j2bgd              1/1     Running   0          3h43m
# cert-manager-cainjector-5f44d58c4b-dhkf4   1/1     Running   0          3h43m
# cert-manager-webhook-566bd88f7b-bsp6d      1/1     Running   0          3h43m
# ingress-nginx-controller-57865f799-8kkqz   1/1     Running   0          17m
# ingress-nginx-controller-57865f799-mhzww   1/1     Running   0          8m39s
# nginx-secrets-store                        1/1     Running   0          3m13s

kubectl exec nginx-secrets-store -n  $NAMESPACE_INGRESS -- ls /mnt/secrets-store/aks-ingress-cert
# /mnt/secrets-store/aks-ingress-cert

kubectl exec nginx-secrets-store -n  $NAMESPACE_INGRESS -- cat /mnt/secrets-store/aks-ingress-cert
# -----BEGIN PRIVATE KEY-----
# MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCZkk/vkoly89H7
# IrqI+7+aKqRG3hMAuAkmfdKvIs2aJ0uxPTlKY7M6MsASHRTbdnLG7hVO8sHgi8Ba
# eckvuBZNOhD7MgD0uSzvFWHFrOlVdVzae+QpB+QQF7unWuwgXAdcTIZ04sJutqor
# AKMUwUEhJUJO0Aqh9IOhHfP435JiiEqHQRk+iAnTbOyAO7SDCfiI2+ec8fVY+73r
# p0a/UQas0ZvGjNvluHZmzRMqz1/OhLXa/Td1j/pehXertgleisiz5x7PV3Ci5Q0f
# 6+WLNlsVVYqnjQ76mH72/F544ovZOWD3X8wr7Sqwvd5K+3SrJMBKj+1DtYwjZt5E
# iR75ufDHAgMBAAECggEAfioes7JOa3r16n0IhFtWeMBJf9MYB4IqOk4qVSmhgeCA
# pdanh37LEqf49aigpv/zoYydQuPa9a+6Ulo1N5fj8oQeyU+2S1cKHE0TqwO4GjY2
# F2Sq+C58ZeApkX73+EnC3kgcOlDE7ZHx0SxPzlBKQoHKrNbrtUwdC7OA6Ng7+ee6
# j/mx5L2SP1EQzOMEZJvrATJQ6PJHwf5WHj/WlRQ64KT+8rATyE2JfMrhUDxjBGnP
# yvmkvVsl6fi3zKADLns6CpcVr8ES9hNHmVMe29VwQf13kc7SnO2lOPcUL+UN5a7H
# fXcsgS6lp107eGqqwGpvyOc5Mhh8m5jUuADjLyKqOQKBgQDG7EK8Ahn5lKkAvwLN
# BtkrHzqzKRrG7E7QrCEDu7yt7j5HjHZktCA+fFjaGgK3UrEd2jWzP0fea5h0+Fwx
# M/d/lKWzl5naMnWmymFAXHs0KfDjSrLvTzHA9tMdUazZmnfBq0ZqAFEAjLNs6EL1
# ymJpwXyeMY6Ll3sT8DpX/biRfQKBgQDFosy3QDBQTmvTE/D+AV6T/6KwF/HckgJf
# qJ+a97LCGIfytqNYqWct1Fe7ZHv7ti1yp9NaNDMbMAanaaYLd7WlSfKgbv3m0UAC
# wyKLSJ+8Wq3fxYpBnpwfeYPU40mBaRM3sLdAIlx/2YUxLK16Y5vUE/iLQUEbaROD
# w9dv6STekwKBgDpSpRJYj2MUyiRU3K5eVqgFBQHoiFhQip82CIv+rEhWtN3negL2
# qQmJDcgMnkU/snxtMRd380tsQovxEZ6/fM5kN90bEtndt48KgU8Mjnbx4RXTHfl6
# P70y4R0UiFhYqMoYvJFxvE4r8qN4ycEk8IvPVglPwFp/NG/ZHFIWKtpFAoGBAIq4
# 7/q8mmzz7qk1ORYBfhJiAB6cYA8TiYj9gjIzJQ0qTNpnqhZEqgC4KHCHYqNWx2XQ
# OQD63Nh7iGAgPwWTnDONyTklTyChxc1qjKe5bS23dI46SQYwP6O0Fn3qn6CvUWbo
# qmfg9o5i7yOKGaZrnmhpMC8GuZ10ztbRMzoBKvjzAoGAKleqmySXCuGb9MGOj/6d
# ZwUuD/UFgp8hRP0sKYfrXtn3Uqfp7RQiLH7Is9bYEpL+1KYoTFAZf5tdISKziKLc
# c0vZfbxsW0cNQ+fbULedCL6Qr7ALAbwLi4BcYuGINJr4A/AGlO+bZiOqiLJD6Tgy
# qMjC5ZSyqKqPegly8fF2tyU=
# -----END PRIVATE KEY-----
# -----BEGIN CERTIFICATE-----
# MIIDezCCAmOgAwIBAgIUEIs6iydkR6j1rWVaiD63iat7OWcwDQYJKoZIhvcNAQEL
# BQAwTTExMC8GA1UEAwwoYWtzLWFwcC0wMS53ZXN0ZXVyb3BlLmNsb3VkYXBwLmF6
# dXJlLmNvbTEYMBYGA1UECgwPYWtzLWluZ3Jlc3MtdGxzMB4XDTIyMTExNzA3NDY1
# NFoXDTIzMTExNzA3NDY1NFowTTExMC8GA1UEAwwoYWtzLWFwcC0wMS53ZXN0ZXVy
# b3BlLmNsb3VkYXBwLmF6dXJlLmNvbTEYMBYGA1UECgwPYWtzLWluZ3Jlc3MtdGxz
# MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmZJP75KJcvPR+yK6iPu/
# miqkRt4TALgJJn3SryLNmidLsT05SmOzOjLAEh0U23Zyxu4VTvLB4IvAWnnJL7gW
# TToQ+zIA9Lks7xVhxazpVXVc2nvkKQfkEBe7p1rsIFwHXEyGdOLCbraqKwCjFMFB
# ISVCTtAKofSDoR3z+N+SYohKh0EZPogJ02zsgDu0gwn4iNvnnPH1WPu966dGv1EG
# rNGbxozb5bh2Zs0TKs9fzoS12v03dY/6XoV3q7YJXorIs+cez1dwouUNH+vlizZb
# FVWKp40O+ph+9vxeeOKL2Tlg91/MK+0qsL3eSvt0qyTASo/tQ7WMI2beRIke+bnw
# xwIDAQABo1MwUTAdBgNVHQ4EFgQUAmm9sMPV7HGU/xIgrqx61+J9BwcwHwYDVR0j
# BBgwFoAUAmm9sMPV7HGU/xIgrqx61+J9BwcwDwYDVR0TAQH/BAUwAwEB/zANBgkq
# hkiG9w0BAQsFAAOCAQEAabDbitolb854v+G1d0yB7Da++TSV7yvhlA8VIi86L/4c
# R+eRVgxjj8miD3j7hnA68PFbfzNTtzAw+OtmEc0zHos4yWw6yD+Wpd0rkPXrb/vM
# fcyVIElG88OB+P+2E/3CFn/vHf0fa9dgwQmkBQV7BKdB6Erqlrgdnpz6AN2l+TUi
# 3LVgBip1hrrIDHwxs3aDIOSheZ8TJs0xHdWuyuvFdMEGP0Pq/7mSURs50eNRKMd2
# 4jft8slnzjzWzX19AKKfpb2+8n1uycEOrSj0YOk9z140c99biFIDlUimn3brkZ6F
# EcTWOC05S5sD6pFwET+CRsITBDZY+iqYSZBntAwxCA==
# -----END CERTIFICATE-----

# To enable autorotation of secrets, use the enable-secret-rotation flag when you create your cluster:
az aks addon update -n $AKS -g $RG -a azure-keyvault-secrets-provider --enable-secret-rotation --rotation-poll-interval 2m

$ingress_nginx_values = @"
controller:
  extraVolumes:
      - name: secrets-store-inline
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: "azure-tls"
  extraVolumeMounts:
      - name: secrets-store-inline
        mountPath: "/mnt/secrets-store"
        readOnly: true
"@
$ingress_nginx_values | helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx `
    --namespace  $NAMESPACE_INGRESS `
    --set controller.replicaCount=2 `
    --set controller.nodeSelector."kubernetes\.io/os"=linux `
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux `
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz `
    -f - 


kubectl run nginx --image=nginx

root@nginx:/ curl -v -k --resolve aks-app-01.houssem.cloud:443:20.82.30.99 https://aks-app-01.houssem.cloud
    # * Added aks-app-01.houssem.cloud:443:20.82.30.99 to DNS cache
    # * Hostname aks-app-01.houssem.cloud was found in DNS cache
    # *   Trying 20.82.30.99:443...
    # * Connected to aks-app-01.houssem.cloud (20.82.30.99) port 443 (#0)
    # * ALPN, offering h2
    # * ALPN, offering http/1.1
    # * successfully set certificate verify locations:
    # *  CAfile: /etc/ssl/certs/ca-certificates.crt
    # *  CApath: /etc/ssl/certs
    # * TLSv1.3 (OUT), TLS handshake, Client hello (1):
    # * TLSv1.3 (IN), TLS handshake, Server hello (2):
    # * TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
    # * TLSv1.3 (IN), TLS handshake, Certificate (11):
    # * TLSv1.3 (IN), TLS handshake, CERT verify (15):
    # * TLSv1.3 (IN), TLS handshake, Finished (20):
    # * TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
    # * TLSv1.3 (OUT), TLS handshake, Finished (20):
    # * SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
    # * ALPN, server accepted to use h2
    # * Server certificate:
    # *  subject: CN=aks-app-01.houssem.cloud
    # *  start date: Nov 17 17:25:37 2022 GMT
    # *  expire date: Nov 17 17:35:37 2023 GMT
    # *  issuer: CN=aks-app-01.houssem.cloud
    # *  SSL certificate verify result: self signed certificate (18), continuing anyway.
    # * Using HTTP2, server supports multi-use
    # * Connection state changed (HTTP/2 confirmed)
    # * Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
    # * Using Stream ID: 1 (easy handle 0x5581835e52c0)
    # > GET / HTTP/2
    # > Host: aks-app-01.houssem.cloud
    # > user-agent: curl/7.74.0
    # > accept: */*
    # >
    # * TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
    # * TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
    # * old SSL session ID is stale, removing
    # * Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
    # < HTTP/2 200
    # < date: Thu, 17 Nov 2022 17:52:02 GMT
    # < content-type: text/html; charset=utf-8
    # < content-length: 629
    # < strict-transport-security: max-age=15724800; includeSubDomains
    # <
    # <!DOCTYPE html>
    # <html xmlns="http://www.w3.org/1999/xhtml">
    # <head>
    #     <link rel="stylesheet" type="text/css" href="/static/default.css">
    #     <title>Welcome to Azure Kubernetes Service (AKS)</title>
    
    #     <script language="JavaScript">
    #         function send(form){
    #         }
    #     </script>
    
    # </head>
    # <body>
    #     <div id="container">
    #         <form id="form" name="form" action="/"" method="post"><center>
    #         <div id="logo">Welcome to Azure Kubernetes Service (AKS)</div>
    #         <div id="space"></div>
    #         <img src="/static/acs.png" als="acs logo">
    #         <div id="form">
    #         </div>
    #     </div>
    # </body>
    # * Connection #0 to host aks-app-01.houssem.cloud left intact
    # </html>

# resources:
# How does HTTPS work? What's a CA? What's a self-signed Certificate?
https://www.youtube.com/watch?v=7K0gAYmWWho&list=PLShDm2AZYnK3cWZpOjV7nOpL7plH2Ztz0&index=1