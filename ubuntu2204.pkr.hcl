#packer {
#  required_plugins {
#    openstack = {
#      version = ">= 1.1.2"
#      source  = "github.com/hashicorp/openstack"
#    }
#  }
#}

#variable "os_pub_net" {
#  description = "Public network ID"
#}

#variable "os_project" {
#  description = "Project in OpenStack"
#}

#variable "os_flavor" {
#  description = "Instance Flavor"
#}

#variable "os_username" {
#  description = "Openstack login Username"
#}

#variable "os_password" {
#  description = "Openstack Password"
#}

#variable "os_identity_endpoint" {
#  description = "Identity endpoint for OpenStack"
#}

locals {
  org_img_name_ubuntu2204 = "Ubuntu-22.04"
  new_img_name_ubuntu2204 = "Ubuntu-22.04-test"
  ssh_username_ubuntu2204 = "ubuntu"
}

source "openstack" "ubuntu-2204" {
  identity_endpoint               = var.os_identity_endpoint
  username                        = var.os_username
  password                        = var.os_password
  tenant_name                     = var.os_project
  domain_name                     = "Default"
  region                          = "europe-nl"
  ssh_username                    = local.ssh_username_ubuntu2204
  image_name                      = local.new_img_name_ubuntu2204
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
      name        = local.org_img_name_ubuntu2204
      visibility  = "public"
      owner       = "55f00f9b08674977a8d66a527030f883"
    }
    most_recent = true
  }
}

# need to be changed, will see how to group all in one build
build {
  sources = [
    "source.openstack.ubuntu-2204"
  ]

##  provisioner "ansible" {
##    playbook_file = "./playbook.yml"
##    extra_arguments = [
##      "--extra-vars", "image=${local.new_img_name_ubuntu2204}"
##    ]
##  }
##
##  provisioner "shell" {
##    inline = [
##      "rm -rf ~/.ansible",
##      "echo > ~/.ssh/authorized_keys"
##    ]
##  }

  provisioner "shell" {
    script = "scripts/update-ubuntu.sh"
    expect_disconnect = true
  }

  provisioner "breakpoint" {
    disable  = true
    note     = "Confirm job is done"
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get upgrade -y",
      "sudo apt-get autoremove -y"
    ]
  }

  post-processor "manifest" {
    output     = "manifest/${local.new_img_name_ubuntu2204}-manifest.json"
    strip_path = true
  }

  post-processor "shell-local" {
    environment_vars = [
      "OS_USERNAME=${var.os_username}",
      "OS_PASSWORD=${var.os_password}",
      "IMAGE_NAME=${local.new_img_name_ubuntu2204}"
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

