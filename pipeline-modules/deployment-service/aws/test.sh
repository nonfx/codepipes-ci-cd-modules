#!/bin/bash

# Functions
get_task_details() {
    aws ecs describe-task-definition --task-definition "$1"
}

get_container_name() {
    echo "$1" | jq -r ".taskDefinition.containerDefinitions[] | select(.image | startswith(\"$2\")) | .name"
}

get_log_configuration() {
    echo "$1" | jq -r -c ".taskDefinition.containerDefinitions[] | select(.image | startswith(\"$2\")) | .logConfiguration"
}

get_secrets() {
    echo "$1" | jq -r -c ".taskDefinition.containerDefinitions[] | select(.image | startswith(\"$2\")) | .secrets"
}

create_container_def_for_update() {
    local logConfig="$1"
    local secrets="$2"
    local otherContainers="$3"

    # Create the updated container definition
    local updatedContainerDef=$(cat <<EOL
{
    "name": "$CONTAINER_NAME",
    "image": "$REPO:$TAG",
    "memory": $CONTAINER_MEM,
    "cpu": $CONTAINER_CPU,
    "portMappings": [{
        "containerPort": $CONTAINER_PORT,
        "hostPort": $HOST_PORT,
        "protocol": "tcp"
    }],
    "environment": [
EOL
    )

    while IFS= read -r line; do
        value=${line#*=}
        name=${line%%=*}
        updatedContainerDef+=$(printf "{\n \"name\" : \"%s\", \"value\": \"%s\" \n}," "$name" "$value")
    done < "$PIPELINE_ENV_FILE"

    # Remove trailing comma, add the log configuration, and secrets
    updatedContainerDef=$(echo "$updatedContainerDef" | sed '$ s/,$//')
    updatedContainerDef+=$(echo "],\"logConfiguration\":$logConfig,\"secrets\":$secrets}")

    # Merging the updated container with other container definitions
    local mergedDefs="[$updatedContainerDef,$otherContainers]"
    echo "$mergedDefs"
}

# Variables
TASK_NAME="racer-app-task-definition"
REPO="887353307671.dkr.ecr.ap-southeast-1.amazonaws.com/racer-staging-ecr"
TAG="it_works"
CONTAINER_MEM="2048"
CONTAINER_CPU="1024"
CONTAINER_PORT="3000"
HOST_PORT="3000"
PIPELINE_ENV_FILE=".env"
EXEC_ROLE_ARN="arn:aws:iam::973993367236:role/racer-ecs-iam-role-v2"

# Main Logic
taskDetails=$(get_task_details "$TASK_NAME")
CONTAINER_NAME=$(get_container_name "$taskDetails" "$REPO")
logConfiguration=$(get_log_configuration "$taskDetails" "$REPO")
secrets=$(get_secrets "$taskDetails" "$REPO")

# Extract all other container definitions excluding the one to be updated
otherContainers=$(echo "$taskDetails" | jq -r -c ".taskDefinition.containerDefinitions[] | select(.name != \"$CONTAINER_NAME\")")

updatedContainerDefs=$(create_container_def_for_update "$logConfiguration" "$secrets" "$otherContainers")

# Now use this definition to register a new task definition
aws ecs register-task-definition --family "$TASK_NAME" --network-mode "awsvpc" \
  --execution-role-arn "$EXEC_ROLE_ARN" --task-role-arn "$EXEC_ROLE_ARN" \
  --container-definitions "$updatedContainerDefs" \
  --requires-compatibilities "EC2" "FARGATE" \
  --cpu "$CONTAINER_CPU" --memory "$CONTAINER_MEM"

# Add further logic for updating services, etc.
