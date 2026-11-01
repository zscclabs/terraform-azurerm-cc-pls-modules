variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the spoke network module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the spoke network module resources"
  default     = null
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "spoke_name" {
  type        = string
  description = "Short name of the spoke, used in resource names"
}

variable "location" {
  type        = string
  description = "Azure region for the spoke network"
}

variable "address_space" {
  type        = string
  description = "Spoke VNet address space (e.g. 10.0.0.0/16). May overlap with the hub and other spokes"

  validation {
    condition     = can(cidrhost(var.address_space, 0)) && tonumber(split("/", var.address_space)[1]) <= 20
    error_message = "address_space must be a valid IPv4 CIDR of /20 or larger (default subnets are carved with 8 extra bits)."
  }
}

variable "pe_subnet_cidr" {
  type        = string
  description = "Private Endpoint subnet CIDR. Defaults to cidrsubnet(address_space, 8, 0), e.g. 10.0.0.0/24 for 10.0.0.0/16"
  default     = null
}

variable "workload_subnet_cidr" {
  type        = string
  description = "Workload subnet CIDR. Defaults to cidrsubnet(address_space, 8, 1), e.g. 10.0.1.0/24 for 10.0.0.0/16"
  default     = null
}

variable "bastion_enabled" {
  type        = bool
  description = "Deploy Azure Bastion in the spoke for SSH to private VMs"
  default     = false
}

variable "bastion_sku" {
  type        = string
  description = "Azure Bastion SKU. Developer: free, portal-only, limited regions (not East US). Standard/Premium enable native client tunneling (az network bastion ssh)"
  default     = "Standard"

  validation {
    condition     = contains(["Developer", "Basic", "Standard", "Premium"], var.bastion_sku)
    error_message = "bastion_sku must be Developer, Basic, Standard or Premium."
  }
}

variable "bastion_subnet_cidr" {
  type        = string
  description = "AzureBastionSubnet CIDR (/26 or larger, not used by Developer SKU). Defaults to cidrsubnet(cidrsubnet(address_space, 8, 2), 2, 0), e.g. 10.0.2.0/26 for 10.0.0.0/16"
  default     = null
}
