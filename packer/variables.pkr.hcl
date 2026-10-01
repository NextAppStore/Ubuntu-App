variable "image_name" {
  type        = string
  description = "Glance-Image-Name — vom Worker zur Build-Zeit gesetzt. @platform:internal"
  default     = "ubuntu-v1"
}

variable "networks" {
  type        = list(string)
  description = "@openstack:network:id:list Build-Netzwerke"
  # DHBWV6 — dieselbe Default-Wahl wie terraform/variables.tf's
  # network_uuid (siehe v1.2.0); die vorherige ID existiert in diesem
  # OpenStack-Projekt nicht mehr.
  default = ["9b579624-d844-4df3-b38d-89978b31d37d"]
}

variable "security_groups" {
  type        = list(string)
  description = "@openstack:security_group:id:list Build-Security-Groups"
  # appstore-insides — erlaubt SSH (22) Ingress v4+v6; die vorherige ID
  # existiert in diesem OpenStack-Projekt nicht und liess jeden
  # Packer-Build ohne Wizard-Override mit "Unable to find security_group"
  # fehlschlagen.
  default = ["934851d7-90a2-42ab-927c-fae610697fc7"]
}
