variable "account_id" {
  description = "Cloudflare account with R2 enabled."
  type        = string
}
variable "zone_id" {
  description = "Existing zone in the same account as the assets bucket."
  type        = string
}
variable "assets_domain" {
  description = "Available hostname under that zone, such as assets.example.com."
  type        = string
}
variable "queue_id" {
  description = "Existing Cloudflare Queue in the same account, with consumers managed separately."
  type        = string
}
