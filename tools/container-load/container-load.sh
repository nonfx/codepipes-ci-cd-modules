#!/bin/bash
# see README.md for doc
set -e

MANIFEST_FILE=container-manifest.yaml

image_cnt=$(yq '.images|length' < $MANIFEST_FILE)

for ((i=0;i<$image_cnt;i++)); do
    image_name=$(yq ".images.[$i].name" < $MANIFEST_FILE)
    tag_cnt=$(yq ".images.[$i].tags|length" < $MANIFEST_FILE)
    for ((t=0;t<$tag_cnt;t++)); do
        image_tag=$(yq ".images.[$i].tags[$t]" < $MANIFEST_FILE)
        echo "=== Pulling image $image_name:$image_tag"
        docker pull $image_name:$image_tag
    done

    for registry in $(yq -o p '.registries' < $MANIFEST_FILE |cut -d ' ' -f 3) ; do
        echo "=== Tagging and uploading to $registry"
        image_target=$(yq ".images.[$i].target_name" < $MANIFEST_FILE)
        for ((t=0;t<$tag_cnt;t++)); do
            image_tag=$(yq ".images.[$i].tags[$t]" < $MANIFEST_FILE)
            docker tag $image_name:$image_tag "$registry/$image_target:$image_tag"
        done
        docker push "$registry/$image_target" --all-tags
    done
done
