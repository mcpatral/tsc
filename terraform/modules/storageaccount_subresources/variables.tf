variable "storage_account_name" {
  description = "Storage account name"
  type        = string
}

variable "storage_account_id" {
  description = "Storage account id"
  type        = string
}

variable "nfsv3_enabled" {
  description = "Is nfsv3 enabled?"
  type        = bool
}

variable "is_hns_enabled" {
  description = "Is hns enabled?"
  type        = bool
}

variable "containers" {
  type = map(object({
    include_in_management_policy = bool
    parent_directories = optional(map(object({
      acls = optional(map(list(string)))
    })), {})
    directories = optional(map(object({
      acls = optional(map(list(string)))
    })), {})
  }))
  default = {}
}