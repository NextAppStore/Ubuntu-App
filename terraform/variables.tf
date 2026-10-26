################################################
# REQUIRED variables
################################################

variable "users" {
  description = "Per-team roster — vom Worker injiziert. @platform:internal"
  type = map(list(object({
    email = string
  })))
  default = {}
}

variable "image_name" {
  description = "Glance-Image-Name — vom Worker zur Apply-Zeit gesetzt. @platform:internal"
  type        = string
}

################################################
# Configurable variables
################################################

variable "network_uuid" {
  description = "Hauptnetzwerk @openstack:network:id"
  type        = string
  # DHBWV6: dual-stack (v4+v6 on the same subnet pair) — every VM
  # automatically gets both fixed IPs from Neutron.
  default = "9b579624-d844-4df3-b38d-89978b31d37d"
}

variable "enable_floating_ip" {
  description = "Floating IP für die VM zuweisen"
  type        = bool
  # DHBWV6 already routes the v6 fixed IP publicly — no floating IP needed.
  # Set to true on a purely private/NAT network without a public route.
  default = false
}

variable "floating_ip_pool" {
  description = "Name des External Networks für Floating IPs @openstack:floating_ip_pool:name"
  type        = string
  default     = "DHBWV6"
}

variable "shared_secgroup_id" {
  description = "ID der gemeinsamen Security Group für alle VMs @openstack:security_group:id"
  type        = string
  default     = "934851d7-90a2-42ab-927c-fae610697fc7"
}