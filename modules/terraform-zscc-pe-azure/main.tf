################################################################################
# Create a Private Endpoint in a spoke VNet connected to the Cloud Connector
# Private Link Service, plus a spoke-local private DNS record so workloads can
# use a stable proxy FQDN (e.g. proxy.zscaler.internal) in proxy settings/PAC
################################################################################

locals {
  # /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<subnet>
  spoke_vnet_id  = regex("^(.*)/subnets/[^/]+$", var.subnet_id)[0]
  dns_zone_name  = var.create_dns_zone ? azurerm_private_dns_zone.proxy_zone[0].name : var.dns_zone_name
  dns_zone_rg    = var.create_dns_zone ? var.resource_group : coalesce(var.dns_zone_resource_group, var.resource_group)
  pe_private_ip  = azurerm_private_endpoint.cc_pe.private_service_connection[0].private_ip_address
  resource_label = "${var.name_prefix}-cc-pe-${var.spoke_name}-${var.resource_tag}"
}


################################################################################
# Create Private Endpoint to the Cloud Connector Private Link Service
################################################################################
resource "azurerm_private_endpoint" "cc_pe" {
  name                          = local.resource_label
  location                      = var.location
  resource_group_name           = var.resource_group
  subnet_id                     = var.subnet_id
  custom_network_interface_name = "${local.resource_label}-nic"

  private_service_connection {
    name                           = "${local.resource_label}-psc"
    private_connection_resource_id = var.pls_id
    is_manual_connection           = var.is_manual_connection
    request_message                = var.is_manual_connection ? var.request_message : null
  }

  dynamic "ip_configuration" {
    for_each = var.static_ip == null ? [] : [var.static_ip]
    content {
      name               = "${local.resource_label}-ipconfig"
      private_ip_address = ip_configuration.value
    }
  }

  tags = var.global_tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}


################################################################################
# Create spoke-local private DNS zone and link it to the spoke VNet
# Or reference an existing zone via var.dns_zone_name
################################################################################
resource "azurerm_private_dns_zone" "proxy_zone" {
  count               = var.create_dns_zone ? 1 : 0
  name                = var.dns_zone_name
  resource_group_name = var.resource_group

  tags = var.global_tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "proxy_zone_link" {
  count                 = var.create_dns_zone ? 1 : 0
  name                  = "${local.resource_label}-dns-link"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.proxy_zone[0].name
  virtual_network_id    = local.spoke_vnet_id
  registration_enabled  = false

  tags = var.global_tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}


################################################################################
# Create A record pointing the proxy FQDN at the Private Endpoint IP
################################################################################
resource "azurerm_private_dns_a_record" "proxy_record" {
  count               = var.create_dns_zone || var.dns_zone_name != null ? 1 : 0
  name                = var.dns_record_name
  zone_name           = local.dns_zone_name
  resource_group_name = local.dns_zone_rg
  ttl                 = var.dns_ttl
  records             = [local.pe_private_ip]

  tags = var.global_tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}
