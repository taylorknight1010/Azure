variable "location" {
  default = "uksouth"
}

variable "tag_environment" {
  type        = string
  description = "Customer environment such as UAT."
}

variable "CustomerName" {
  type        = string
  description = "Customer Name in 3 letters such as IBM."
}

variable "pipeline_name" {
  type = string
  description = "Name of the pipeline that owns the state of this code"
}

variable "image_server_name" {
  type        = string
  description = "Name of the image server. This is optional, will be auto-generated if not provided."
  default     = null
}

variable "ppd_poweron_runbook_create" {
  type        = bool
  description = "Flag to trigger creation of the Power On PreProd Environment runbook - true or false."
  default     = false
}
