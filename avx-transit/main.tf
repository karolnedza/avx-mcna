### Transit Network "West Europe"

module "xxxx" {
  source  = "./avx-azure-transit-firenet"
  region                 = "xxxx"
  account                = "xxxx"
  cidr                   = "xxxx"
  gw_name                = "xxxx"
  firewall_name          = "xxxx"
  vnet_name               = "xxxx"
  local_as_number          = "xxxx"
  firewall_image         = "xxxx"
  firewall_image_version = "xxxx"
}


module "yyyy" {
  source  = "./avx-azure-transit-firenet"
  region                 = "yyyy"
  account                = "yyyy"
  cidr                   = "yyyy"
  gw_name                = "yyyy"
  firewall_name          = "yyyy"
  vnet_name               = "yyyy"
  local_as_number          = "yyyy"
  firewall_image         = "yyyy"
  firewall_image_version = "yyyy"
}

module "transit-peering-fullmesh" {
  source  = "./avx-transit-peering"

  transit_gateways = [
    module.yyyy.transit_gateway.gw_name,
    module.xxxx.transit_gateway.gw_name

  ]
  # excluded_cidrs = [
  #   0.0.0.0/0,
  # ]
}
