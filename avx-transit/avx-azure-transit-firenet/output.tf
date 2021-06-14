output "vnet" {
  description = "The created VNET with all of it's attributes"
  value       = aviatrix_vpc.default
}

output "transit_gateway" {
  description = "The Aviatrix transit gateway object with all of it's attributes"
  value       = aviatrix_transit_gateway.default
}

output "aviatrix_firenet" {
  description = "The Aviatrix firenet object with all of it's attributes"
  value       = aviatrix_firenet.firenet
}

output "aviatrix_firewall_instance" {
  description = "A list with the created firewall instances and their attributes"
  value       = var.ha_gw ? [aviatrix_firewall_instance.firewall_instance_1[0], aviatrix_firewall_instance.firewall_instance_2[0]] : [aviatrix_firewall_instance.firewall_instance[0]]
}

output "azure_vnet_name" {
  description = "Azure VNET name"
  value       = split(":", aviatrix_vpc.default.vpc_id)[0]
}

output "azure_rg" {
  description = "Azure resource group"
  value       = split(":", aviatrix_vpc.default.vpc_id)[1]
}

output "firewall_instance_nic_names" {
  description = "The names of the NICs of the firewall(s)"
  value       = var.ha_gw ? [join("", regex("([^\\/]+$)", aviatrix_firewall_instance.firewall_instance_1[0].egress_interface)), join("", regex("([^\\/]+$)", aviatrix_firewall_instance.firewall_instance_2[0].egress_interface))] : [join("", regex("([^\\/]+$)", aviatrix_firewall_instance.firewall_instance[0].egress_interface))]
}

output "firewall_name" {
  description = "A list of the firewall names created"
  value       = [for name in aviatrix_firenet.firenet.firewall_instance_association.*.instance_id : join("", regex("^(.*?):", name))]
}
