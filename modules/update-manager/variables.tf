variable "weds-maintenance-recurrence" {
  type        = string
  description = "The name to be used for Wednesday maintenance configuration."
  default     = "Month Fourth Wednesday"
}

variable "weds-maintenance-only-recurrence" {
  type        = string
  description = "The name to be used for Wednesday maintenance only configuration."
  default     = "Month Fourth Wednesday"
}

variable "definition-updates-recurrence" {
  type        = string
  description = "The name to be used for definition update configuration."
  default     = "Week Monday,Tuesday,Wednesday,Thursday,Friday"
}

variable "image-updates-recurrence" {
  type        = string
  description = "The name to be used for image server update configuration."
  default     = "Month Fourth Wednesday"
}

variable "dynamicscopetargetrg" {
  type        = string
  description = "The name to be used for the resource group that the dynamic scope will target to include VMs into schedule."
}

variable "weds-maintenance-start_date_time" {
  type        = string
  description = "Start time and date for Wednesday Maintenance - Maintenance Configuration."
  default     = "2024-06-06 18:00"
}

variable "weds-maintenance-time_zone" {
  type        = string
  description = "Time zone for Wednesday Maintenance - Maintenance Configuration."
  default     = "GMT Standard Time"
}

variable "weds-maintenance-duration" {
  type        = string
  description = "Schedule duration for Wednesday Maintenance - Maintenance Configuration."
  default     = "04:00"
}

variable "weds-maintenance-only-start_date_time" {
  type        = string
  description = "Start time and date for Wednesday Only Maintenance - Maintenance Configuration."
  default     = "2024-06-07 15:00"
}

variable "weds-maintenance-only-time_zone" {
  type        = string
  description = "Time zone for Wednesday Only Maintenance - Maintenance Configuration."
  default     = "GMT Standard Time"
}

variable "weds-maintenance-only-duration" {
  type        = string
  description = "Schedule duration for Wednesday Only Maintenance - Maintenance Configuration."
  default     = "03:00"
}

variable "definition-updates-start_date_time" {
  type        = string
  description = "Start time and date for Definition Updates - Maintenance Configuration."
  default     = "2024-06-07 13:00"
}

variable "definition-updates-time_zone" {
  type        = string
  description = "Time zone for Definition Updates - Maintenance Configuration."
  default     = "GMT Standard Time"
}

variable "definition-updates-duration" {
  type        = string
  description = "Schedule duration for Definition Updates - Maintenance Configuration."
  default     = "03:00"
}

variable "image-updates-start_date_time" {
  type        = string
  description = "Start time and date for Image Server Updates - Maintenance Configuration."
  default     = "2024-06-07 06:00"
}

variable "image-updates-time_zone" {
  type        = string
  description = "Time zone for Image Server Updates - Maintenance Configuration."
  default     = "GMT Standard Time"
}

variable "image-updates-duration" {
  type        = string
  description = "Schedule duration for Image Server Updates - Maintenance Configuration.."
  default     = "03:00"
}

variable "tag_environment" {
  type        = string
  description = "Customer environment such as UAT."
}

variable "create-weds-maintenance" {
  type        = bool
  description = "Flag to trigger creation of Maintenance Configuration - true or false."
}

variable "create-weds-maintenance-only" {
  type        = bool
  description = "Flag to trigger creation of Maintenance Configuration - true or false."
}

variable "create-definition-updates" {
  type        = bool
  description = "Flag to trigger creation of Maintenance Configuration - true or false."
}

variable "create-image-updates" {
  type        = bool
  description = "Flag to trigger creation of Maintenance Configuration - true or false."
}

variable "pipeline_name" {
  type = string
  description = "Name of the pipeline that owns the state of this code"
}

variable "prefix" {
}

variable "role_tag_values" {
  description = "List of values for the 'Role' tag to include in the dynamic maintenance scopes."
  type        = list(string)
  default     = [
    "server",
    "azure_devops"
  ]
}

variable "webhook_expiry_date" {
  type = string
  description = "Expiry date of the automation account runbook webhook."
  default = "2026-12-31T00:00:00Z"
}


variable "ppd_pre_event_create" {
  type        = bool
  description = "Flag to trigger creation of the PreProd pre event - true or false."
  default     = false
}
