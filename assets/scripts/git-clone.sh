#!/bin/bash
set -e
sn=`basename $0`

[ $# -ne 3 ] && echo "$0: must supply 3 parameters - git_repo, git_ref, source_code_path" && exit 1

GIT_REPO=$1
GIT_REF=$2
SOURCE_CODE_PATH=$3

echo "=== ${sn}: Cloning Git repo ${GIT_REPO}"

mkdir -p ${SOURCE_CODE_PATH}
git clone ${GIT_REPO} --single-branch ${SOURCE_CODE_PATH}
cd ${SOURCE_CODE_PATH}
git fetch ${GIT_REPO} ${GIT_REF}
git checkout FETCH_HEAD

echo "=== ${sn}: Done"
