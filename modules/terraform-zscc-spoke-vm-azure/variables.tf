variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the test VM module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the test VM module resources"
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

variable "resource_group" {
  type        = string
  description = "Spoke resource group for the test VM"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "subnet_id" {
  type        = string
  description = "Private spoke workload subnet ID for the test VM"
}

variable "vm_size" {
  type        = string
  description = "Test VM size"
  default     = "Standard_B2s"
}

variable "admin_username" {
  type        = string
  description = "Admin username"
  default     = "azureuser"
}

variable "create_ssh_key" {
  type        = bool
  description = "true: generate a per-VM SSH key pair. false: use ssh_public_key (e.g. one shared key for all VMs)"
  default     = true
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for the admin user. Required when create_ssh_key is false"
  default     = null
}

variable "proxy_fqdn" {
  type        = string
  description = "Proxy FQDN resolving to the spoke Private Endpoint"
}

variable "proxy_port" {
  type        = number
  description = "Cloud Connector explicit proxy port. When set, the VM gets system-wide and apt proxy settings"
  default     = null
}

variable "tcp_check_ports" {
  type        = list(number)
  description = "Ports proxy-test connects to through the Private Endpoint to verify the Private Link path"
  default     = [80, 443]
}
