with open(file="namespace.yaml") as f:

    namespace = yaml.safe_load(f)

    core_v1 = client.CoreV1Api()

    response = core_v1.create_namespace(body=namespace)

    print(f"Namespace created. Status='{response.metadata.name}'")