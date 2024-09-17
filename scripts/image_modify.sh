#!/usr/bin/env bash

set -x

export OS_AUTH_URL=https://create.leaf.cloud:5000
export OS_PROJECT_ID=17e5a06a7ce34fb689b6e0ee062f663c
export OS_PROJECT_NAME="leaf-test"
export OS_USER_DOMAIN_NAME="Default"
export OS_PROJECT_DOMAIN_ID="default"
export OS_REGION_NAME="europe-nl"
export OS_INTERFACE=public
export OS_IDENTITY_API_VERSION=3

file_name="manifest/${IMAGE_NAME}-manifest.json"

for img_id in $(jq '.builds[].artifact_id' ${file_name} | sed 's/"//g')
do
    echo "${img_id}"
    openstack image unset --property signature_verified "${img_id}"
    sleep 5
    img_name="$(openstack image show ${img_id} -f value -c name)"

    echo "$img_name"
    for old_img in $(openstack image list --private -f value | grep "\ ${img_name}\ " | grep -v "${img_id}" | awk '{print $1}')
    do
      echo "$old_img"
      openstack image set --name "${img_name}.$(date +%Y%m%d)" "${old_img}"
    done
done
