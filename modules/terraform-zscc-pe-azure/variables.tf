variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the PE module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the PE module resources"
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
  description = "Resource group in the spoke for the Private Endpoint and DNS resources"
}

variable "location" {
  type        = string
  description = "Azure region of the spoke VNet"
}

variable "subnet_id" {
  type        = string
  description = "ID of the existing spoke subnet to place the Private Endpoint in"
}

variable "pls_id" {
  type        = string
  description = "ID of the Cloud Connector Private Link Service"
}

variable "is_manual_connection" {
  type        = bool
  description = "true: connection requires manual approval on the Private Link Service. false: the spoke subscription is in the PLS auto-approval list"
  default     = false
}

variable "request_message" {
  type        = string
  description = "Message sent to the PLS owner when is_manual_connection is true"
  default     = "Request access to Zscaler Cloud Connector"
}

variable "static_ip" {
  type        = string
  description = "Optional static private IP for the Private Endpoint (recommended when PAC files or proxy settings reference the IP)"
  default     = null
}

variable "create_dns_zone" {
  type        = bool
  description = "true: create a private DNS zone in the spoke and link it to the spoke VNet. false: add the A record to an existing zone (dns_zone_name / dns_zone_resource_group) or skip DNS if dns_zone_name is null"
  default     = true
}

variable "dns_zone_name" {
  type        = string
  description = "Private DNS zone name for the proxy record"
  default     = "zscaler.internal"
}

variable "dns_zone_resource_group" {
  type        = string
  description = "Resource group of an existing DNS zone when create_dns_zone is false. Defaults to var.resource_group"
  default     = null
}

variable "dns_record_name" {
  type        = string
  description = "A record name for the proxy endpoint"
  default     = "proxy"
}

variable "dns_ttl" {
  type        = number
  description = "TTL in seconds of the proxy A record"
  default     = 300
}
