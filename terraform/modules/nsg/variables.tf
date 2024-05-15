variable "resource_group_name" {
  type        = string
  nullable    = false
  description = "Name of the resource group to be imported."
}

variable "location" {
  type        = string
  description = "Region name"
}

variable "name" {
  type        = string
  description = "Create network security group"
}

variable "inbound_security_rules" {
  type = map(object({
    access             = string
    priority           = string
    protocol           = string
    port               = optional(string)
    src_address_prefix = optional(string)
    dst_address_prefix = optional(string)
  }))
  description = "NSG inbound parameters"
  nullable    = false
}

variable "outbound_security_rules" {
  type = map(object({
    access             = string
    priority           = string
    protocol           = string
    port               = optional(string)
    src_address_prefix = optional(string)
    dst_address_prefix = optional(string)
  }))
  description = "NSG outbound parameters"
  nullable    = false
}

variable "tags" {
  type        = map(string)
  description = "The tags to associate with your network and subnets."
}
