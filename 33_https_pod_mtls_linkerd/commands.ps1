# Lab: setting TLS certificate in Kubernetes deployment using Service Mesh Linkerd

# 0. Setup

# install linkerd CLI on windows:
choco install linkerd2
# install linkerd CLI on linux 
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh

linkerd version

# 1. Create an AKS cluster

$AKS_RG="rg-aks-linkerd-tls"
$AKS_NAME="aks-cluster"

az group create -n $AKS_RG -l westeurope

az aks create -g $AKS_RG -n $AKS_NAME `
              --kubernetes-version "1.25.2" `
              --enable-managed-identity `
              --node-count 3 `
              --network-plugin azure

# Connect to the cluster

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes

# To check that your cluster is ready to install Linkerd, run:
linkerd check --pre

# instal linkerd CRDs
linkerd install --crds | kubectl apply -f -
# Rendering Linkerd CRDs...
# Next, run `linkerd install | kubectl apply -f -` to install the control plane.

# customresourcedefinition.apiextensions.k8s.io/authorizationpolicies.policy.linkerd.io created
# customresourcedefinition.apiextensions.k8s.io/httproutes.policy.linkerd.io created
# customresourcedefinition.apiextensions.k8s.io/meshtlsauthentications.policy.linkerd.io created
# customresourcedefinition.apiextensions.k8s.io/networkauthentications.policy.linkerd.io created
# customresourcedefinition.apiextensions.k8s.io/serverauthorizations.policy.linkerd.io created
# customresourcedefinition.apiextensions.k8s.io/servers.policy.linkerd.io created
# customresourcedefinition.apiextensions.k8s.io/serviceprofiles.linkerd.io created

# instal linkerd control plane
linkerd install | kubectl apply -f -
# namespace/linkerd created
# clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-identity created
# clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-identity created
# serviceaccount/linkerd-identity created
# clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-destination created
# clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-destination created
# serviceaccount/linkerd-destination created
# secret/linkerd-sp-validator-k8s-tls created
# validatingwebhookconfiguration.admissionregistration.k8s.io/linkerd-sp-validator-webhook-config created
# secret/linkerd-policy-validator-k8s-tls created
# validatingwebhookconfiguration.admissionregistration.k8s.io/linkerd-policy-validator-webhook-config created
# clusterrole.rbac.authorization.k8s.io/linkerd-policy created
# clusterrolebinding.rbac.authorization.k8s.io/linkerd-destination-policy created
# role.rbac.authorization.k8s.io/linkerd-heartbeat created
# rolebinding.rbac.authorization.k8s.io/linkerd-heartbeat created
# clusterrole.rbac.authorization.k8s.io/linkerd-heartbeat created
# clusterrolebinding.rbac.authorization.k8s.io/linkerd-heartbeat created
# serviceaccount/linkerd-heartbeat created
# clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-proxy-injector created
# clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-proxy-injector created
# serviceaccount/linkerd-proxy-injector created
# secret/linkerd-proxy-injector-k8s-tls created
# mutatingwebhookconfiguration.admissionregistration.k8s.io/linkerd-proxy-injector-webhook-config created
# configmap/linkerd-config created
# secret/linkerd-identity-issuer created
# configmap/linkerd-identity-trust-roots created
# service/linkerd-identity created
# service/linkerd-identity-headless created
# deployment.apps/linkerd-identity created
# service/linkerd-dst created
# service/linkerd-dst-headless created
# service/linkerd-sp-validator created
# service/linkerd-policy created
# service/linkerd-policy-validator created
# deployment.apps/linkerd-destination created
# cronjob.batch/linkerd-heartbeat created
# deployment.apps/linkerd-proxy-injector created
# service/linkerd-proxy-injector created
# secret/linkerd-config-overrides created

# check linkerd installed correcly
# linkerd check
# Linkerd core checks
# ===================

# kubernetes-api
# --------------
# √ can initialize the client
# √ can query the Kubernetes API

# kubernetes-version
# ------------------
# √ is running the minimum Kubernetes API version
# √ is running the minimum kubectl version

# linkerd-existence
# -----------------
# √ 'linkerd-config' config map exists
# √ heartbeat ServiceAccount exist
# √ control plane replica sets are ready
# √ no unschedulable pods
# √ control plane pods are ready
# √ cluster networks contains all pods
# √ cluster networks contains all services

# linkerd-config
# --------------
# √ control plane Namespace exists
# √ control plane ClusterRoles exist
# √ control plane ClusterRoleBindings exist
# √ control plane ServiceAccounts exist
# √ control plane CustomResourceDefinitions exist
# √ control plane MutatingWebhookConfigurations exist
# √ control plane ValidatingWebhookConfigurations exist
# √ proxy-init container runs as root user if docker container runtime is used

# linkerd-identity
# ----------------
# √ certificate config is valid
# √ trust anchors are using supported crypto algorithm
# √ trust anchors are within their validity period
# √ trust anchors are valid for at least 60 days
# √ issuer cert is using supported crypto algorithm
# √ issuer cert is within its validity period
# √ issuer cert is valid for at least 60 days
# √ issuer cert is issued by the trust anchor

# linkerd-webhooks-and-apisvc-tls
# -------------------------------
# √ proxy-injector webhook has valid cert
# √ proxy-injector cert is valid for at least 60 days
# √ sp-validator webhook has valid cert
# √ sp-validator cert is valid for at least 60 days
# √ policy-validator webhook has valid cert
# √ policy-validator cert is valid for at least 60 days

# linkerd-version
# ---------------
# √ can determine the latest version
# √ cli is up-to-date

# control-plane-version
# ---------------------
# √ can retrieve the control plane version
# √ control plane is up-to-date
# √ control plane and cli versions match

# linkerd-control-plane-proxy
# ---------------------------
# √ control plane proxies are healthy
# √ control plane proxies are up-to-date
# √ control plane proxies and cli versions match

# Status check results are √

# install demo app
kubectl apply -f https://raw.githubusercontent.com/linkerd/website/main/run.linkerd.io/public/emojivoto.yml
# curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/emojivoto.yml | kubectl apply -f -
# namespace/emojivoto created
# serviceaccount/emoji created
# serviceaccount/voting created
# serviceaccount/web created
# service/emoji-svc created
# service/voting-svc created
# service/web-svc created
# deployment.apps/emoji created
# deployment.apps/vote-bot created
# deployment.apps/voting created
# deployment.apps/web created

# install metric stack and dashboard
linkerd viz install | kubectl apply -f - # install the on-cluster metrics stack
# namespace/linkerd-viz created
# clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-viz-metrics-api created
# clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-viz-metrics-api created
# serviceaccount/metrics-api created
# clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-viz-prometheus created
# clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-viz-prometheus created
# serviceaccount/prometheus created
# clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-viz-tap created
# clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-viz-tap-admin created
# clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-viz-tap created
# clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-viz-tap-auth-delegator created
# serviceaccount/tap created
# rolebinding.rbac.authorization.k8s.io/linkerd-linkerd-viz-tap-auth-reader created
# secret/tap-k8s-tls created
# apiservice.apiregistration.k8s.io/v1alpha1.tap.linkerd.io created
# role.rbac.authorization.k8s.io/web created
# rolebinding.rbac.authorization.k8s.io/web created
# clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-viz-web-check created
# clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-viz-web-check created
# clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-viz-web-admin created
# clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-viz-web-api created
# clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-viz-web-api created
# serviceaccount/web created
# server.policy.linkerd.io/admin created
# authorizationpolicy.policy.linkerd.io/admin created
# networkauthentication.policy.linkerd.io/kubelet created
# server.policy.linkerd.io/proxy-admin created
# authorizationpolicy.policy.linkerd.io/proxy-admin created
# service/metrics-api created
# deployment.apps/metrics-api created
# server.policy.linkerd.io/metrics-api created
# authorizationpolicy.policy.linkerd.io/metrics-api created
# meshtlsauthentication.policy.linkerd.io/metrics-api-web created
# configmap/prometheus-config created
# service/prometheus created
# deployment.apps/prometheus created
# service/tap created
# deployment.apps/tap created
# server.policy.linkerd.io/tap-api created
# authorizationpolicy.policy.linkerd.io/tap created
# clusterrole.rbac.authorization.k8s.io/linkerd-tap-injector created
# clusterrolebinding.rbac.authorization.k8s.io/linkerd-tap-injector created
# serviceaccount/tap-injector created
# secret/tap-injector-k8s-tls created
# mutatingwebhookconfiguration.admissionregistration.k8s.io/linkerd-tap-injector-webhook-config created
# service/tap-injector created
# deployment.apps/tap-injector created
# server.policy.linkerd.io/tap-injector-webhook created
# authorizationpolicy.policy.linkerd.io/tap-injector created
# networkauthentication.policy.linkerd.io/kube-api-server created
# service/web created
# deployment.apps/web created
# serviceprofile.linkerd.io/metrics-api.linkerd-viz.svc.cluster.local created
# serviceprofile.linkerd.io/prometheus.linkerd-viz.svc.cluster.local created

linkerd check
# ...
# Linkerd extensions checks
# =========================

#                               linkerd-viz
# -----------
# √ linkerd-viz Namespace exists
# √ linkerd-viz ClusterRoles exist
# √ linkerd-viz ClusterRoleBindings exist
# √ tap API server has valid cert
# √ tap API server cert is valid for at least 60 days
# √ tap API service is running
# √ linkerd-viz pods are injected
# √ viz extension pods are running
# √ viz extension proxies are healthy
# √ viz extension proxies are up-to-date
# √ viz extension proxies and cli versions match
# √ prometheus is installed and configured correctly
# √ can initialize the client
# √ viz extension self-check

# Status check results are √

linkerd viz dashboard

# access the web ap using port-forward

kubectl -n emojivoto port-forward svc/web-svc 8080:80

# add the app to the mesh
# kubectl get deploy -n emojivoto -o yaml | linkerd inject - | kubectl apply -f -
# deployment "emoji" injected
# deployment "vote-bot" injected
# deployment "voting" injected
# deployment "web" injected
# deployment.apps/emoji configured
# deployment.apps/vote-bot configured
# deployment.apps/voting configured
# deployment.apps/web configured

# deploy sample app

$NAMESPACE_APP="app-07"

kubectl create namespace $NAMESPACE_APP
# namespace/app-07 created

kubectl apply -f app-deploy-svc.yaml -n $NAMESPACE_APP
# service/app-svc created
# deployment.apps/demo-app created

kubectl get pods,svc -n $NAMESPACE_APP
# NAME                            READY   STATUS    RESTARTS   AGE
# pod/demo-app-6944454588-97z8d   1/1     Running   0          12s
# pod/demo-app-6944454588-t8lts   1/1     Running   0          12s
# pod/demo-app-6944454588-xh29t   1/1     Running   0          12s

# NAME              TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
# service/app-svc   ClusterIP   10.0.108.87   <none>        80/TCP    12s

# To add Linkerd’s data plane proxies to a service defined in a Kubernetes manifest, 
# you can use linkerd inject to add the annotations before applying the manifest to Kubernetes.
cat  app-deploy-svc.yaml | linkerd inject - > app-deploy-svc-mesh.yaml
# service "app-svc" skipped
# deployment "demo-app" injected
# template:
#   metadata:
#     annotations:
#       linkerd.io/inject: enabled

# deploy the app
kubectl apply -f app-deploy-svc-mesh.yaml -n $NAMESPACE_APP
# service/app-svc unchanged
# deployment.apps/demo-app configured

# [optional] You can mesh every deployment in a namespace by combining this with kubectl get:
kubectl get deploy -o yaml -n $NAMESPACE_APP | linkerd inject - | kubectl apply -f -

# we can see now we have 2 containers per pod, the second container is the sidecar
kubectl get pods,svc -n $NAMESPACE_APP
# NAME                            READY   STATUS    RESTARTS   AGE
# pod/demo-app-6f9b94cfd7-br67t   2/2     Running   0          2m11s
# pod/demo-app-6f9b94cfd7-p6ptn   2/2     Running   0          2m15s
# pod/demo-app-6f9b94cfd7-v8fns   2/2     Running   0          2m7s

# NAME              TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
# service/app-svc   ClusterIP   10.0.108.87   <none>        80/TCP    14m

# get the list of containers
kubectl get pods -n $NAMESPACE_APP -o jsonpath='{.items[*].spec.containers[*].name}'
# linkerd-proxy demo-app linkerd-proxy demo-app linkerd-proxy demo-app