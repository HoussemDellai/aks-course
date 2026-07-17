# Running Github Actions Runners Controller on Azure AKS

Install the Github Actions Runners Controller on Azure AKS using the following command:

```sh
helm install arc `
    --namespace arc-systems `
    --create-namespace `
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
```

Installing the runner scale set

```
kubectl create namespace arc-runners
```

```sh
kubectl create secret generic pre-defined-secret `
   --namespace=arc-runners `
   --from-literal=github_app_id=4322550 `
   --from-literal=github_app_installation_id=147167032 `
   --from-literal=github_app_private_key='-----BEGIN RSA PRIVATE KEY-----d061a2876ba7d488939485e677de6f7e9d66fa82'
```

```sh
helm upgrade arc-runner-set `
    --install `
    --namespace arc-runners `
    --create-namespace `
    --values ./kubernetes/gha-runner-scale-set/values.yaml `
    --set githubConfigUrl="https://github.com/HoussemDellai/aks-course" `
    --set githubConfigSecret="pre-defined-secret" `
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```