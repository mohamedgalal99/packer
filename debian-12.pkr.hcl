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

locals {
  org_img_name_debian12 = "Debian-12"
  new_img_name_debian12 = "Debian-12"
  ssh_username_debian12 = "debian"
}

source "openstack" "debian-12" {
  identity_endpoint               = var.os_identity_endpoint
  username                        = var.os_username
  password                        = var.os_password
  tenant_name                     = var.os_project
  domain_name                     = "Default"
  region                          = "europe-nl"
  ssh_username                    = local.ssh_username_debian12
  image_name                      = local.new_img_name_debian12
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
      name        = local.org_img_name_debian12
      visibility  = "public"
      owner       = "55f00f9b08674977a8d66a527030f883"
    }
    most_recent = true
  }
}

# need to be changed, will see how to group all in one build
build {
  sources = [
    "source.openstack.debian-12"
  ]

##  provisioner "ansible" {
##    playbook_file = "./playbook.yml"
##    extra_arguments = [
##      "--extra-vars", "image=${local.new_img_name_debian12}"
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
    # Configure DNS using systemd-resolved (when available)
    "sudo mkdir -p /etc/systemd/resolved.conf.d",
    "echo -e '[Resolve]\\nDNS=8.8.8.8 8.8.4.4\\nFallbackDNS=1.1.1.1' | sudo tee /etc/systemd/resolved.conf.d/dns.conf > /dev/null",
    "sudo systemctl restart systemd-resolved || true",

    # Symlink /etc/resolv.conf if systemd-resolved produced one
    "if [ -f /run/systemd/resolve/resolv.conf ]; then sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf; fi",
    # DNS fallback for images not using systemd-resolved
    "if ! getent hosts deb.debian.org >/dev/null 2>&1; then printf 'nameserver 1.1.1.1\\nnameserver 8.8.8.8\\noptions timeout:2 attempts:5\\n' | sudo tee /etc/resolv.conf > /dev/null; fi",

    # Set hostname
    "echo 'debian-12' | sudo tee /etc/hostname",
    "echo '127.0.0.1 debian-12' | sudo tee -a /etc/hosts",

    # Test DNS resolution
    "echo 'Testing DNS resolution...'",
    "getent hosts deb.debian.org || true",
    "sudo DEBIAN_FRONTEND=noninteractive apt-get update -o Acquire::Retries=5 -o Acquire::http::Timeout=30"
  ]
}


  provisioner "shell" {
    script = "scripts/update-debian.sh"
    expect_disconnect = true
    pause_before = "10s"
    max_retries = 3
    timeout = "30m"
  }

  provisioner "shell" {
    inline = [
      "sudo DEBIAN_FRONTEND=noninteractive apt-get update -o Acquire::Retries=5 -o Acquire::http::Timeout=30",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y -o Acquire::Retries=5 -o Acquire::http::Timeout=30",
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
    output     = "manifest/${local.new_img_name_debian12}-manifest.json"
    strip_path = true
  }

  post-processor "shell-local" {
    environment_vars = [
        "IMAGE_NAME=${local.new_img_name_debian12}",
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
