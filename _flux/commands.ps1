az extension add -n k8s-configuration
az extension add -n k8s-extension

$AKS_NAME="aks-esp-cluster"
$AKS_RG="rg-esp-spoke-aks-cluster"

az group create -n $AKS_RG -l westeurope
az aks create -n $AKS_NAME -g $AKS_RG
az aks get-credentials -n $AKS_NAME -g $AKS_RG --admin

az k8s-configuration flux create -g $AKS_RG -c $AKS_NAME `
-n cluster-config `
--namespace cluster-config `
-t managedClusters `
--scope cluster `
-u https://github.com/Azure/gitops-flux2-kustomize-helm-mt `
--branch main  `
--kustomization name=infra path=./infrastructure prune=true `
--kustomization name=apps path=./apps/staging prune=true dependsOn=["infra"]


# To confirm that the deployment was successful, run the following command:

az k8s-configuration flux show -g $AKS_RG -c $AKS_NAME -n cluster-config -t managedClusters

kubectl get ns
# NAME                STATUS   AGE
# cluster-config      Active   4m32s
# flux-system         Active   7m4s
# nginx               Active   4m25s
# podinfo             Active   2m25s
# redis               Active   4m25s

# With a successful deployment the following namespaces are created:
# 1. flux-system: Holds the Flux extension controllers.
# 2. cluster-config: Holds the Flux configuration objects.
# 3. nginx, podinfo, redis: Namespaces for workloads described in manifests in the Git repository.

# The flux-system namespace contains the Flux extension objects:
# Azure Flux controllers: fluxconfig-agent, fluxconfig-controller
# OSS Flux controllers: source-controller, kustomize-controller, helm-controller, notification-controller

kubectl get deploy -A
# NAMESPACE           NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
# flux-system         fluxconfig-agent                           1/1     1            1           5m9s
# flux-system         fluxconfig-controller                      1/1     1            1           5m9s
# flux-system         helm-controller                            1/1     1            1           5m9s
# flux-system         kustomize-controller                       1/1     1            1           5m9s
# flux-system         notification-controller                    1/1     1            1           5m9s
# flux-system         source-controller                          1/1     1            1           5m9s
# kube-system         extension-agent                            1/1     1            1           6m46s
# kube-system         extension-operator                         1/1     1            1           6m46s
# nginx               nginx-ingress-controller                   1/1     1            1           2m36s
# nginx               nginx-ingress-controller-default-backend   1/1     1            1           2m36s
# podinfo             podinfo                                    1/1     1            1           38s
# ...

# The Flux agent and controller pods should be in a running state. Confirm this using the following command:

kubectl get pods -n flux-system
# NAME                                      READY   STATUS    RESTARTS   AGE
# fluxconfig-agent-54f5566956-5f6cr         2/2     Running   0          9m45s
# fluxconfig-controller-5bf94d7f86-qg7wr    2/2     Running   0          9m45s
# helm-controller-787f4b745c-qq54r          1/1     Running   0          9m45s
# kustomize-controller-7b9c76c466-qnsgt     1/1     Running   0          9m45s
# notification-controller-75dcf8b46-ll6bd   1/1     Running   0          9m45s
# source-controller-795d96f46f-nf7f9        1/1     Running   0          9m45s

Set-Alias -Name grep -Value select-string # if using powershell
kubectl get crds | grep flux
# alerts.notification.toolkit.fluxcd.io                        2023-05-02T10:28:15Z
# buckets.source.toolkit.fluxcd.io                             2023-05-02T10:28:15Z
# fluxconfigs.clusterconfig.azure.com                          2023-05-02T10:28:15Z
# gitrepositories.source.toolkit.fluxcd.io                     2023-05-02T10:28:15Z
# helmcharts.source.toolkit.fluxcd.io                          2023-05-02T10:28:15Z
# helmreleases.helm.toolkit.fluxcd.io                          2023-05-02T10:28:15Z
# helmrepositories.source.toolkit.fluxcd.io                    2023-05-02T10:28:15Z
# imagepolicies.image.toolkit.fluxcd.io                        2023-05-02T10:28:15Z
# imagerepositories.image.toolkit.fluxcd.io                    2023-05-02T10:28:15Z
# imageupdateautomations.image.toolkit.fluxcd.io               2023-05-02T10:28:15Z
# kustomizations.kustomize.toolkit.fluxcd.io                   2023-05-02T10:28:15Z
# ocirepositories.source.toolkit.fluxcd.io                     2023-05-02T10:28:15Z
# providers.notification.toolkit.fluxcd.io                     2023-05-02T10:28:15Z
# receivers.notification.toolkit.fluxcd.io                     2023-05-02T10:28:15Z

kubectl get fluxconfigs -A
# NAMESPACE        NAME             SCOPE     URL                                                       PROVISION   AGE
# cluster-config   cluster-config   cluster   https://github.com/Azure/gitops-flux2-kustomize-helm-mt   Succeeded   11m

kubectl get gitrepositories -A
# NAMESPACE        NAME             URL                                                       AGE   READY   STATUS
# cluster-config   cluster-config   https://github.com/Azure/gitops-flux2-kustomize-helm-mt   12m   True    stored artifact for revision 'main@sha1:3dbc5deb98d5a8099d06def8f40628ab103b0330'

kubectl get helmreleases -A
# NAMESPACE        NAME      AGE   READY   STATUS
# cluster-config   nginx     12m   True    Release reconciliation succeeded
# cluster-config   podinfo   10m   True    Release reconciliation succeeded
# cluster-config   redis     12m   True    Release reconciliation succeeded

kubectl get kustomizations -A
# NAMESPACE        NAME                   AGE   READY   STATUS
# cluster-config   cluster-config-apps    12m   True    Applied revision: main@sha1:3dbc5deb98d5a8099d06def8f40628ab103b0330
# cluster-config   cluster-config-infra   12m   True    Applied revision: main@sha1:3dbc5deb98d5a8099d06def8f40628ab103b0330

kubectl get deploy -n nginx
# NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-ingress-controller                   1/1     1            1           12m
# nginx-ingress-controller-default-backend   1/1     1            1           12m

kubectl get deploy -n podinfo
# NAME      READY   UP-TO-DATE   AVAILABLE   AGE
# podinfo   1/1     1            1           11m

kubectl get all -n redis
# NAME                   READY   STATUS    RESTARTS   AGE
# pod/redis-master-0     1/1     Running   0          13m
# pod/redis-replicas-0   1/1     Running   0          13m
# pod/redis-replicas-1   1/1     Running   0          12m
# pod/redis-replicas-2   1/1     Running   0          11m

# NAME                     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
# service/redis-headless   ClusterIP   None           <none>        6379/TCP   13m
# service/redis-master     ClusterIP   10.0.112.117   <none>        6379/TCP   13m
# service/redis-replicas   ClusterIP   10.0.31.116    <none>        6379/TCP   13m

# NAME                              READY   AGE
# statefulset.apps/redis-master     1/1     13m
# statefulset.apps/redis-replicas   3/3     13m

# list role assignments for an identity
az role assignment list --assignee $GITOPS_IDENTITY --output table
