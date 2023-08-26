# Creating and installing Helm Charts
 

## Introduction
 
Kubernetes is a popular open-source container orchestration platform that allows you to deploy, scale, and manage containerized applications. Helm is a package manager for Kubernetes that simplifies the process of installing and managing applications on a Kubernetes cluster. Helm provides a way to package Kubernetes resources, such as deployments, services, and config maps, into a single, reusable unit called a chart.

This workshop will guide you through the process of creating and installing a Helm chart on a Kubernetes cluster. You will learn how to create a sample chart, check the syntax of the chart, install the chart, override chart values, install a chart with custom values, install a chart in different environments, upgrade a chart, and delete a chart.

## Prerequisites
 
- A Kubernetes cluster
- Helm installed on your machine
- Basic knowledge of Kubernetes concepts and Helm charts

## 1. Install Helm
 
Helm is a package manager for Kubernetes that simplifies the process of installing and managing applications on a Kubernetes cluster. Follow the guide at [helm.sh/docs/intro/install/](https://helm.sh/docs/intro/install/) to install Helm on your machine. Once installed, verify the version by running:

```sh
helm version  
```

This should output the version of Helm that you have installed.

## 2. Create a Sample Chart
 
A Helm chart is a collection of files that describe a set of Kubernetes resources that can be deployed together as a single unit.
Create a sample Helm chart by running the following command:

```sh
helm create firstchart  
```

This will create a basic Helm chart in a folder named firstchart.

```sh
firstchart
│   .helmignore
│   Chart.yaml
│   values.yaml
│
└───templates
    │   deployment.yaml
    │   hpa.yaml
    │   ingress.yaml
    │   NOTES.txt
    │   service.yaml
    │   serviceaccount.yaml
    │   _helpers.tpl
    │
    └───tests
            test-connection.yaml
```

## 3. Check Helm Syntax
 
Before installing a Helm chart, it's a good idea to check the syntax of the chart to ensure that it is valid. 
Check the syntax of the Helm chart by running the following command:

```sh
helm lint firstchart
```
 
This will check the syntax of the chart and ensure that it is valid.

## 4. Install a Helm Chart into Kubernetes
 
Once you have created a Helm chart, you can install it on your Kubernetes cluster.
Install the Helm chart by running the following command:

```sh
helm install my-app firstchart  
```

This will install the Helm chart with the release name my-app.

Verify the created resources. You should see a Deployment, Service, HPA and Ingress resources.

```sh
kubectl get deploy,svc,hpa,ingress
```

## 5. Override Chart Values in command line
 
Helm charts can include default values that are used when the chart is installed.
You can override these default values by specifying them on the command line when you install the chart.
Override the default chart values by running the following command.

```sh
helm install --set image.tag="1.21.0" my-app firstchart  
```

This will install the chart with the specified image tag.

## 6. Install a Chart with custom values
 
You can also install a chart with a custom `values.yaml` file that specifies the values to use when installing the chart.
Create a custom `values.yaml` file.

```yaml
# values.yaml
replicaCount: 1
image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21.0"
service:
  type: ClusterIP
  port: 80
ingress:
  enabled: false
  className: ""
```

Then install the chart with the following command:

```sh
helm install -f values.yaml my-app firstchart  
```

This will install the chart with the values specified in the `values.yaml` file.

## 7. Install a Chart in different Environments (Dev/Test/Prod)
 
You may want to install a chart to different environments with different values. 
You can achieve this by specifying different value files when installing the chart.
For example, `values.dev.yaml` file contain values for the `dev` environment.
And `values.prod.yaml` file contain values for the `production` environment.

To deploy the chart to a dev cluster, you can run the following command:

```sh
helm install -f values.dev.yaml my-app firstchart  
```

To deploy the chart to a prod cluster, you can run the following command:

```sh
helm install -f values.prod.yaml my-app firstchart  
```

## 8. Install a Chart with Overrides and Custom Values
 
You can also install a chart with both overrides and a custom values.yaml file. For example, to install the chart with

the specified image tag and the values specified in the values.yaml file, run the following command:

```sh
helm install -f values.yaml --set image.tag="1.19.0" my-app firstchart  
```

## 9. List installed Charts
 
You can list the installed charts by running the following command:

```sh
helm list  
```

This will show the release names and status of all installed charts.

## 10. Upgrade a Chart
 
You can upgrade a chart by running the following command:

```sh
helm upgrade --install --set service.type=LoadBalancer my-app firstchart  
```

This will upgrade the chart with the specified values and install it if it doesn't already exist.

## 11. Delete a Chart
 
You can delete a chart by running the following command:

```sh
helm uninstall my-app  
```

This will delete the chart with the release name my-app.

## 12. Reuse an existing Helm Repository

Until now, we have created and used our own helm chart, specific for our application.
There are many other helm charts available in opensource.
These helm charts are really helpful to install packaged applications like Ingress Controller, Database, Wordpress, GitOps, monitoring tools, etc.
These helm charts are available in `helm repository` like the one provided by `Bitnami`. Here is the link: [github.com/bitnami/charts/tree/main/bitnami](https://github.com/bitnami/charts/tree/main/bitnami).
You can download and add a Helm repository to your list of repositories in your machine by running the following command.

```sh
helm repo add bitnami https://charts.bitnami.com/bitnami  
```

This will add the Bitnami Helm repository to your list of repositories.

## 13. Install a Chart from a Repository
 
You can install a chart from a repository by running the following command:

```sh
helm install my-release bitnami/jenkins  
```

This will install the Jenkins chart from the Bitnami repository with the release name my-release.

## Conclusion
 
In this workshop, you learned how to create and install a Helm chart on a Kubernetes cluster. You learned how to create a sample chart, check the syntax of the chart, install the chart, override chart values, install a chart with custom values, install a chart in different environments, upgrade a chart, and delete a chart. Helm is a powerful tool that can simplify the process of deploying and managing applications on a Kubernetes cluster. With Helm, you can package Kubernetes resources into a single, reusable unit and deploy them consistently across different environments.