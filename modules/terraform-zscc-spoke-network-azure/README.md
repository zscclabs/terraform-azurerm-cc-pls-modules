# Zscaler Cloud Connector / Azure Spoke Network Module

Creates a spoke network that reaches Cloud Connector through Private Link:

- Resource group `<prefix>-rg-<spoke>-<tag>`
- VNet with `address_space`. It **may overlap** with the hub and other spokes, since there is no peering.
- PE subnet (default `cidrsubnet(address_space, 8, 0)`, `private_endpoint_network_policies = "Disabled"`)
- Workload subnet (default `cidrsubnet(address_space, 8, 1)`). It has no route table or NAT gateway; workloads reach
  the internet through the explicit proxy at the Private Endpoint.

- Optional **Azure Bastion** (`bastion_enabled`, default Standard SKU) with an `AzureBastionSubnet` /26 (default
  `10.0.2.0/26` for `10.0.0.0/16`) and a public IP **on Bastion only**. Standard turns on native client tunneling:
  `az network bastion ssh`. Each spoke needs its own Bastion, because the spokes aren't peered (their address spaces overlap).
  `bastion_sku = "Developer"` gives the free shared Bastion. It needs no subnet or public IP, but it's portal-only,
  allows one session at a time and is available only in some regions (e.g. East US 2, but **not** East US).

Pass `pe_subnet_id` and `resource_group_name` to [`terraform-zscc-pe-azure`](../terraform-zscc-pe-azure).

## Outputs

`resource_group_name`, `vnet_id`, `vnet_name`, `address_space`, `pe_subnet_id`, `workload_subnet_id`, `bastion_name`
