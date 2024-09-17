packer {
  required_plugins {
    openstack = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/openstack"
    }
  }
}

variable "image_name" {
  type    = string
  default = "eth-miner-base"
}

source "openstack" "ubuntu-base" {
  image_name        = "${var.image_name}"
  source_image_name = "Ubuntu-20.04"
  flavor            = "ec1.medium"
  ssh_username      = "ubuntu"
  image_tags        = ["ubuntu", "miner"]
  networks          = ["ee54f79e-d33a-4866-8df0-4a4576d70243"]
}

source "openstack" "a30-ubuntu-base" {
  image_name              = "${var.image_name}"
  source_image_name       = "Ubuntu-20.04"
  flavor                  = "eg1.a30x1.V8-32"
  ssh_username            = "ubuntu"
  image_tags              = ["ubuntu", "miner"]
  networks                = ["ee54f79e-d33a-4866-8df0-4a4576d70243"]
  image_disk_format       = "qcow2"
  image_visibility        = "private"
  use_blockstorage_volume = true
  volume_size             = 10
  volume_type             = "unencrypted"
  image_min_disk          = 10
  cloud                   = leafcloud-vast
}

build {
  name = "eth-miner"
  sources = [
    "source.openstack.a30-ubuntu-base"
  ]

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
    ]
    script = "apt_install.sh"
  }

  // Set of base configuration files
  provisioner "file" {
    sources     = ["./t-rex-miner.service", "./start-mining.sh"]
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/start-mining.sh /opt/start-mining.sh",
      "sudo chmod +x /opt/start-mining.sh",
      "sudo mv /tmp/t-rex-miner.service /etc/systemd/system/",
      "sudo chmod u+x /etc/systemd/system/t-rex-miner.service",
      "sudo systemctl enable t-rex-miner",
    ]
  }

  provisioner "shell" {
    inline = [
      "echo all done!"
    ]
  }

}
