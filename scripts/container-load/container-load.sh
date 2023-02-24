#!/bin/bash
# see README.md for doc
set -e

MANIFEST_FILE=container-manifest.yaml

image_cnt=$(yq '.images|length' < $MANIFEST_FILE)

for ((i=0;i<$image_cnt;i++)); do
    image_name=$(yq ".images.[$i].name" < $MANIFEST_FILE)
    image_tag=$(yq ".images.[$i].tag" < $MANIFEST_FILE)
    echo "=== Pulling image $image_name:$image_tag"
    docker pull $image_name:$image_tag
    
    for registry in $(yq -o p '.registries' < container-manifest.yaml |cut -d ' ' -f 3) ; do
        echo "=== Tagging and uploading to $registry"
        image_target=$(yq ".images.[$i].target_name" < $MANIFEST_FILE)
        docker tag $image_name:$image_tag "$registry/$image_target:$image_tag"
        docker push "$registry/$image_target:$image_tag"
    done
done
