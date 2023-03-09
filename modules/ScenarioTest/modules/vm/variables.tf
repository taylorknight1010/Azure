variable "vm" {
  type    = object({
    id                  = string
    disktype            = list(string)
    location            = string
    size                = string
    os_disk             = map(string)
    source_image_reference = map(string)
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

