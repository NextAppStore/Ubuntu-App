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
  # DHBWV6 ist dual-stack; ohne explizite Version waehlt Packer
  # bevorzugt die IPv4-Adresse. Das VPN der DHBW routet aber nur
  # IPv6 (2001:7c0:1b20::/48) zum Build-Host, keine Route ins
  # 10.200.x.x-Netz - daher IPv6 erzwingen, damit lokale Builds
  # ueber VPN ueberhaupt eine SSH-Verbindung aufbauen koennen.
  ssh_ip_version    = "6"
}

build {
  sources = ["source.openstack.image"]

  provisioner "shell" {
    script = "scripts/provision.sh"
  }
}
