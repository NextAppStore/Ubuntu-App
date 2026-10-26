packer {
  required_plugins {
    openstack = {
      source  = "github.com/hashicorp/openstack"
      version = "~> 1"
    }
  }
}

source "openstack" "image" {
  cloud             = "openstack"
  image_name        = var.image_name
  source_image_name = "Ubuntu 24.04"
  flavor            = "gp1.small"
  networks          = var.networks
  security_groups   = var.security_groups
  ssh_username      = "ubuntu"
  # Packer builds run from the worker, which itself sits inside
  # OpenStack (not via the DHBW VPN) - the 10.200.x.x v4 network
  # is directly reachable from there. Force v4 explicitly, because
  # DHBWV6 is dual-stack and Packer might otherwise randomly pick the
  # v6 address.
  ssh_ip_version = "4"
}

build {
  sources = ["source.openstack.image"]

  provisioner "shell" {
    script = "scripts/provision.sh"
  }
}
