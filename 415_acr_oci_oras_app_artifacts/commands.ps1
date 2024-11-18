# install oras cli

winget install oras

$RG="rg-acr-oci-415"
$ACR_NAME="acrociregistry13"
$REGISTRY="$ACR_NAME.azurecr.io"
$TAG="v1"
$IMAGE="$REGISTRY/${REPO}:$TAG"

# az login # login to Azure if needed
az group create -n $RG -l swedencentral
az acr create -n $ACR_NAME -g $RG --sku Standard
az acr login -n $REGISTRY --expose-token

$TOKEN=$(az acr login -n $REGISTRY --expose-token --output tsv --query accessToken)

# Sign in with ORAS

oras login $REGISTRY --username "00000000-0000-0000-0000-000000000000" --password $TOKEN

# push a nuget package

oras push $REGISTRY/nuget/newtonsoft:13.0.3 --artifact-type package/nuget ./newtonsoft.json.13.0.3.nupkg

# check the resource in ACR

oras manifest fetch --pretty $REGISTRY/nuget/newtonsoft:13.0.3

# pull the nuget package

mkdir ./download

oras pull -o ./download $REGISTRY/nuget/newtonsoft:13.0.3

# Push and Pull OCI Artifacts with ORAS

oras push $REGISTRY/samples/artifact:readme --artifact-type readme/example ./readme.md:application/markdown

# To view the manifest created as a result of oras push, use oras manifest fetch:

oras manifest fetch --pretty $REGISTRY/samples/artifact:readme

# Pull an artifact

mkdir ./download

oras pull -o ./download $REGISTRY/samples/artifact:readme

# Remove the artifact (optional)

oras manifest delete $REGISTRY/samples/artifact:readme
