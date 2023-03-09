variable "nic" {
  type = any
}

variable "vm" {
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

