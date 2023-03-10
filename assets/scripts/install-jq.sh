#!/bin/bash
set -e
sn=`basename $0`

# Parameter (optional) JQ version to install
JQ_VERSION=${1:-1.6}

echo "=== ${sn}: Checking jq v${JQ_VERSION}"

[ $(jq --version 2>&1) = "jq-${JQ_VERSION}" ] && echo "=== ${sn}: Required jq version is already installed" && exit 0

echo "=== ${sn}: Installing jq v${JQ_VERSION}"

curl -sLJO https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64
chmod +x jq-linux64
mv jq-linux64 /usr/local/bin/jq

echo "=== ${sn}: Done"
