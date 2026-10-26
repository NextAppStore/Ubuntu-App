terraform {
  required_version = ">= 1.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.10"
    }
  }
}

provider "openstack" {
  cloud = "openstack"
  # Auth via OS_CLOUD + clouds.yaml (or OS_* env vars)
}

############################
# APP DEFAULTS (set by the app developer)
############################

locals {
  # These values are app-specific and defined by the app developer
  app_name = "ubuntu-user"
  flavor   = "gp1.small"
  key_pair = "" # Empty = password auth only

  metadata = {}
}

############################
# USER MANAGEMENT (CONTRACT)
############################

# Flatten users from teams - EXACTLY as specified by the contract
locals {
  all_users = flatten([
    for team, members in var.users : [
      for member in members : {
        id       = "${team}-${replace(split("@", member.email)[0], ".", "-")}"
        team     = team
        email    = member.email
        username = replace(split("@", member.email)[0], ".", "")
      }
    ]
  ])

  # Extract unique teams
  unique_teams = distinct([for user in local.all_users : user.team])

  # VM count = 1 (one shared VM)
  vm_count = 1

  # List of all usernames and emails
  usernames = [for user in local.all_users : user.username]
  emails    = [for user in local.all_users : user.email]
  user_ids  = [for user in local.all_users : user.id]
}

# Generate a password for each user
resource "random_password" "user_passwords" {
  count            = length(local.all_users)
  length           = 16
  special          = true
  override_special = "!@%^*_-+="
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

# Packer-built image lookup by name (do not hardcode IDs)
data "openstack_images_image_v2" "image" {
  name        = var.image_name
  most_recent = true
}

# External network only needed if floating IP is enabled
data "openstack_networking_network_v2" "external" {
  name = var.floating_ip_pool
}

# -----------------------------------------------------------------------------
# Shared VM
# -----------------------------------------------------------------------------
resource "openstack_compute_instance_v2" "shared_vm" {
  name        = "${local.app_name}-shared"
  image_id    = data.openstack_images_image_v2.image.id
  flavor_name = local.flavor
  key_pair    = local.key_pair != "" ? local.key_pair : null

  security_groups = [var.shared_secgroup_id]

  timeouts {
    create = "15m"
    delete = "15m"
  }

  network {
    uuid = var.network_uuid
  }

  user_data = templatefile("${path.module}/cloud-init-multi-user.yml.tpl", {
    all_users    = local.all_users
    unique_teams = local.unique_teams
    passwords    = [for p in random_password.user_passwords : p.result]
  })

  metadata = merge(local.metadata, {
    teams  = join(",", local.unique_teams)
    users  = join(",", local.usernames)
    emails = join(",", local.emails)
  })
}

# -----------------------------------------------------------------------------
# Optional floating IP (one for the shared VM)
# -----------------------------------------------------------------------------
resource "openstack_networking_floatingip_v2" "fip" {
  count = var.enable_floating_ip ? 1 : 0
  pool  = data.openstack_networking_network_v2.external.name
}

# Wait until the VM has fully booted
resource "time_sleep" "wait_for_vm" {
  count           = var.enable_floating_ip ? 1 : 0
  depends_on      = [openstack_compute_instance_v2.shared_vm]
  create_duration = "60s"
}

# Find the port ID of the VM
data "openstack_networking_port_v2" "vm_port" {
  count     = var.enable_floating_ip ? 1 : 0
  device_id = openstack_compute_instance_v2.shared_vm.id
  depends_on = [
    openstack_compute_instance_v2.shared_vm,
    time_sleep.wait_for_vm
  ]
}

# Floating IP association using the data-source port ID
resource "openstack_networking_floatingip_associate_v2" "fip_assoc" {
  count       = var.enable_floating_ip ? 1 : 0
  floating_ip = openstack_networking_floatingip_v2.fip[0].address
  port_id     = data.openstack_networking_port_v2.vm_port[0].id

  depends_on = [
    data.openstack_networking_port_v2.vm_port,
    time_sleep.wait_for_vm
  ]
}
