variable "env_subscription_id" {
  type        = string
  description = "Azure Subscription ID where the Cloud Connector load balancer and spokes reside"
}

variable "arm_location" {
  type        = string
  description = "The Azure Region where the Cloud Connector load balancer is deployed"
  default     = "eastus"
}

variable "name_prefix" {
  type        = string
  description = "The name prefix for all your resources"
  default     = "zscc"
}

variable "owner_tag" {
  type        = string
  description = "populate custom owner tag attribute"
  default     = "zscc-admin"
}

variable "environment" {
  type        = string
  description = "Customer defined environment tag. ie: Dev, QA, Prod, etc."
  default     = "Development"
}

variable "cc_lb_name" {
  type        = string
  description = "Name of the existing Cloud Connector internal load balancer (e.g. zscc-cc-lb-<tag>)"
}

variable "cc_lb_resource_group" {
  type        = string
  description = "Resource group of the existing Cloud Connector load balancer. The Private Link Service is created here too"
}

variable "cc_lb_frontend_name" {
  type        = string
  description = "Optional LB frontend IP configuration name. Defaults to the first frontend"
  default     = null
}

variable "create_nat_subnet" {
  type        = bool
  description = "Create a dedicated /28 NAT subnet for the Private Link Service in the load balancer VNet"
  default     = true
}

variable "nat_subnet_cidr" {
  type        = string
  description = "Optional /28 for the PLS NAT subnet. Defaults to the last /28 of the load balancer VNet address space"
  default     = null
}

variable "nat_subnet_id" {
  type        = string
  description = "Existing NAT subnet ID when create_nat_subnet is false"
  default     = null
}

variable "nat_ip_count" {
  type        = number
  description = "Number of PLS NAT IPs (1-8)"
  default     = 2
}

variable "visibility_subscription_ids" {
  type        = list(string)
  description = "Subscriptions allowed to request connections to the PLS. Defaults to the current subscription"
  default     = []
}

variable "auto_approval_subscription_ids" {
  type        = list(string)
  description = "Subscriptions auto-approved on the PLS. Defaults to the current subscription"
  default     = []
}

variable "proxy_protocol_enabled" {
  type        = bool
  description = "Enable TCP Proxy Protocol v2 on the PLS. Leave false unless Cloud Connector is confirmed to parse PROXY v2"
  default     = false
}

variable "spokes" {
  type = map(object({
    address_space           = optional(string)
    pe_subnet_cidr          = optional(string)
    workload_subnet_cidr    = optional(string)
    subnet_id               = optional(string)
    workload_subnet_id      = optional(string)
    test_vm                 = optional(bool, true)
    bastion                 = optional(bool)
    bastion_sku             = optional(string)
    bastion_subnet_cidr     = optional(string)
    resource_group          = optional(string)
    location                = optional(string)
    static_ip               = optional(string)
    is_manual_connection    = optional(bool, false)
    create_dns_zone         = optional(bool, true)
    dns_zone_name           = optional(string, "zscaler.internal")
    dns_zone_resource_group = optional(string)
    dns_record_name         = optional(string, "proxy")
  }))
  description = "Map of spoke name => settings. Set address_space to create a new spoke network, or subnet_id + resource_group to use an existing spoke subnet"
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.spokes :
      (v.address_space != null) != (v.subnet_id != null) && (v.subnet_id == null || v.resource_group != null)
    ])
    error_message = "Each spoke must set either address_space (new network) or subnet_id + resource_group (existing subnet), not both."
  }
}

variable "test_vm_enabled" {
  type        = bool
  description = "Deploy a private test VM in each spoke workload subnet (per-spoke opt-out with test_vm = false)"
  default     = true
}

variable "test_vm_size" {
  type        = string
  description = "Test VM size"
  default     = "Standard_B2s"
}

variable "test_vm_ssh_public_key" {
  type        = string
  description = "Optional SSH public key for all test VMs. When null, one generated key pair (../<name_prefix>-key-<suffix>.pem) is used for every VM"
  default     = null
}

variable "proxy_port" {
  type        = number
  description = "Cloud Connector explicit proxy port. When set, test VMs get system-wide and apt proxy settings"
  default     = null
}

variable "bastion_enabled" {
  type        = bool
  description = "Deploy Azure Bastion in each new spoke for SSH to the private test VMs (per-spoke override with bastion = true/false)"
  default     = false
}

variable "bastion_sku" {
  type        = string
  description = "Default Azure Bastion SKU for spoke Bastions (per-spoke override with bastion_sku). Standard enables az network bastion ssh; Developer is free but portal-only and region-limited"
  default     = "Standard"
}
