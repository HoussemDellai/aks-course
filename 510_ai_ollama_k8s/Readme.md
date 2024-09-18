# Ollama AI model deployment on Azure Kubernetes Service (AKS)

https://github.com/open-webui/open-webui/tree/main/kubernetes/manifest/base

```sh
$AKS_RG="rg-aks-ollama-llm"
$AKS_NAME="aks-cluster"

# create resource group
az group create -n $AKS_RG -l swedencentral

# create an AKS cluster 
az aks create -n $AKS_NAME -g $AKS_RG --network-plugin azure --network-plugin-mode overlay -k 1.30.3 --node-vm-size Standard_D4s_v5

# get credentials
az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

# deploy Ollama server and client app (Open-WebUI) into AKS
kubectl apply -f .

# check the install
kubectl get all -n open-webui

# install LLM model likw phi3 or llama3.1 into ollama server
kubectl exec ollama-0 -n ollama -it -- ollama run phi3

# get the public IP of the client service
kubectl get svc -n open-webui
```

Here are some example models that can be used in `ollama` [available here](https://github.com/ollama/ollama/blob/main/README.md#model-library):

| Model              | Parameters | Size  | Download                       |
| ------------------ | ---------- | ----- | ------------------------------ |
| Llama 3.1          | 8B         | 4.7GB | `ollama run llama3.1`          |
| Llama 3.1          | 70B        | 40GB  | `ollama run llama3.1:70b`      |
| Llama 3.1          | 405B       | 231GB | `ollama run llama3.1:405b`     |
| Phi 3 Mini         | 3.8B       | 2.3GB | `ollama run phi3`              |
| Phi 3 Medium       | 14B        | 7.9GB | `ollama run phi3:medium`       |
| Gemma 2            | 2B         | 1.6GB | `ollama run gemma2:2b`         |
| Gemma 2            | 9B         | 5.5GB | `ollama run gemma2`            |
| Gemma 2            | 27B        | 16GB  | `ollama run gemma2:27b`        |
| Mistral            | 7B         | 4.1GB | `ollama run mistral`           |
| Moondream 2        | 1.4B       | 829MB | `ollama run moondream`         |
| Neural Chat        | 7B         | 4.1GB | `ollama run neural-chat`       |
| Starling           | 7B         | 4.1GB | `ollama run starling-lm`       |
| Code Llama         | 7B         | 3.8GB | `ollama run codellama`         |
| Llama 2 Uncensored | 7B         | 3.8GB | `ollama run llama2-uncensored` |
| LLaVA              | 7B         | 4.5GB | `ollama run llava`             |
| Solar              | 10.7B      | 6.1GB | `ollama run solar`             |

