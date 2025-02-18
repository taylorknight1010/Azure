variable "azurerm_subscription_id" {
  description = "The name of the subscription that the service health alerts are scoped too"
  type        = string
}

variable "servicehealthtargetrg" {
  description = "The name of the resource group that the service health alerts are stored in"
  type        = string
}

variable "monitor_activity_log_alert" {
  type        = string
  description = "The name of the activity log alert"
}

variable "monitor_activity_log_alert_description" {
  type        = string
  description = "The description of this activity log alert."
}

variable "tag_environment" {
  type        = string
  description = "Customer environment tag value, for example UAT."
}

variable "azurerm_resource_group_itmailboxrg" {
  type        = string
  description = "The name of the resource group that the IT Mailbox Action Group is stored in."
}

variable "pipeline_name" {
  type = string
  description = "Name of the pipeline that owns the state of this code"
}

variable "location" {
  type = string
  description = "Azure Region to be used"
  default = "uksouth"
}
