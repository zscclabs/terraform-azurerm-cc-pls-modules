################################################################################
# Create a spoke network that consumes Cloud Connector through Private Link.
# The address space may overlap with the hub and with other spokes since there
# is no peering - traffic reaches Cloud Connector only via the Private Endpoint
################################################################################

locals {
  pe_subnet_cidr       = coalesce(var.pe_subnet_cidr, cidrsubnet(var.address_space, 8, 0))
  workload_subnet_cidr = coalesce(var.workload_subnet_cidr, cidrsubnet(var.address_space, 8, 1))
  # First /26 of the third /24-equivalent block, e.g. 10.0.2.0/26 for 10.0.0.0/16
  bastion_subnet_cidr = coalesce(var.bastion_subnet_cidr, cidrsubnet(cidrsubnet(var.address_space, 8, 2), 2, 0))
  # Developer SKU is a shared, VNet-attached Bastion: no AzureBastionSubnet or public IP
  bastion_dedicated = var.bastion_enabled && var.bastion_sku != "Developer"
}


################################################################################
# Resource Group
################################################################################
resource "azurerm_resource_group" "spoke_rg" {
  name     = "${var.name_prefix}-rg-${var.spoke_name}-${var.resource_tag}"
  location = var.location

  tags = var.global_tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}


################################################################################
# Virtual Network
################################################################################
resource "azurerm_virtual_network" "spoke_vnet" {
  name                = "${var.name_prefix}-vnet-${var.spoke_name}-${var.resource_tag}"
  address_space       = [var.address_space]
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_rg.name

  tags = var.global_tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}


################################################################################
# Create Private Endpoint subnet
################################################################################
resource "azurerm_subnet" "pe_subnet" {
  name                              = "${var.name_prefix}-pe-subnet-${var.spoke_name}-${var.resource_tag}"
  resource_group_name               = azurerm_resource_group.spoke_rg.name
  virtual_network_name              = azurerm_virtual_network.spoke_vnet.name
  address_prefixes                  = [local.pe_subnet_cidr]
  private_endpoint_network_policies = "Disabled"
  default_outbound_access_enabled   = false
}


################################################################################
# Create private workload subnet. No route table / NAT gateway and Azure
# default outbound access disabled: workloads reach the internet only through
# the explicit proxy at the Private Endpoint
################################################################################
resource "azurerm_subnet" "workload_subnet" {
  name                            = "${var.name_prefix}-workload-subnet-${var.spoke_name}-${var.resource_tag}"
  resource_group_name             = azurerm_resource_group.spoke_rg.name
  virtual_network_name            = azurerm_virtual_network.spoke_vnet.name
  address_prefixes                = [local.workload_subnet_cidr]
  default_outbound_access_enabled = false
}


################################################################################
# Optional Azure Bastion for SSH to private spoke VMs.
# Basic/Standard/Premium: dedicated host in AzureBastionSubnet with its own
# public IP (VMs stay private). Standard/Premium enable native client access via
# `az network bastion ssh`.
# Developer: free shared Bastion attached to the VNet, portal-only, limited regions
################################################################################
resource "azurerm_subnet" "bastion_subnet" {
  count                = local.bastion_dedicated ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.spoke_rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = [local.bastion_subnet_cidr]
}

resource "azurerm_public_ip" "bastion_pip" {
  count               = local.bastion_dedicated ? 1 : 0
  name                = "${var.name_prefix}-bastion-pip-${var.spoke_name}-${var.resource_tag}"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.global_tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_bastion_host" "spoke_bastion" {
  count               = var.bastion_enabled ? 1 : 0
  name                = "${var.name_prefix}-bastion-${var.spoke_name}-${var.resource_tag}"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
  sku                 = var.bastion_sku
  tunneling_enabled   = var.bastion_sku == "Standard" || var.bastion_sku == "Premium"
  virtual_network_id  = var.bastion_sku == "Developer" ? azurerm_virtual_network.spoke_vnet.id : null

  dynamic "ip_configuration" {
    for_each = local.bastion_dedicated ? [1] : []
    content {
      name                 = "${var.name_prefix}-bastion-ipconf-${var.spoke_name}-${var.resource_tag}"
      subnet_id            = azurerm_subnet.bastion_subnet[0].id
      public_ip_address_id = azurerm_public_ip.bastion_pip[0].id
    }
  }

  tags = var.global_tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}
