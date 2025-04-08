# Deploying apps into AKS using ArgoCD

## Installing ArgoCD into the cluster

```sh
kubectl create namespace argocd

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Expose ArgoCD on public IP
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# get password then decode base64
kubectl get secret argocd-initial-admin-secret -n argocd -o yaml
```

## Deploying a sample application

We'll deploy the sample application prvided in `kubernetes` folder.

First create the namespace for the application.

```sh
kubectl create namespace webapp
```

Then deploy the app through ArgoCD.

The ArgoCD's `Application` object will be used to create the app. Here is its configuration.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app01
  namespace: argocd
spec:
  destination:
    namespace: webapp
    server: https://kubernetes.default.svc
  source:
    path: kubernetes
    repoURL: https://github.com/HoussemDellai/aks-course
    targetRevision: HEAD
  project: default
```

Let's deploy it to AKS through ArgoCD server.

```sh
kubectl apply -f app-argocd.yaml
```

Check the app is installed correctly.

```sh
kubectl get application -n argocd
```

## Exploring ArgoCD CLI

Installing ArgoCD CLI on Windows

```sh
winget install -e --id argoproj.argocd
```

## Login to ArgoCD server

Replace the IP with your ArgoCD server IP.

```sh
argocd login 4.178.217.48:80
# WARNING: server certificate had error: tls: failed to verify certificate: x509: certificate signed by unknown authority. Proceed insecurely (y/n)? y
# Username: admin
# Password:
# 'admin:login' logged in successfully
# Context '4.178.217.48:80' updated
```

```sh
argocd app get app01
# Name:               argocd/app01
# Project:            default
# Server:             https://kubernetes.default.svc
# Namespace:          webapp
# URL:                https://4.178.217.48:80/applications/app01
# Source:
# - Repo:             https://github.com/HoussemDellai/aks-course
#   Target:           HEAD
#   Path:             290_gitops_argocd/kubernetes
# SyncWindow:         Sync Allowed
# Sync Policy:        Manual
# Sync Status:        Synced to HEAD (932985c)
# Health Status:      Healthy

# GROUP  KIND        NAMESPACE  NAME             STATUS  HEALTH   HOOK  MESSAGE
#        Service     webapp     inspectorgadget  Synced  Healthy        service/inspectorgadget created
# apps   Deployment  webapp     inspectorgadget  Synced  Healthy        deployment.apps/inspectorgadget created
```