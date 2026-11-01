output "resource_group_name" {
  description = "Spoke resource group name"
  value       = azurerm_resource_group.spoke_rg.name
}

output "vnet_id" {
  description = "Spoke VNet ID"
  value       = azurerm_virtual_network.spoke_vnet.id
}

output "vnet_name" {
  description = "Spoke VNet name"
  value       = azurerm_virtual_network.spoke_vnet.name
}

output "address_space" {
  description = "Spoke VNet address space"
  value       = var.address_space
}

output "pe_subnet_id" {
  description = "Private Endpoint subnet ID"
  value       = azurerm_subnet.pe_subnet.id
}

output "workload_subnet_id" {
  description = "Workload subnet ID"
  value       = azurerm_subnet.workload_subnet.id
}

output "bastion_name" {
  description = "Spoke Azure Bastion name (null when disabled)"
  value       = try(azurerm_bastion_host.spoke_bastion[0].name, null)
}

output "bastion_sku" {
  description = "Spoke Azure Bastion SKU (null when disabled)"
  value       = var.bastion_enabled ? var.bastion_sku : null
}
