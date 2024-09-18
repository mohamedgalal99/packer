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
#
#variable "os_project" {
#  description = "Project in OpenStack"
#}
#
#variable "os_flavor" {
#  description = "Instance Flavor"
#}
#
#variable "os_username" {
#  description = "Openstack login Username"
#}
#
#variable "os_password" {
#  description = "Openstack Password"
#}
#
#variable "os_identity_endpoint" {
#  description = "Identity endpoint for OpenStack"
#}

locals {
  org_img_name_almalinux93 = "AlmaLinux-9.3"
  new_img_name_almalinux93 = "AlmaLinux-9.3-test"
  ssh_username_almalinux93 = "almalinux"
}


source "openstack" "almalinux-9-3" {
  identity_endpoint               = var.os_identity_endpoint
  username                        = var.os_username
  password                        = var.os_password
  tenant_name                     = var.os_project
  domain_name                     = "Default"
  region                          = "europe-nl"
  ssh_username                    = local.ssh_username_almalinux93
  image_name                      = local.new_img_name_almalinux93
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
      name        = local.org_img_name_almalinux93
      visibility  = "public"
      owner       = "55f00f9b08674977a8d66a527030f883"
    }
    most_recent = true
  }
}

# need to be changed, will see how to group all in one build
build {
  sources = [
    "source.openstack.almalinux-9-3"
  ]

  provisioner "shell" {
    script = "scripts/dnf-update.sh"
    expect_disconnect = true
  }

  provisioner "breakpoint" {
    disable  = true
    note     = "Confirm job is done"
  }

  post-processor "manifest" {
    output     = "manifest/${local.new_img_name_almalinux93}-manifest.json"
    strip_path = true
  }

  post-processor "shell-local" {
    environment_vars = [
      "OS_USERNAME=${var.os_username}",
      "OS_PASSWORD=${var.os_password}",
      "IMAGE_NAME=${local.new_img_name_almalinux93}"
    ]
    scripts = [
      "./scripts/image_modify.sh"
    ]
  }
}

