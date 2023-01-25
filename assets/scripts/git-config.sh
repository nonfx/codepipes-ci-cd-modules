#!/bin/bash
set -e
sn=`basename $0`
script_dir=`dirname $0`

[ $# -ne 5 ] && echo "$0: must supply 5 parameters - git_username, git_password, git_repo, git_config_path and git_creds_path" && exit 1

GIT_USERNAME=$1
GIT_PASSWORD=$2
GIT_REPO=$3
GIT_CFG_PATH=$4
GIT_CREDS_PATH=$5

echo "=== ${sn}: Configuring Git"

git config --file ${GIT_CFG_PATH} credential.helper "store --file ${GIT_CREDS_PATH}"
git config --file ${GIT_CFG_PATH} credential.useHttpPath true
git config --file ${GIT_CFG_PATH} credential.interactive never

server=$(${script_dir}/url_parser.sh $GIT_REPO "\$scheme://\$server")
# url-encode passwords as the password tend to contain special characters that can break the url syntax.
git_password_encoded=$(printf %s $GIT_PASSWORD | jq -sRr @uri)
git_url_with_auth=$(${script_dir}/url_parser.sh $GIT_REPO "\$scheme://$GIT_USERNAME:$git_password_encoded@\$server")
git config --global url."$git_url_with_auth".insteadOf "${server}"

echo "=== ${sn}: Done"
