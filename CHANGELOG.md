## 0.1.0 (Unreleased)

FEATURES:
* `terraform-zscc-pls-azure`: Private Link Service on an existing Cloud Connector internal load balancer. Finds the LB VNet from its frontend and creates a /28 NAT subnet there automatically
* `terraform-zscc-spoke-network-azure`: spoke resource group, VNet (overlapping CIDRs allowed), PE subnet and workload subnet
* `terraform-zscc-pe-azure`: spoke Private Endpoint with private DNS zone, VNet link and proxy A record
* `terraform-zscc-spoke-network-azure`: optional Azure Bastion per spoke (Developer, or Basic/Standard/Premium with native client tunneling on Standard+)
* `examples/cc_pls`: per-spoke `location` for multi-region spokes connecting to one PLS, and per-spoke `bastion_sku`
* `terraform-zscc-spoke-vm-azure`: private test VM per spoke (no public IP, NSG denies Internet, run-command access, `proxy-test` script)
* `examples/cc_pls`: one PLS plus, per spoke, a new or existing network and a Private Endpoint via `for_each`
