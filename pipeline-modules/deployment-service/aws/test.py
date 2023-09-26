import boto3
import json

# Initialize ECS and SecretsManager clients
ecs_client = boto3.client('ecs')
secrets_client = boto3.client('secretsmanager')


def get_task_definition(task_name):
    response = ecs_client.describe_task_definition(taskDefinition=task_name)
    return response['taskDefinition']


def update_container_image(task_def, repository, tag):
    # Loop through containers and update the image for the specified repository
    for container in task_def['containerDefinitions']:
        if container['image'].startswith(repository):
            container['image'] = f"{repository}:{tag}"


def add_environment_from_file(task_def, env_file):
    # Read the file and add environment variables
    with open(env_file, 'r') as f:
        lines = f.readlines()
        for line in lines:
            name, value = line.strip().split('=')
            task_def['containerDefinitions'][0]['environment'].append({"name": name, "value": value})


def update_secrets(task_def, secret_name):
    secret_arn = secrets_client.describe_secret(SecretId=secret_name)['ARN']
    secret_values = json.loads(secrets_client.get_secret_value(SecretId=secret_name)['SecretString'])

    # Update secrets in the container definition
    for key, value in secret_values.items():
        task_def['containerDefinitions'][0]['secrets'].append({
            "name": key,
            "valueFrom": f"{secret_arn}:{key}::"
        })


def register_task_definition(task_def):
    # Remove some fields that can't be provided to register_task_definition
    for field in ['taskDefinitionArn', 'revision', 'status', 'requiresAttributes', 'compatibilities']:
        task_def.pop(field, None)
    response = ecs_client.register_task_definition(**task_def)
    return response['taskDefinition']['revision']


def update_service(cluster_name, ecs_service_name, task_name, revision):
    ecs_client.update_service(cluster=cluster_name, service=ecs_service_name, taskDefinition=f"{task_name}:{revision}")


if __name__ == '__main__':
    # Define the parameters
    task_name = "your_task_name"
    repository = "your_repo"
    tag = "your_tag"
    env_file = "path_to_env_file"
    secret_name = "your_secret_name"
    cluster_name = "your_cluster_name"
    ecs_service_name = "your_ecs_service_name"

    # Get the current task definition
    task_def = get_task_definition(task_name)

    # Update the container image
    update_container_image(task_def, repository, tag)

    # Add environment variables from file
    add_environment_from_file(task_def, env_file)

    # Update secrets
    update_secrets(task_def, secret_name)

    # Register the new task definition
    new_revision = register_task_definition(task_def)

    # Update the ECS service
    update_service(cluster_name, ecs_service_name, task_name, new_revision)
