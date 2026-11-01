# Zscaler Cloud Connector / Azure Spoke Private Endpoint Module

Creates a Private Endpoint in an existing spoke subnet that connects to the Cloud Connector Private Link Service. It also
creates a spoke-local private DNS zone (default `zscaler.internal`), links it to the spoke VNet and adds an A record
(default `proxy`) pointing at the PE IP. Each spoke gets its own zone, so the same FQDN resolves to the local PE in
every spoke, even when address spaces overlap.

Set `create_dns_zone = false` with `dns_zone_name`/`dns_zone_resource_group` to add the record to an existing zone, or
`create_dns_zone = false, dns_zone_name = null` to skip DNS.

Set `static_ip` when PAC files or proxy settings reference the PE IP directly.

## Outputs

`pe_id`, `pe_ip`, `proxy_fqdn`

> Note: a private DNS zone name must be unique per resource group. If two spokes share a resource group, give each
> its own `dns_zone_name`, or create one zone and link it to only the VNets that should resolve to that PE.
