#!/usr/bin/env bash

set -euo pipefail

echo "Starting image_modify.sh script..."

# Use environment variables passed from Packer
# OS_AUTH_URL, OS_USERNAME, OS_PASSWORD, OS_PROJECT_NAME, etc. are already set

# Verify required environment variables are set
required_vars=("OS_AUTH_URL" "OS_USERNAME" "OS_PASSWORD" "OS_PROJECT_NAME" "OS_REGION_NAME")
for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
        echo "Error: Required environment variable $var is not set"
        exit 1
    fi
    echo "Verified $var is set"
done

file_name="manifest/${IMAGE_NAME}-manifest.json"
echo "Looking for manifest file: $file_name"

if [ ! -f "$file_name" ]; then
    echo "Error: Manifest file $file_name not found"
    exit 1
fi
echo "Found manifest file"

echo "Reading image ID from manifest..."
for img_id in $(jq '.builds[].artifact_id' "${file_name}" | sed 's/"//g' | tail -1)
do
    echo "Processing New Image ID: ${img_id}"
    
    # Unset signature_verified property
    echo "Attempting to unset signature_verified property..."
    if ! openstack image unset --property signature_verified "${img_id}"; then
        echo "Warning: Failed to unset signature_verified property for image ${img_id}"
    else
        echo "Successfully unset signature_verified property"
    fi
    
    echo "Waiting 5 seconds before proceeding..."
    sleep 5
    
    # Get image name
    echo "Fetching image name for ID ${img_id}..."
    img_name="$(openstack image show "${img_id}" -f value -c name)"
    if [ -z "$img_name" ]; then
        echo "Error: Failed to get name for image ${img_id}"
        continue
    fi
    
    echo "Image Name: $img_name"
    
    # List all public images matching the name
    echo "Searching for old images with name: ${img_name}"
    old_images=$(openstack image list --public -f value | grep "\ ${img_name}\ " | grep -v "${img_id}" || true)
    echo "Found old images:"
    echo "$old_images"
    
    # Rename old images with same name
    for old_img in $(echo "$old_images" | awk '{print $1}')
    do
        echo "Fetching creation date for old image ${old_img}..."
        if old_img_created_at=$(openstack image show "${old_img}" -f value -c created_at) &&
            [[ "${old_img_created_at}" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})T ]]; then
            old_img_date="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
        else
            old_img_date="$(date +%Y%m%d)"
            echo "Warning: Could not get a valid creation date for old image ${old_img}; using current date ${old_img_date}"
        fi

        new_name="${img_name}.${old_img_date}"
        echo "Attempting to rename old image: $old_img to $new_name"
        
        # Get current status of old image
        old_img_status=$(openstack image show "${old_img}" -f value -c status || echo "ERROR_FETCHING_STATUS")
        echo "Old image status: $old_img_status"
        
        if ! openstack image set --name "${new_name}" "${old_img}"; then
            echo "Warning: Failed to rename old image ${old_img} to ${new_name}"
            # Try to get error details
            openstack image show "${old_img}" || echo "Could not fetch image details"
        else
            echo "Successfully renamed old image ${old_img} to ${new_name}"
        fi
    done
    
    echo "Finished processing image ${img_id}"
done

echo "Script completed"
