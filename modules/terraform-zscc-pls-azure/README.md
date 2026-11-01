# Zscaler Cloud Connector / Azure Private Link Service Module

Creates an Azure Private Link Service on the frontend of an **existing** Cloud Connector internal Standard Load
Balancer. The load balancer is looked up by name with `data "azurerm_lb"`, and its VNet is found from the selected
frontend's subnet. A dedicated **/28 NAT subnet** is created in that VNet with
`private_link_service_network_policies_enabled = false`. It defaults to the last /28 of the VNet's first address space
(`10.1.0.0/16` → `10.1.255.240/28`), and `nat_subnet_cidr` overrides that.

Visibility and auto-approval default to the current subscription. Spokes in that subscription connect without manual approval.

## Inputs (key)

| Name | Description | Default |
| --- | --- | --- |
| `cc_lb_name` / `cc_lb_resource_group` | Existing CC load balancer | n/a |
| `cc_lb_frontend_name` | Frontend to attach to | first frontend |
| `create_nat_subnet` | Create a /28 NAT subnet in the LB VNet, or use `nat_subnet_id` | `true` |
| `nat_subnet_cidr` | Override for the NAT /28 | last /28 of LB VNet |
| `nat_ip_count` | NAT IPs (1-8) | `1` |
| `visibility_subscription_ids` / `auto_approval_subscription_ids` | Who can connect / is auto-approved | current subscription |
| `proxy_protocol_enabled` | TCP Proxy Protocol v2 | `false` |

## Outputs

`pls_id`, `pls_alias`, `nat_subnet_id`, `nat_subnet_cidr`, `nat_ip_addresses`
