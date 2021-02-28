You have a .NET application and you want to dockerize it ? This module will walk you through that process.

You'll learn how to:
1. Create a Dockerfile
1. Build docker image
1. Run a docker image
1. List docker images
1. Stop a container
1. Remove a container
1. Remove an image

## 1) Create a Dockerfile

Depending on the programming language and platform for your application, you will find the corresponding Docker image. That image will have all the required dependencies and libraries already installed. 

For example, for .NET Core apps, there are multiple images available that contains the SDK and/or runtime for multiple versions.

You typically find these images on a Container Registry like hub.docker.com.
// From within the folder cd app-dotnet
docker build .

