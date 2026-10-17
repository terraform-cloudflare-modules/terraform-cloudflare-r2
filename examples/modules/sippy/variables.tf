variable "account_id" {
  description = "Cloudflare account with R2 enabled."
  type        = string
}
variable "create" {
  description = "Whether to manage this migration; false removes an existing Sippy configuration."
  type        = bool
  default     = true
}
variable "bucket_name" {
  description = "Existing destination R2 bucket."
  type        = string
}
variable "jurisdiction" {
  description = "Jurisdiction of the existing destination bucket."
  type        = string
  default     = "default"
}
variable "source_provider" {
  description = "Source alternative to demonstrate: aws, gcs, s3 or azure."
  type        = string
  default     = "aws"
  validation {
    condition     = contains(["aws", "gcs", "s3", "azure"], var.source_provider)
    error_message = "Choose aws, gcs, s3 or azure."
  }
}
variable "source_bucket" {
  description = "AWS or GCS source bucket; required for those source types."
  type        = string
  default     = null
}
variable "source_region" {
  description = "AWS source region; required for AWS."
  type        = string
  default     = null
}
variable "source_bucket_url" {
  description = "S3-compatible source bucket URL; required for s3."
  type        = string
  default     = null
}
variable "source_account_name" {
  description = "Azure source storage account; required for azure."
  type        = string
  default     = null
}
variable "source_container" {
  description = "Azure source container; required for azure."
  type        = string
  default     = null
}
variable "credentials" {
  description = "Existing source read and destination R2 write credentials. Supply fields for the selected source only."
  type = object({
    source_access_key_id          = optional(string)
    source_secret_access_key      = optional(string)
    client_email                  = optional(string)
    private_key                   = optional(string)
    account_key                   = optional(string)
    sas_token                     = optional(string)
    destination_access_key_id     = string
    destination_secret_access_key = string
  })
  sensitive = true
}
