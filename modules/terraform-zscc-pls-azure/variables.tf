variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the PLS module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the PLS module resources"
  default     = null
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "resource_group" {
  type        = string
  description = "Resource group in which the Private Link Service is created"
}

variable "location" {
  type        = string
  description = "Azure region. Must match the region of the Cloud Connector load balancer and hub VNet"
}

variable "cc_lb_name" {
  type        = string
  description = "Name of the existing Cloud Connector internal Standard Load Balancer"
}

variable "cc_lb_resource_group" {
  type        = string
  description = "Resource group of the existing Cloud Connector load balancer"
}

variable "cc_lb_frontend_name" {
  type        = string
  description = "Name of the load balancer frontend IP configuration to attach the Private Link Service to. Defaults to the first frontend"
  default     = null
}

variable "create_nat_subnet" {
  type        = bool
  description = "true: create a dedicated /28 NAT subnet in the load balancer VNet. false: use var.nat_subnet_id"
  default     = true
}

variable "nat_subnet_cidr" {
  type        = string
  description = "Optional /28 CIDR for the NAT subnet. Defaults to the last /28 of the load balancer VNet's first address space"
  default     = null

  validation {
    condition     = var.nat_subnet_cidr == null || endswith(coalesce(var.nat_subnet_cidr, "x"), "/28")
    error_message = "nat_subnet_cidr must be a /28."
  }
}

variable "nat_subnet_id" {
  type        = string
  description = "ID of an existing subnet for Private Link Service NAT IPs. The subnet must have private_link_service_network_policies_enabled = false. Required when create_nat_subnet is false"
  default     = null
}

variable "nat_ip_count" {
  type        = number
  description = "Number of NAT IP configurations on the Private Link Service (1-8). Each NAT IP adds SNAT port capacity"
  default     = 1

  validation {
    condition     = var.nat_ip_count >= 1 && var.nat_ip_count <= 8
    error_message = "nat_ip_count must be between 1 and 8."
  }
}

variable "nat_static_ips" {
  type        = list(string)
  description = "Optional static NAT IPs, by index. Missing entries are allocated dynamically"
  default     = []
}

variable "visibility_subscription_ids" {
  type        = list(string)
  description = "Subscriptions allowed to see/request connections to the Private Link Service. Defaults to the current subscription"
  default     = []
}

variable "auto_approval_subscription_ids" {
  type        = list(string)
  description = "Subscriptions whose Private Endpoint connections are approved automatically. Defaults to the current subscription"
  default     = []
}

variable "proxy_protocol_enabled" {
  type        = bool
  description = "Enable TCP Proxy Protocol v2 to pass the original consumer source IP and LinkID. Only enable if Cloud Connector can parse PROXY v2 headers; health probes will also carry the header"
  default     = false
}
