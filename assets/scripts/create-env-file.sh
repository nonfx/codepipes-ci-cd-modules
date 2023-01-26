#!/bin/bash
set -e
sn=`basename $0`

[ $# -lt 2 ] && echo "$0: must supply at least 2 parameters - env_file_name, <list of exported variables>" && exit 1

ENV_FILE_NAME=$1
shift
EXPORTED_ENV_NAMES=$@

echo "=== ${sn}: Creating ${ENV_FILE_NAME}"

for name in ${EXPORTED_ENV_NAMES}
do
    printf "$name=%s\n" "$(eval printf "%s" "\$$name" | jq -aRs .)" >> $ENV_FILE_NAME
    printf "Exporting variable '$name'\n"
done

echo "=== ${sn}: Done"
