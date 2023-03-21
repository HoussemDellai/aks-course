$TAG="dotnet-v7.0.1.01"

docker build --rm -t webapp:$TAG .

docker tag webapp:$TAG houssemdocker/webapp:$TAG

docker push houssemdocker/webapp:$TAG