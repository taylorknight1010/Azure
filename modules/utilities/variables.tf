variable "prefix" {
}

variable "tag_environment" {
  type = string
  description = "Customer environment such as sandbox, uat, prod."
}

variable "pipeline_name" {
  type = string
  description = "Name of the pipeline that owns the state of this code"
}

variable "log_analytics_workspace_name" {
  description = "The resource ID of the Log Analytics Workspace"
  type        = string
}

variable "log_analytics_workspace_rg" {
  description = "The resource group where the Log Analytics Workspace is stored"
  type        = string
}

variable "service_principal_object_id" {
  description = "Object ID of the service principal that runs this pipeline. Used in Key Vault creation" # Enterprise Application object id
  type        = string
}

variable "rsv_create" {
  type        = bool
  description = "Flag to trigger creation of the Recovery Services Vaults - true or false."
  default = true
}

variable "kv_create" {
  type        = bool
  description = "Flag to trigger creation of the Key Vaults - true or false."
  default = true
}

variable "monitor_create" {
  type        = bool
  description = "Flag to trigger creation of Azure Monitor Action Groups - true or false."
  default = true
}

variable "alerts_create" {
  type        = bool
  description = "Flag to trigger creation of Azure Monitor alerts - true or false."
  default = true
}

variable "storage_create" {
  type        = bool
  description = "Flag to trigger creation of the Storage Accounts - true or false."
  default = true
}

variable "law_create" {
  type        = bool
  description = "Flag to trigger creation of the Log Analytics Workspace - true or false."
  default = true
}



