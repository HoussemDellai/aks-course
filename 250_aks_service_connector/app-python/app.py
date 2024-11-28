import os
from azure.storage.blob import BlobServiceClient
from azure.identity import DefaultAzureCredential


def connect_to_storage_with_identity():
    try:
        # the envs are from the secret reference defined in pod.yaml. And the secret is created by Service Connector
        # when creating the connection between the AKS cluster and the Azure OpenAI service
        client_identity = BlobServiceClient(
            account_url=os.environ.get("AZURE_STORAGEBLOB_RESOURCEENDPOINT"), 
            credential=DefaultAzureCredential()
        )
        containers = client_identity.list_containers()
        print("Connect to Azure Storage succeeded. Find {} containers".format(len(list(containers))))
    except Exception as e:
        print("Connect to Azure Storage failed: {}".format(e))


if __name__ == "__main__":
    connect_to_storage_with_identity()