variable "utilities_create" {
  type        = bool
  description = "Flag to trigger creation of the Azure Policy - true or false."
  default = true
}

variable "utilities_effect" {
  type        = string
  description = "Azure Policy Effect - Will default to disabled."
  default = "Disabled"
}

variable "ama_create" {
  type        = bool
  description = "Flag to trigger creation of the Azure Policy - true or false."
  default = true
}

variable "ama_effect" {
  type        = string
  description = "Azure Policy Effect - Will default to disabled."
  default = "Disabled"
}

variable "monitoring_create" {
  type        = bool
  description = "Flag to trigger creation of the Azure Policy - true or false."
  default = true
}

variable "monitoring_effect" {
  type        = string
  description = "Azure Policy Effect - Will default to Disabled."
  default = "Disabled"
}

variable "security_create" {
  type        = bool
  description = "Flag to trigger creation of the Azure Policy - true or false."
  default = true
}

variable "security_effect" {
  type        = string
  description = "Azure Policy Effect - Will default to disabled."
  default = "Disabled"
}

variable "governance_create" {
  type        = bool
  description = "Flag to trigger creation of the Azure Policy - true or false."
  default = true
}

variable "governance_effect" {
  type        = string
  description = "Azure Policy Effect - Will default to disabled."
  default = "Disabled"
}

variable "deny_public_access_create" {
  type        = bool
  description = "Flag to trigger creation of the Azure Policy - true or false."
  default = true
}

variable "deny_public_access_effect" {
  type        = string
  description = "Azure Policy Effect - Will default to disabled."
  default = "Disabled"
}

variable "logAnalytics" {
  type        = string
  description = "Log Analytics resource ID Workspace where all monitoring logs stream too."
}


variable "bringYourOwnUserAssignedManagedIdentity" {
  type        = bool
  description = "true or false to create a user managed identity or provide an existing one. Defaults to create new"
  default = false
}

variable "dcrResourceId" {
  type        = string
  description = "Data collection rule for AMA resource ID."
}

variable "billing_create" {
  type        = bool
  description = "Flag to trigger creation of the Azure Policy - true or false."
  default = true
}

variable "billing_effect" {
  type        = string
  description = "Azure Policy Effect - Will default to disabled."
  default = "Disabled"
}
