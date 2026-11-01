################################################################################
# Create a Private Link Service on the frontend of an existing Cloud Connector
# internal Standard Load Balancer so that spoke VNets (including those with
# overlapping address space) can reach Cloud Connector via Private Endpoints
################################################################################

data "azurerm_client_config" "current" {}


################################################################################
# Look up the existing Cloud Connector load balancer and its frontend
################################################################################
data "azurerm_lb" "cc_lb" {
  name                = var.cc_lb_name
  resource_group_name = var.cc_lb_resource_group

  lifecycle {
    postcondition {
      condition     = var.cc_lb_frontend_name == null || contains(self.frontend_ip_configuration[*].name, coalesce(var.cc_lb_frontend_name, "-"))
      error_message = "Frontend IP configuration ${coalesce(var.cc_lb_frontend_name, "-")} not found on load balancer ${var.cc_lb_name}."
    }
    postcondition {
      condition = alltrue([
        for fe in self.frontend_ip_configuration : fe.subnet_id != ""
        if var.cc_lb_frontend_name == null ? fe.name == self.frontend_ip_configuration[0].name : fe.name == var.cc_lb_frontend_name
      ])
      error_message = "The selected frontend on load balancer ${var.cc_lb_name} must be an internal (subnet-based) frontend."
    }
  }
}

locals {
  frontend = (
    var.cc_lb_frontend_name == null
    ? data.azurerm_lb.cc_lb.frontend_ip_configuration[0]
    : one([for fe in data.azurerm_lb.cc_lb.frontend_ip_configuration : fe if fe.name == var.cc_lb_frontend_name])
  )
  frontend_ip_configuration_id = local.frontend.id

  # /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<subnet>
  lb_vnet_parts = regex("(?i)^/subscriptions/[^/]+/resourceGroups/([^/]+)/providers/Microsoft.Network/virtualNetworks/([^/]+)/subnets/", local.frontend.subnet_id)

  visibility_subscription_ids    = coalescelist(var.visibility_subscription_ids, [data.azurerm_client_config.current.subscription_id])
  auto_approval_subscription_ids = coalescelist(var.auto_approval_subscription_ids, [data.azurerm_client_config.current.subscription_id])

  # Default NAT subnet: last /28 of the LB VNet's first address space (e.g. 10.1.0.0/16 -> 10.1.255.240/28),
  # a range the Cloud Connector network module never allocates
  lb_vnet_space   = data.azurerm_virtual_network.lb_vnet.address_space[0]
  nat_newbits     = 28 - tonumber(split("/", local.lb_vnet_space)[1])
  nat_subnet_cidr = var.nat_subnet_cidr != null ? var.nat_subnet_cidr : (local.nat_newbits > 0 ? cidrsubnet(local.lb_vnet_space, local.nat_newbits, pow(2, local.nat_newbits) - 1) : null)

  nat_subnet_id = var.create_nat_subnet ? azurerm_subnet.pls_nat_subnet[0].id : var.nat_subnet_id
}


################################################################################
# Look up the VNet hosting the load balancer frontend
################################################################################
data "azurerm_virtual_network" "lb_vnet" {
  name                = local.lb_vnet_parts[1]
  resource_group_name = local.lb_vnet_parts[0]
}


################################################################################
# Create dedicated /28 NAT subnet for the Private Link Service in the LB VNet
# Or reference an existing subnet via var.nat_subnet_id
################################################################################
resource "azurerm_subnet" "pls_nat_subnet" {
  count                                         = var.create_nat_subnet ? 1 : 0
  name                                          = "${var.name_prefix}-cc-pls-nat-subnet-${var.resource_tag}"
  resource_group_name                           = data.azurerm_virtual_network.lb_vnet.resource_group_name
  virtual_network_name                          = data.azurerm_virtual_network.lb_vnet.name
  address_prefixes                              = [local.nat_subnet_cidr]
  private_link_service_network_policies_enabled = false

  lifecycle {
    precondition {
      condition     = local.nat_subnet_cidr != null
      error_message = "Load balancer VNet address space ${local.lb_vnet_space} is too small to carve a /28. Set nat_subnet_cidr or nat_subnet_id."
    }
  }
}


################################################################################
# Create Private Link Service
################################################################################
resource "azurerm_private_link_service" "cc_pls" {
  name                = "${var.name_prefix}-cc-pls-${var.resource_tag}"
  location            = var.location
  resource_group_name = var.resource_group

  load_balancer_frontend_ip_configuration_ids = [local.frontend_ip_configuration_id]
  visibility_subscription_ids                 = local.visibility_subscription_ids
  auto_approval_subscription_ids              = local.auto_approval_subscription_ids
  proxy_protocol_enabled                      = var.proxy_protocol_enabled

  dynamic "nat_ip_configuration" {
    for_each = range(var.nat_ip_count)
    content {
      name                       = "${var.name_prefix}-cc-pls-nat-ip-${nat_ip_configuration.value + 1}-${var.resource_tag}"
      subnet_id                  = local.nat_subnet_id
      primary                    = nat_ip_configuration.value == 0
      private_ip_address         = try(var.nat_static_ips[nat_ip_configuration.value], null)
      private_ip_address_version = "IPv4"
    }
  }

  tags = var.global_tags

  lifecycle {
    ignore_changes = [
      tags,
    ]

    precondition {
      condition     = local.nat_subnet_id != null
      error_message = "Set nat_subnet_id when create_nat_subnet is false."
    }
  }
}
