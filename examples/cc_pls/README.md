# Example: Private Link Service + spoke Private Endpoints

Adds a Private Link Service to an existing Cloud Connector load balancer, plus a Private Endpoint with a
`proxy.zscaler.internal` DNS record in every spoke listed in `var.spokes`.

1. Put environment-specific values (`env_subscription_id`, `name_prefix`, `cc_lb_name`, `cc_lb_resource_group`)
   in `private.auto.tfvars`, which is git-ignored and overrides `terraform.tfvars`. Fill in the rest of `terraform.tfvars`: the CC LB name/RG (see the CC repo's `terraform output` / Azure portal), and
   one entry per spoke: `address_space` for a new spoke network, or `subnet_id` + `resource_group` for an existing one.
   The LB VNet and the /28 NAT subnet are derived automatically (override with `nat_subnet_cidr`).
2. `terraform init && terraform plan`. Check that only additions are planned.
3. `terraform apply`. Then point spoke workloads at `proxy.zscaler.internal:<proxy_port>`.

Adding a spoke later is just a new map entry. Spokes can be added and removed independently.
