################################################################################
# Generate a unique random string for resource name assignment
################################################################################
resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}


################################################################################
# Map default tags with values to be assigned to all tagged resources
################################################################################
locals {
  # Spokes with address_space get a new network; others use an existing subnet_id/resource_group
  new_spokes = { for k, v in var.spokes : k => v if v.address_space != null }

  # Test VMs go into the new spoke workload subnet, or the supplied workload_subnet_id for existing spokes
  test_vm_spokes = {
    for k, v in var.spokes : k => v
    if var.test_vm_enabled && v.test_vm && (v.address_space != null || v.workload_subnet_id != null)
  }

  global_tags = {
    Owner       = var.owner_tag
    ManagedBy   = "terraform"
    Vendor      = "Zscaler"
    Environment = var.environment
  }
}


################################################################################
# 1. Create Private Link Service on the existing Cloud Connector load balancer
################################################################################
module "cc_pls" {
  source                         = "../../modules/terraform-zscc-pls-azure"
  name_prefix                    = var.name_prefix
  resource_tag                   = random_string.suffix.result
  global_tags                    = local.global_tags
  resource_group                 = var.cc_lb_resource_group
  location                       = var.arm_location
  cc_lb_name                     = var.cc_lb_name
  cc_lb_resource_group           = var.cc_lb_resource_group
  cc_lb_frontend_name            = var.cc_lb_frontend_name
  create_nat_subnet              = var.create_nat_subnet
  nat_subnet_cidr                = var.nat_subnet_cidr
  nat_subnet_id                  = var.nat_subnet_id
  nat_ip_count                   = var.nat_ip_count
  visibility_subscription_ids    = var.visibility_subscription_ids
  auto_approval_subscription_ids = var.auto_approval_subscription_ids
  proxy_protocol_enabled         = var.proxy_protocol_enabled
}


################################################################################
# 2. Create spoke networks (RG, VNet, PE subnet, workload subnet)
################################################################################
module "spoke_network" {
  source               = "../../modules/terraform-zscc-spoke-network-azure"
  for_each             = local.new_spokes
  name_prefix          = var.name_prefix
  resource_tag         = random_string.suffix.result
  global_tags          = local.global_tags
  spoke_name           = each.key
  location             = coalesce(each.value.location, var.arm_location)
  address_space        = each.value.address_space
  pe_subnet_cidr       = each.value.pe_subnet_cidr
  workload_subnet_cidr = each.value.workload_subnet_cidr
  bastion_enabled      = coalesce(each.value.bastion, var.bastion_enabled)
  bastion_sku          = coalesce(each.value.bastion_sku, var.bastion_sku)
  bastion_subnet_cidr  = each.value.bastion_subnet_cidr
}


################################################################################
# 3. Create a Private Endpoint and proxy DNS record in each spoke VNet
################################################################################
module "spoke_pe" {
  source                  = "../../modules/terraform-zscc-pe-azure"
  for_each                = var.spokes
  name_prefix             = var.name_prefix
  resource_tag            = random_string.suffix.result
  global_tags             = local.global_tags
  spoke_name              = each.key
  resource_group          = try(module.spoke_network[each.key].resource_group_name, each.value.resource_group)
  location                = coalesce(each.value.location, var.arm_location)
  subnet_id               = try(module.spoke_network[each.key].pe_subnet_id, each.value.subnet_id)
  pls_id                  = module.cc_pls.pls_id
  is_manual_connection    = each.value.is_manual_connection
  static_ip               = each.value.static_ip
  create_dns_zone         = each.value.create_dns_zone
  dns_zone_name           = each.value.dns_zone_name
  dns_zone_resource_group = each.value.dns_zone_resource_group
  dns_record_name         = each.value.dns_record_name
}


################################################################################
# 4. Create a private test VM in each spoke workload subnet
################################################################################
module "spoke_test_vm" {
  source         = "../../modules/terraform-zscc-spoke-vm-azure"
  for_each       = local.test_vm_spokes
  name_prefix    = var.name_prefix
  resource_tag   = random_string.suffix.result
  global_tags    = local.global_tags
  spoke_name     = each.key
  resource_group = try(module.spoke_network[each.key].resource_group_name, each.value.resource_group)
  location       = coalesce(each.value.location, var.arm_location)
  subnet_id      = try(module.spoke_network[each.key].workload_subnet_id, each.value.workload_subnet_id)
  vm_size        = var.test_vm_size
  ssh_public_key = coalesce(var.test_vm_ssh_public_key, tls_private_key.key.public_key_openssh)
  create_ssh_key = false
  proxy_fqdn     = module.spoke_pe[each.key].proxy_fqdn
  proxy_port     = var.proxy_port
}
