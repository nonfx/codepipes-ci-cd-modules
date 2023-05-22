#!/bin/bash
set -e

# Load environment variables from .secret.env file
function load_env_variables() {
  file_path="$1"
  env_vars=$(<"$file_path")
  echo $env_vars
}

# Check if the secret already exists in AWS Secrets Manager
function check_secret_exists() {
  secret_name="$1"
  aws secretsmanager describe-secret --secret-id "$secret_name" >/dev/null 2>&1
  return $?
}

# Create or update the secret in AWS Secrets Manager
function create_or_update_secret() {
  secret_name=$1
  env_vars="$2"

  secret_string="{"
  while IFS="=" read -r key value; do
    secret_string+="\"$key\":$value,"
  done <<< "$env_vars"
  secret_string="${secret_string%,}"
  secret_string+="}"
  echo "Secret String: $secret_string"
  if check_secret_exists "$secret_name"; then
    # Clear the existing secret content
    aws secretsmanager update-secret --secret-id $secret_name --secret-string "{}"

    # Update the secret with the new content
    aws secretsmanager update-secret --secret-id $secret_name --secret-string $secret_string
  else
    aws secretsmanager create-secret --name $secret_name --secret-string $secret_string
  fi
}


# Get the ARN of the secret
function get_secret_arn() {
  secret_name=$1
  aws secretsmanager describe-secret --secret-id $secret_name | jq -r '.ARN'
}

# Get the secret content
function get_secret_content() {
  secret_name=$1
  aws secretsmanager get-secret-value --secret-id $secret_name --output json | jq -r '.SecretString'
}

