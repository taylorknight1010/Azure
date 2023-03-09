variable "hubvnet" {
  type = map(string)
}

variable "coresubnet" {
  type = map(string)
}

variable "location" {
  description = "The location which should be used for this virtual network."
  type = string
}

variable "tags" {
  description = "The tags which should be used for this virtual network."
  type = map
}

