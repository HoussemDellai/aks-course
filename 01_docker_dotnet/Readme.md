In this tutorial, we have a .NET application and we want to dockerize it. This module will walk through that process.

We'll learn how to:
1. Create a Dockerfile
1. Build docker image
1. Run a docker image
1. Stop a container
1. Remove a container
1. Remove an image
1. Working with Docker Compose

## Introduction to containers

Depending on the programming language and platform for your application, we will find the corresponding Docker image. That image will have all the required dependencies and libraries already installed. 

For example, for .NET Core apps, there are multiple images available that contains the SDK and/or runtime for multiple versions.

These images are typically available on a Container Registry like hub.docker.com, for [.NET Core](https://hub.docker.com/_/microsoft-dotnet), for [Java](https://hub.docker.com/_/openjdk), for [NodeJs](https://hub.docker.com/_/node).

There are also images available for database engines like [MySQL](https://hub.docker.com/_/mysql), [SQL Server](https://hub.docker.com/_/microsoft-mssql-server), [Oracle](https://hub.docker.com/_/oracle-database-enterprise-edition), Cassandra, etc.


## 1) Create a Dockerfile

We have a sample .NET Core 5.0 web MVC application. We can run this application through the .NET cli tool:

```dotnetcli
$ dotnet build
$ dotnet run
```

Now we want to run this same application in a Docker container. The process is similar to running the application inside a virtual machine:
1. Choose a base VM running Linux or Windows.
1. Install the application dependencies and libraries (typically app SDK and Runtime). 
1. Build the application. 
1. Deploy the application into the VM.

With containers, the process will be:

1. Choose a base docker image with application dependencies and libraries (steps 1 and 2 for VMs).
1. Build the application.
1. Deploy the application into the image.

This process will be described into a file called *Dockerfile*. Let's see the following example:


```dockerfile
# Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:5.0-buster-slim AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim AS build
WORKDIR /src
COPY "WebApp.csproj" .
RUN dotnet restore "WebApp.csproj"
COPY . .
RUN dotnet build "WebApp.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "WebApp.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "WebApp.dll"]
```

Note that in this Dockerfile, we are using 2 different docker images. One is used to build the application (sdk). And a second one is used to run the app (aspnet).

## 2) Build docker image

Let's first make sure that we have Docker up and running:

```bash
$ docker run hello-world
```

Then we go to the application folder (app-dotnet) and run the following command to build the image (don't forget the dot "." at the end which referes to the current folder):

```bash
$ docker build .
```

Run the same command and assign a name to the image:

```bash
$ docker build --rm -t webapp:1.0 .
```

Check the images exists:

```bash
$ docker images
```

## 3) Run a docker image

Let's run a container based on the image created earlier:

```bash
$ docker run --rm -d -p 5000:80/tcp webapp:1.0
```

Open web browser on *localhost:5000* to see the application running.

List the running docker containers:

```bash
$ docker ps
```

## 3) Run a command inside a docker container
Explore the command docker exec.
```bash
$ docker exec <CONTAINER_ID> -- ls
```

## 5) Stop a container

Explore the command docker stop.
```bash
$ docker stop <CONTAINER_ID>
```

## 6) Remove a container

Explore the command docker rm.
```bash
$ docker rm <CONTAINER_ID>
```

## 7) Remove an image

Explore the command docker rmi.
```bash
$ docker rmi <IMAGE_ID_OR_NAME>
```

## 8) Working with Docker Compose

When we want to run multiple applications together (for micro/multi services for example), working with the commands to build and run each image independently is time consuming. To solve this issue, Dcoker invented the Compose file. It can compose and configure multiple services in one single YAML file. Using docker compose, we can build and run multiple images, configure applications to connect to each other, configure docker networking, configure environment variables, etc.

Let's see the following *docker-compose.yml* file:

```yml
# docker-compose.yml
version: "3"
services:
  web:
    container_name: webapp
    build: 
      dockerfile: Dockerfile
      context: app-dotnet
    ports:
      - "8008:80"
    environment:
      ConnectionStrings__WebAppContext: "Server=db;Database=ProductsDB;User=sa;Password=@Aa123456;"
    depends_on:
      - db

  db:
    container_name: mssql-db
    image: "microsoft/mssql-server-linux"
    expose:
      - "1433"
    environment:
      SA_PASSWORD: "@Aa123456"
      ACCEPT_EULA: "Y"
    ports:
      - "1433:1433"
```

Let's build and run the compose file:

```bash
$ docker-compose build
$ docker-compose up
```

## 9) Working with Container Registry (Docker Hub)

Create a Docker Hub account at: https://hub.docker.com/.
Login to Docker Hub registry:

```bash
$ docker login
```

Tag the image with your Docker Hub ID (for me it is *houssemdocker*):

```bash
$ docker tag webapp:1.0 <houssemdocker>/webapp:1.0
```

Push the image to the registry:

```bash
$ docker push <houssemdocker>/webapp:1.0
```

## 10) Working with Container Registry (Azure Container Registry)

Make sure yiur have an Azure subscription and you have installed Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli.

Create a new Azure Container Registry (ACR) in Azure portal.

Enable *Admin* credentials from ACR.

Login to ACR:

```bash
$acrName="myacr"
az acr login -n $acrName --expose-token
```

Build the image on ACR (Optional):

```bash
az acr build -t "$acrName.azurecr.io/webapp:1.0" -r $acrName .
```

Note that image is already pushed to ACR.