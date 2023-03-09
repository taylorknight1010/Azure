variable "hubvnet" {
  description = "The name which should be used for this virtual network."
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
