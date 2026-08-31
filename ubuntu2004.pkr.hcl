#packer {
#  required_plugins {
#    openstack = {
#      version = ">= 1.1.2"
#      source  = "github.com/hashicorp/openstack"
#    }
#  }
#}

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

variable "os_region" {
  description = "OpenStack region"
}

variable "os_user_domain" {
  description = "OpenStack user domain"
}

variable "os_project_domain" {
  description = "OpenStack project domain"
}

variable "os_identity_version" {
  description = "OpenStack identity API version"
}

variable "os_interface" {
  description = "OpenStack interface"
}

# Need to edit this section #
locals {
  org_img_name_ubuntu2004 = "Ubuntu-20.04"
  # will change it from ubuntu-20.04-test
  new_img_name_ubuntu2004 = "Ubuntu-20.04"
  ssh_username_ubuntu2004 = "ubuntu"
}

source "openstack" "ubuntu-2004" {
  identity_endpoint               = var.os_identity_endpoint
  username                        = var.os_username
  password                        = var.os_password
  tenant_name                     = var.os_project
  domain_name                     = "Default"
  region                          = "europe-nl"
  ssh_username                    = local.ssh_username_ubuntu2004
  image_name                      = local.new_img_name_ubuntu2004
  metadata = {
    hw_machine_type = "q35"
    hw_qemu_guest_agent = "yes"
  }
  external_source_image_format    = "qcow2"
  networks                        = [var.os_pub_net]
  image_visibility                = "public"
  image_disk_format               = "qcow2"
  volume_type                     = "unencrypted"
  config_drive                    = true
  use_blockstorage_volume         = true
  volume_size                     = "10"
  ssh_keypair_name                = "shared_leafcloud_key"
  ssh_private_key_file            = "ssh-key/shared_leafcloud_key"
  flavor                          = var.os_flavor
  ssh_timeout                     = "30m"
  ssh_wait_timeout                = "30m"

  source_image_filter {
    filters {
      name        = local.org_img_name_ubuntu2004
      visibility  = "public"
      owner       = "55f00f9b08674977a8d66a527030f883"
    }
    most_recent = true
  }
}

# need to be changed, will see how to group all in one build
build {
  sources = [
    "source.openstack.ubuntu-2004"
  ]

##  provisioner "ansible" {
##    playbook_file = "./playbook.yml"
##    extra_arguments = [
##      "--extra-vars", "image=${local.new_img_name_ubuntu2004}"
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
    inline = [
      # Install resolvconf
      "sudo DEBIAN_FRONTEND=noninteractive apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y resolvconf",
      # Configure DNS in resolvconf
      "echo 'nameserver 8.8.8.8' | sudo tee /etc/resolvconf/resolv.conf.d/head > /dev/null",
      "echo 'nameserver 8.8.4.4' | sudo tee -a /etc/resolvconf/resolv.conf.d/head > /dev/null",
      "sudo resolvconf -u",
      # Also set in /etc/resolv.conf as backup
      "echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf > /dev/null",
      "echo 'nameserver 8.8.4.4' | sudo tee -a /etc/resolv.conf > /dev/null",
      # Configure hostname
      "echo 'ubuntu-2004' | sudo tee /etc/hostname",
      "echo '127.0.0.1 ubuntu-2004' | sudo tee -a /etc/hosts",
      # Test DNS resolution
      "echo 'Testing DNS resolution...'",
      "ping -c 1 google.com || true"
    ]
  }

  provisioner "shell" {
    script = "scripts/update-ubuntu.sh"
    expect_disconnect = true
    pause_before = "10s"
    max_retries = 3
    timeout = "30m"
  }

  provisioner "shell" {
    inline = [
      "sudo DEBIAN_FRONTEND=noninteractive apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y"
    ]
    expect_disconnect = true
    pause_before = "10s"
    max_retries = 3
    timeout = "30m"
  }

  provisioner "breakpoint" {
    disable  = true
    note     = "Confirm job is done"
  }

  post-processor "manifest" {
    output     = "manifest/${local.new_img_name_ubuntu2004}-manifest.json"
    strip_path = true
  }

  post-processor "shell-local" {
    environment_vars = [
        "IMAGE_NAME=${local.new_img_name_ubuntu2004}",
        "OS_AUTH_URL=${var.os_identity_endpoint}",
        "OS_USERNAME=${var.os_username}",
        "OS_PASSWORD=${var.os_password}",
        "OS_PROJECT_NAME=${var.os_project}",
        "OS_REGION_NAME=${var.os_region}",
        "OS_USER_DOMAIN_NAME=${var.os_user_domain}",
        "OS_PROJECT_DOMAIN_ID=${var.os_project_domain}",
        "OS_IDENTITY_API_VERSION=${var.os_identity_version}",
        "OS_INTERFACE=${var.os_interface}"
    ]
    scripts = [
      "./scripts/image_modify.sh"
    ]
  }
}
