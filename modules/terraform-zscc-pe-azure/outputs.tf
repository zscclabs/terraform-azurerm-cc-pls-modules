output "pe_id" {
  description = "Private Endpoint ID"
  value       = azurerm_private_endpoint.cc_pe.id
}

output "pe_ip" {
  description = "Private Endpoint IP that spoke workloads use as their proxy"
  value       = local.pe_private_ip
}

output "proxy_fqdn" {
  description = "Proxy FQDN resolving to the Private Endpoint IP within the spoke"
  value       = local.dns_zone_name == null ? null : "${var.dns_record_name}.${local.dns_zone_name}"
}
