module "az-audio-spoke1-west-europe" {
  source  = "./avx-azure-spoke"
  region                = "xxxx"

  resource_group   = "xxxx"

  account               = "xxxx"
  vnet_cidr             = "10.10.0.0/23"

  gw_name               = "xxxx"
  vnet_name             = "xxxx"


  gw_subnet_cidr           = "10.10.0.0/28"
  gw_subnet_cidr_hagw      = "10.11.0.16/28"

  subnet_vm1          = "10.10.0.32/28"   # here VM lives
  subnet_vm2          = "10.10.0.64/28"   # here VM lives

  transit_gw           = "xxxx"

  security_domain      = "xxxx"
}
