#packer {
#  required_plugins {
#    openstack = {
#      version = ">= 1.1.2"
#      source  = "github.com/hashicorp/openstack"
#    }
#  }
#}

variable "os_access_key" {
  description = "Access key for OpenStack"
}

variable "os_secret_key" {
  description = "Secret key for OpenStack"
}

variable "os_pub_net" {
  description = "Public network ID"
}

variable "os_project" {
  description = "Project in OpenStack"
}

variable "os_flavor" {
  description = "Instance Flavor"
}

variable "os_username" {
  description = "Openstack login Username"
}

variable "os_password" {
  description = "Openstack Password"
}

variable "os_identity_endpoint" {
  description = "Identity endpoint for OpenStack"
}

locals {
  org_img_name_rocky89 = "Rocky-8.9"
  new_img_name_rocky89 = "Rocky-8.9-test"
  ssh_username_rocky89 = "rocky"
}


source "openstack" "rocky-8-9" {
  identity_endpoint               = var.os_identity_endpoint
#  application_credential_id      = var.os_access_key
#  application_credential_secret  = var.os_secret_key
  username                        = var.os_username
  password                        = var.os_password
  tenant_name                     = var.os_project
  domain_name                     = "Default"
  region                          = "europe-nl"
  ssh_username                    = local.ssh_username_rocky89
  image_name                      = local.new_img_name_rocky89
  external_source_image_format    = "qcow2"
  networks                        = [var.os_pub_net]
  image_visibility                = "private"
  image_disk_format               = "qcow2"
  volume_type                     = "unencrypted"
  config_drive                    = true
  use_blockstorage_volume         = true
  volume_size                     = "10"
  ssh_keypair_name                = "shared_leafcloud_key"
  ssh_private_key_file            = "ssh-key/shared_leafcloud_key"
  flavor                          = var.os_flavor

  source_image_filter {
    filters {
      name        = local.org_img_name_rocky89
      visibility  = "public"
      owner       = "55f00f9b08674977a8d66a527030f883"
    }
    most_recent = true
  }
}

# need to be changed, will see how to group all in one build
build {
  sources = [
    "source.openstack.rocky-8-9"
  ]

  provisioner "breakpoint" {
    disable  = true
    note     = "Before Ansible"
  }

#  provisioner "ansible" {
#    playbook_file     = "./playbook.yml"
#    ssh_host_key_file = "/home/ubuntu/packer/ssh-key/shared_leafcloud_key"
#    extra_arguments   = [
#      "-vvvv",
#      "--ssh-extra-args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa -o ConnectTimeout=60",
#      "--extra-vars", "image=${local.new_img_name_rocky89}"
#    ]
#  }

#  provisioner "shell" {
#    inline = [
#      "rm -rf ~/.ansible",
#      "echo > ~/.ssh/authorized_keys"
#    ]
#  }

  provisioner "shell" {
    script = "scripts/yum-update.sh"
    pause_before = "10s"
    expect_disconnect = true
  }

  provisioner "breakpoint" {
    disable  = true
    note     = "Confirm ansible did his job"
  }

  post-processor "manifest" {
    output     = "manifest/${local.new_img_name_rocky89}-manifest.json"
    strip_path = true
  }

  post-processor "shell-local" {
    environment_vars = [
      "OS_USERNAME=${var.os_username}",
      "OS_PASSWORD=${var.os_password}",
      "IMAGE_NAME=${local.new_img_name_rocky89}"
    ]
    scripts = [
      "./scripts/image_modify.sh"
    ]
  }

  provisioner "breakpoint" {
    disable  = true
    note     = "Confirm ansible did his job"
  }
}

