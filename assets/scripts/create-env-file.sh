#!/bin/bash

##############################################
# Deprecated Notice - Please Use env.sh Script
##############################################

# This script is deprecated. Please use env.sh for environment variable management.

# Migration Instructions:
# - Replace 'cat {{ pipeline_env_file }}' with 'env.sh all --non-secrets --quoted'
# - Replace 'cat {{ pipeline_secret_file }}' with 'env.sh all --secrets --quoted'
# - Additional options are available. Run 'env.sh --help' to learn more.

set -e
sn=`basename $0`

[ $# -lt 2 ] && echo "$0: less than 2 input parameters provided - skipping env file creation for $@" exit 0

ENV_FILE_NAME=$1
shift
EXPORTED_ENV_NAMES=$@

echo "=== ${sn}: Creating ${ENV_FILE_NAME}"

for name in ${EXPORTED_ENV_NAMES}
do
    printf "$name=%s\n" "$(eval printf "%s" "\"\$$name\"" | jq -aRs .)" >> $ENV_FILE_NAME
    printf "Exporting variable '$name'\n"
done

echo "=== ${sn}: Done"
