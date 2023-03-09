variable "vm" {
  type = object({
    id                  = string
    publisher           = string
    offer               = string
    sku                 = string
    caching             = string
    storage_account_type = string
    size                = string
    osversion           = string
  })
}

variable "nic" {
  type = any
}

variable "hubvnet" {
  type = string
}

variable "coresubnet" {
  type = string
}


variable "location" {
  description = "The location which should be used for this virtual network."
  type = string
}

variable "tags" {
  description = "The tags which should be used for this virtual network."
  type = map
}

variable "resource_group_name" {
  description = "The location which should be used for this virtual network."
  type = any
}

variable "osversion" {
 default = "latest" 
}

