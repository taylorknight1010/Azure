variable "domainsuffix" {
  type = string
}

variable "log_analytics_workspace_id" {
  description = "The resource ID of the Log Analytics Workspace"
  type        = string
  default     = "law_workspace_id_tbc"
}

variable "action_group_email" {
  description = "The email address for the action group notification."
  type        = string
  default     = "itsupport@customerName.co.uk"
}


variable "tag_environment" {
  description = "Custom environment such as UAT"
  type        = string
}

variable "pipeline_name" {
  type = string
  description = "Name of the pipeline that owns the state of this code"
}

variable "prefix" {
  description = "3 Letter acronym for Managed Services Customer"
}
