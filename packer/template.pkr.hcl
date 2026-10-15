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
  # Packer-Builds laufen vom Worker aus, der selbst innerhalb von
  # OpenStack sitzt (nicht ueber das DHBW-VPN) - das 10.200.x.x-v4-Netz
  # ist von dort aus direkt erreichbar. Explizit v4 erzwingen, weil
  # DHBWV6 dual-stack ist und Packer sonst zufaellig die v6-Adresse
  # waehlen koennte.
  ssh_ip_version = "4"
}

build {
  sources = ["source.openstack.image"]

  provisioner "shell" {
    script = "scripts/provision.sh"
  }
}
