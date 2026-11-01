## Environment-specific values. Put real values in private.auto.tfvars (git-ignored),
## which Terraform loads automatically and which overrides the placeholders below.

## Azure subscription containing the Cloud Connector hub and spokes
env_subscription_id = "00000000-0000-0000-0000-000000000000"
arm_location        = "eastus"
name_prefix         = "zscc"

## Existing Cloud Connector internal load balancer (from terraform-azurerm-cloud-connector-modules)
## The LB VNet is discovered from the LB frontend subnet
cc_lb_name           = "zscc-cc-lb-xxxxxxxx"
cc_lb_resource_group = "zscc-rg-xxxxxxxx"

## PLS NAT subnet - a /28 is created in the LB VNet. Defaults to the last /28 of the VNet
## address space (e.g. 10.1.255.240/28 for 10.1.0.0/16). Uncomment to override.
create_nat_subnet = true
# nat_subnet_cidr = "10.1.250.0/28"
nat_ip_count = 2

## Private test VMs in each spoke workload subnet (no public IP, Internet blocked by NSG)
test_vm_enabled = true
## Azure Bastion (Standard) per spoke for SSH to the private test VMs (~10 min to deploy, billed hourly)
bastion_enabled = true
bastion_sku     = "Standard"
## Set to the Cloud Connector explicit proxy port to configure system/apt proxy on the test VMs
# proxy_port = 8080

## Spoke VNets - address space may overlap with the hub and each other
spokes = {
  # New spoke network: RG + VNet + PE subnet (10.0.0.0/24) + workload subnet (10.0.1.0/24)
  spoke1 = {
    address_space = "10.0.0.0/16"
    static_ip     = "10.0.0.10"
  }
  # Same address space as spoke1 - fine, there is no peering
  spoke2 = {
    address_space = "10.0.0.0/16"
  }
  # East US 2 spokes - Private Endpoints connect cross-region to the eastus PLS.
  # Bastion uses the default Standard SKU. bastion_sku = "Developer" (free, portal-only) is also available in eastus2
  spoke3 = {
    location      = "eastus2"
    address_space = "10.0.0.0/16"
  }
  spoke4 = {
    location      = "eastus2"
    address_space = "10.0.0.0/16"
  }
  # Existing spoke subnet
  # spoke3 = {
  #   subnet_id      = "/subscriptions/<sub>/resourceGroups/spoke3-rg/providers/Microsoft.Network/virtualNetworks/spoke3-vnet/subnets/pe-subnet"
  #   resource_group = "spoke3-rg"
  # }
}
