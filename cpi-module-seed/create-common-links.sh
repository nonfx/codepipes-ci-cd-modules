#!/bin/bash
#
# This script creates symlinks in the pipeline-modules service directories so that
# the cpi-module-seed script will load the common modules properly. The names of the
# symlinks are prepended with "cmn-" so that the symlinked files can be more easily
# identified in a dir list (or VS code). This also allows us to setup a .gitignore
# entry so the symlinks don't accidentally get committed.
# NOTE: the module file name at load time is not used as the "official" module name
# as that is taken from the module metadata in the yaml file.

set -e
# set -x

clouds="aws azure gcp"
services="app-service deployment-service"
pipeline_module_dir="pipeline-modules"
common_dir="../../common"

for cloud in $clouds; do
    [ -e "$pipeline_module_dir/common/$cloud" ] || continue
    for module in $(find $pipeline_module_dir/common/$cloud -type f -name "*.yaml"); do
        echo "Processing $module"
        for service in $services; do
            module_name=$(basename $module)
            if [ -f $pipeline_module_dir/$service/$cloud/$module_name ]; then
                echo "WARNING: File already exists for $pipeline_module_dir/$service/$cloud/$module_name - Skipping symlink for common module with same name"
            else
                ln -sf $common_dir/$cloud/$module_name $pipeline_module_dir/$service/$cloud/cmn-$module_name
            fi
        done
    done
done
