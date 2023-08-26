# Logging with EFK in Kubernetes

This workshop shows how to install the EFK (Elasticsearch, Fluentd and Kibana) stack in Kubernetes using Helm, to get application logs.

These are the amin commands used to install EFK:

```sh
helm install elasticsearch stable/elasticsearch
```

wait for few minutes..

```sh
kubectl apply -f .\fluentd-daemonset-elasticsearch.yaml
```

```sh
helm install kibana stable/kibana -f kibana-values.yaml
```

```sh
kubectl apply -f .\counter.yaml
```

Open Kibana dashboard.

The workshop is available as a video on youtube:

<a href="https://www.youtube.com/watch?v=mwToMPpDHfg&list=PLpbcUe4chE7-Eb5DUTKcR80rPAK-ZnefW">![](images/04_efk_logging__efk-sketch-light.png)</a>

