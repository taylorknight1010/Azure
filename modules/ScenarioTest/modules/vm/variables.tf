variable "resource_group_name" {
  description = "Name of the resource group."
}

variable "tags" {
  description = "Name of the resource group."
}

variable "location" {
  description = "Location for all resources."
}


variable "nic_id" {
  description = "ID of the NIC."
}

variable "coresubnet" {
  description = "ID of the virtual machine."
}

variable "vm_size" {
  description = "Size of the virtual machine."
}

variable "caching" {
  description = "Caching type for the virtual machine OS disk."
}

variable "storage_account_type" {
  description = "Storage account type for the virtual machine OS disk."
}

variable "publisher" {
  description = "Publisher of the virtual machine image."
}

variable "offer" {
  description = "Offer of the virtual machine image."
}

variable "sku" {
  description = "SKU of the virtual machine image."
}

variable "osversion" {
  description = "Operating system version of the virtual machine image."
}

variable "vm_names" {
  description = "Map of virtual machine names to their configurations."
}

variable "managed_disk_type" {
  description = "Map of virtual machine names to their configurations."
}

