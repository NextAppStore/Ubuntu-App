variable "image_name" {
  type        = string
  description = "Glance-Image-Name — vom Worker zur Build-Zeit gesetzt. @platform:internal"
  default     = "ubuntu-v1"
}

variable "networks" {
  type        = list(string)
  description = "@openstack:network:id:list Build-Netzwerke"
  # DHBWV6 — same default as terraform/variables.tf's
  # network_uuid (see v1.2.0); the previous ID no longer exists in this
  # OpenStack project.
  default = ["9b579624-d844-4df3-b38d-89978b31d37d"]
}

variable "security_groups" {
  type        = list(string)
  description = "@openstack:security_group:id:list Build-Security-Groups"
  # appstore-insides — allows SSH (22) ingress v4+v6; the previous ID
  # does not exist in this OpenStack project and made every Packer
  # build without a wizard override fail with "Unable to find
  # security_group".
  default = ["934851d7-90a2-42ab-927c-fae610697fc7"]
}
