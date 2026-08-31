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
  org_img_name_ubuntu2204 = "Ubuntu-22.04"
  new_img_name_ubuntu2204 = "Ubuntu-22.04"
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
  volume_size                     = "20"
  ssh_keypair_name                = "shared_leafcloud_key"
  ssh_private_key_file            = "ssh-key/shared_leafcloud_key"
  flavor                          = var.os_flavor
  ssh_timeout                     = "30m"
  ssh_wait_timeout                = "30m"

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
  inline = [
    # Ensure the ephemeral cloud hostname resolves before further sudo commands
    "CURRENT_HOSTNAME=$(hostname); grep -q \" $CURRENT_HOSTNAME\" /etc/hosts || echo \"127.0.1.1 $CURRENT_HOSTNAME\" | sudo tee -a /etc/hosts",

    # Configure DNS using systemd-resolved
    "sudo mkdir -p /etc/systemd/resolved.conf.d",
    "echo -e '[Resolve]\\nDNS=8.8.8.8 8.8.4.4\\nFallbackDNS=1.1.1.1' | sudo tee /etc/systemd/resolved.conf.d/dns.conf > /dev/null",
    "sudo systemctl restart systemd-resolved",

    # Symlink /etc/resolv.conf to systemd's generated file
    "sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf",

    # Disable command-not-found metadata updates during image builds
    "printf 'Acquire::IndexTargets::deb::CNF::DefaultEnabled \"false\";\\nAPT::Update::Post-Invoke-Success {};\\n' | sudo tee /etc/apt/apt.conf.d/99packer-no-cnf > /dev/null",

    # Set hostname and keep the transient cloud hostname resolvable for sudo
    "echo 'ubuntu-2204' | sudo tee /etc/hostname",
    "CURRENT_HOSTNAME=$(hostname); grep -q \"127.0.1.1 ubuntu-2204\" /etc/hosts || echo '127.0.1.1 ubuntu-2204' | sudo tee -a /etc/hosts",

    # Test DNS resolution
    "echo 'Testing DNS resolution...'",
    "ping -c 1 google.com || true",

    # Refresh apt metadata only after DNS is configured, with retries
    "if command -v cloud-init >/dev/null 2>&1; then sudo cloud-init status --wait || true; fi",
    "while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do echo 'Waiting for apt/dpkg locks to be released...'; sleep 3; done",
    "sudo mkdir -p /var/lib/apt/lists/partial",
    "sudo apt-get clean",
    "sudo DEBIAN_FRONTEND=noninteractive apt-get update -o Acquire::Retries=5"
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
      "if command -v cloud-init >/dev/null 2>&1; then sudo cloud-init status --wait || true; fi",
      "while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do echo 'Waiting for apt/dpkg locks to be released...'; sleep 3; done",
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
    output     = "manifest/${local.new_img_name_ubuntu2204}-manifest.json"
    strip_path = true
  }

  post-processor "shell-local" {
    environment_vars = [
        "IMAGE_NAME=${local.new_img_name_ubuntu2204}",
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
