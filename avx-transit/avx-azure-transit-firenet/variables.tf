variable "region" {
  description = "The Azure region to deploy this module in"
  type        = string
}

variable "cidr" {
  description = "The CIDR range to be used for the VNET"
  type        = string
}

variable "account" {
  description = "The Azure account name, as known by the Aviatrix controller"
  type        = string
}

variable "gw_name" {
  description = "Aviatrix Transit GW Name"
  default = "az-transit-gw"
}

variable "firewall_name" {
  description = "Firewall Name"
  default = "az-transit-fw"
}


variable "vnet_name" {
  description = "Vnet Name"
  default = "az-transit-vnet"
}


variable "instance_size" {
  description = "Azure Instance size for the Aviatrix gateways"
  type        = string
  default     = "Standard_B2ms" # this is minimum size for Transit Firenet
}

variable "insane_instance_size" {
  description = "Azure Instance size for the Aviatrix gateways"
  type        = string
  default     = "Standard_D3_v2"
}

variable "fw_instance_size" {
  description = "Azure Instance size for the NGFW's"
  type        = string
  default     = "Standard_D3_v2"
}

variable "password" {
  description = "Firewall instance password"
  type        = string
  default     = "@Aviatrix123"
}

variable "attached" {
  description = "Boolean to determine if the spawned firewall instances will be attached on creation"
  type        = bool
  default     = true
}

variable "name" {
  description = "Custom name for VNETs, gateways, and firewalls"
  type        = string
  default     = ""
}

variable "prefix" {
  description = "Boolean to determine if name will be prepended with avx-"
  type        = bool
  default     = true
}

variable "suffix" {
  description = "Boolean to determine if name will be appended with -spoke"
  type        = bool
  default     = true
}

variable "firewall_image" {
  description = "The firewall image to be used to deploy the NGFW's"
  type        = string
}

variable "firewall_image_version" {
  description = "The firewall image version specific to the NGFW vendor image"
  type        = string
}

variable "firewall_username" {
  description = "The username for the administrator account"
  type        = string
  default     = "avxadmin"
}

variable "ha_gw" {
  description = "Set to false to deploy single Aviatrix gateway. When set to false, fw_amount is ignored and only a single NGFW instance is deployed."
  type        = bool
  default     = true
}

variable "egress_enabled" {
  description = "Set to true to enable egress inspection on the firewall instances"
  type        = bool
  default     = false
}

variable "inspection_enabled" {
  description = "Set to false to disable inspection on the firewall instances"
  type        = bool
  default     = true
}

variable "insane_mode" {
  description = "Set to true to enable Aviatrix high performance encryption."
  type        = bool
  default     = false
}

variable "connected_transit" {
  description = "Set to false to disable connected transit."
  type        = bool
  default     = true
}

variable "bgp_manual_spoke_advertise_cidrs" {
  description = "Define a list of CIDRs that should be advertised via BGP."
  type        = string
  default     = ""
}

variable "learned_cidr_approval" {
  description = "Set to true to enable learned CIDR approval."
  type        = string
  default     = "false"
}

variable "active_mesh" {
  description = "Set to false to disable active mesh."
  type        = bool
  default     = true
}

variable "enable_segmentation" {
  description = "Switch to true to enable transit segmentation"
  type        = bool
  default     = true
}

variable "single_az_ha" {
  description = "Set to true if Controller managed Gateway HA is desired"
  type        = bool
  default     = true
}

variable "single_ip_snat" {
  description = "Enable single_ip mode Source NAT for this container"
  type        = bool
  default     = false
}

variable "enable_advertise_transit_cidr" {
  description = "Switch to enable/disable advertise transit VPC network CIDR for a VGW connection"
  type        = bool
  default     = false
}

variable "bgp_polling_time" {
  description = "BGP route polling time. Unit is in seconds"
  type        = string
  default     = "50"
}

variable "bgp_ecmp" {
  description = "Enable Equal Cost Multi Path (ECMP) routing for the next hop"
  type        = bool
  default     = false
}

variable "bootstrap_storage_name" {
  description = "The firewall bootstrap_storage_name"
  type        = string
  default     = null
}

variable "storage_access_key" {
  description = "The storage_access_key to access the storage account"
  type        = string
  default     = null
}

variable "file_share_folder" {
  description = "The file_share_folder containing the bootstrap files"
  type        = string
  default     = null
}

variable "local_as_number" {
  description = "The gateways local AS number"
  type        = number
  default     = null
}

variable "enable_bgp_over_lan" {
  description = "Enable BGP over LAN. Creates eth4 for integration with SDWAN for example"
  type        = bool
  default     = false
}

variable "enable_egress_transit_firenet" {
  description = "Set to true to enable egress on transit gw"
  type        = bool
  default     = false
}

variable "az1" {
  description = "AZ Zone to be used for GW deployment."
  type        = string
  default     = "az-1"
}

variable "az2" {
  description = "AZ Zone to be used for HAGW deployment."
  type        = string
  default     = "az-2"
}

variable "az_support" {
  description = "Set to true if the Azure region supports AZ's"
  type        = bool
  default     = true
}


locals {
  is_checkpoint = length(regexall("check", lower(var.firewall_image))) > 0 #Check if fw image contains checkpoint. Needs special handling for the username/password
  is_palo       = length(regexall("palo", lower(var.firewall_image))) > 0  #Check if fw image contains palo. Needs special handling for management_subnet (CP & Fortigate null)
  lower_name    = length(var.name) > 0 ? replace(lower(var.name), " ", "-") : replace(lower(var.region), " ", "-")
  prefix        = var.prefix ? "avx-" : ""
  suffix        = var.suffix ? "-firenet" : ""
  name          = "${local.prefix}${local.lower_name}${local.suffix}"
  cidrbits      = tonumber(split("/", var.cidr)[1])
  newbits       = 26 - local.cidrbits
  netnum        = pow(2, local.newbits)
  subnet        = var.insane_mode ? cidrsubnet(var.cidr, local.newbits, local.netnum - 2) : aviatrix_vpc.default.public_subnets[2].cidr
  ha_subnet     = var.insane_mode ? cidrsubnet(var.cidr, local.newbits, local.netnum - 1) : aviatrix_vpc.default.public_subnets[3].cidr
}
