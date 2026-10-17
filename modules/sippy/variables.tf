variable "create" {
  description = "Whether to manage Sippy for this bucket. Setting false removes the resource and disables migration."
  type        = bool
  default     = true
  nullable    = false
}
variable "account_id" {
  description = "Cloudflare account that owns the destination bucket."
  type        = string
  default     = null
}
variable "bucket_name" {
  description = "Existing destination R2 bucket name, for example from the root module's names output."
  type        = string
  default     = null
}
variable "jurisdiction" {
  description = "Destination bucket jurisdiction. Must match the bucket; null delegates to the provider."
  type        = string
  default     = null
}
variable "source_storage" {
  description = "Source storage configuration. Terraform reserves source for module addressing, so this maps to the provider's source field. Credentials remain in state."
  type = object({
    cloud_provider    = optional(string)
    access_key_id     = optional(string)
    secret_access_key = optional(string)
    bucket            = optional(string)
    region            = optional(string)
    bucket_url        = optional(string)
    client_email      = optional(string)
    private_key       = optional(string)
    account_name      = optional(string)
    container         = optional(string)
    account_key       = optional(string)
    sas_token         = optional(string)
  })
  default   = null
  sensitive = true
  validation {
    condition     = var.source_storage == null ? true : !(var.source_storage.account_key != null && var.source_storage.sas_token != null)
    error_message = "Azure sources accept either account_key or sas_token, never both."
  }
}
variable "destination" {
  description = "R2 write credentials used by Sippy. Use credentials scoped to the destination bucket. Credentials remain in state."
  type = object({
    cloud_provider    = optional(string)
    access_key_id     = optional(string)
    secret_access_key = optional(string)
  })
  default   = null
  sensitive = true
}
