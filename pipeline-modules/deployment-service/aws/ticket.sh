#!/bin/bash

# Functions

# Fetch details of the provided ECS Task Definition.
get_task_details() {
    aws ecs describe-task-definition --task-definition "$1"
}

# Retrieve the name of the container from the task definition that starts with the specified image prefix.
get_container_name() {
    echo "$1" | jq -r ".taskDefinition.containerDefinitions[] | select(.name | startswith(\"$2\")) | .name"
}

# Get the log configuration of a container using its image prefix.
get_log_configuration() {
    echo "$1" | jq -r -c ".taskDefinition.containerDefinitions[] | select(.name | startswith(\"$2\")) | .logConfiguration"
}

# Update secrets in the task definition.
update_task_definition_secrets() {
    local task_definition_file="$1"
    local secret_name="$2"
    local secret_arn
    secret_arn=$(get_secret_arn "$secret_name")
    local secret_content
    secret_content=$(get_secret_content "$secret_name")
    local secret_content_keys
    secret_content_keys=$(jq --arg secret_arn "$secret_arn" -c '[to_entries[] | {name: .key, valueFrom: ($secret_arn + ":" + .key + "::") }]' <<< "$secret_content")
    jq --argjson keys "$secret_content_keys" '(.containerDefinitions[] | .secrets) = (.secrets // []) + $keys' "$task_definition_file" > "tmp_task_definition.json"
    mv "tmp_task_definition.json" "$task_definition_file"
}

# Load environment variables from the given file.
load_env_variables() {
  file_path="$1"
  env_vars=$(<"$file_path")
  echo "$env_vars"
}

# Check if a secret with the given name exists in AWS Secrets Manager.
check_secret_exists() {
  secret_name="$1"
  aws secretsmanager describe-secret --secret-id "$secret_name" >/dev/null 2>&1
  return $?
}

# Create a new secret or update an existing one in AWS Secrets Manager.
create_or_update_secret() {
  local secret_name="$1"
  local env_vars="$2"
  local secret_string="{"

  while IFS="=" read -r key value; do
    value=${value//\"/}
    secret_string+="\"$key\":\"$value\","
  done <<< "$env_vars"
  secret_string="${secret_string%,}}"

  if check_secret_exists "$secret_name"; then
    aws secretsmanager update-secret --secret-id "$secret_name" --secret-string "{}"
    aws secretsmanager update-secret --secret-id "$secret_name" --secret-string "$secret_string"
  else
    aws secretsmanager create-secret --name "$secret_name" --secret-string "$secret_string"
  fi
}

# Retrieve the ARN of the secret using its name.
get_secret_arn() {
  secret_name="$1"
  aws secretsmanager describe-secret --secret-id "$secret_name" | jq -r '.ARN'
}

# Fetch the content of the secret.
get_secret_content() {
  secret_name="$1"
  aws secretsmanager get-secret-value --secret-id "$secret_name" --output json | jq -r '.SecretString'
}

# Create a new container definition for updating.
create_container_def_for_update() {
    local logConfig="$1"
    local secrets="$2"
    local otherContainers="$3"
    local updatedContainerDef

    updatedContainerDef="{
        \"name\": \"$CONTAINER_NAME\",
        \"image\": \"$REPO:$TAG\",
        \"memory\": $CONTAINER_MEM,
        \"cpu\": $CONTAINER_CPU,
        \"portMappings\": [{
            \"containerPort\": $CONTAINER_PORT,
            \"hostPort\": $HOST_PORT,
            \"protocol\": \"tcp\"
        }],
        \"environment\": ["
    while IFS= read -r line; do
        value=${line#*=}
        name=${line%%=*}
        updatedContainerDef+=$(printf "{\n \"name\" : \"%s\", \"value\": \"%s\" \n}," "$name" "$value")
    done < "$PIPELINE_ENV_FILE"
    updatedContainerDef=$(echo "$updatedContainerDef" | sed '$ s/,$//')
    updatedContainerDef+=$(echo "],\"logConfiguration\":$logConfig,\"secrets\":$secrets}")

    local mergedDefs="[$updatedContainerDef,$otherContainers]"
    echo "$mergedDefs"
}

echo "Loading environment variables..."

env_vars=$(load_env_variables ".secret.env")
create_or_update_secret {{secret_name}} "$env_vars"
#update_task_definition_secrets "containerDef.json"

# Variables
TASK_NAME="racer-app-task-definition"
REPO="public.ecr.aws/docker/library/tomcat:9.0.80-jdk8-corretto-al2"
TAG="it_works"
CONTAINER_MEM="2048"
CONTAINER_CPU="1024"
CONTAINER_PORT="3000"
HOST_PORT="3000"
PIPELINE_ENV_FILE=".env"
EXEC_ROLE_ARN="arn:aws:iam::517787345042:role/test-ecs-iam-role-v2"

# Main Logic
taskDetails=$(get_task_details "$TASK_NAME")
CONTAINER_NAME=$(get_container_name "$taskDetails" "$REPO")
logConfiguration=$(get_log_configuration "$taskDetails" "$REPO")

# Extract all other container definitions excluding the one to be updated.
otherContainers=$(echo "$taskDetails" | jq -r -c ".taskDefinition.containerDefinitions[] | select(.name != \"$CONTAINER_NAME\")")

updatedContainerDefs=$(create_container_def_for_update "$logConfiguration" "$secrets" "$otherContainers")

# Register the new task definition.
aws ecs register-task-definition --family "$TASK_NAME" --network-mode "awsvpc" \
  --execution-role-arn "$EXEC_ROLE_ARN" --task-role-arn "$EXEC_ROLE_ARN" \
  --container-definitions "$updatedContainerDefs" \
  --requires-compatibilities "EC2" "FARGATE" \
  --cpu "$CONTAINER_CPU" --memory "$CONTAINER_MEM"

# TODO: Add logic for updating services, etc.
