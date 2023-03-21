# Logging with EFK in Kubernetes

This workshop shows how to install the EFK (Elasticsearch, Fluentd and Kibana) stack in Kubernetes using Helm, to get application logs.

These are the amin commands used to install EFK:

```bash
$ helm install elasticsearch stable/elasticsearch
```

wait for few minutes..

```bash
$ kubectl apply -f .\fluentd-daemonset-elasticsearch.yaml
```

```bash
$ helm install kibana stable/kibana -f kibana-values.yaml
```

```bash
$ kubectl apply -f .\counter.yaml
```

Open Kibana dashboard.

The workshop is available as a video on youtube:

<a href="https://www.youtube.com/watch?v=mwToMPpDHfg&list=PLpbcUe4chE7-Eb5DUTKcR80rPAK-ZnefW"><img src="https://github.com/HoussemDellai/EFK-Kubernetes/blob/master/images/efk-sketch-light.jpg?raw=true" width="80%"></a>

