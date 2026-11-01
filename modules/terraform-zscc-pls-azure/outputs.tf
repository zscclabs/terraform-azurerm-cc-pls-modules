output "pls_id" {
  description = "Private Link Service ID"
  value       = azurerm_private_link_service.cc_pls.id
}

output "pls_alias" {
  description = "Private Link Service alias"
  value       = azurerm_private_link_service.cc_pls.alias
}

output "nat_subnet_id" {
  description = "Subnet ID used for Private Link Service NAT IPs"
  value       = local.nat_subnet_id
}

output "nat_ip_addresses" {
  description = "Static PLS NAT IPs. Dynamically allocated NAT IPs are not returned by the provider; Cloud Connector sees spoke traffic sourced from nat_subnet_cidr"
  value       = compact(azurerm_private_link_service.cc_pls.nat_ip_configuration[*].private_ip_address)
}

output "nat_subnet_cidr" {
  description = "CIDR of the NAT subnet created for the Private Link Service (null when using nat_subnet_id)"
  value       = var.create_nat_subnet ? local.nat_subnet_cidr : null
}
