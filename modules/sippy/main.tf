resource "cloudflare_r2_bucket_sippy" "this" {
  count = var.create ? 1 : 0

  account_id   = var.account_id
  bucket_name  = var.bucket_name
  jurisdiction = var.jurisdiction
  source       = var.source_storage
  destination  = var.destination

  lifecycle {
    precondition {
      condition     = try(length(trimspace(var.account_id)) > 0 && length(trimspace(var.bucket_name)) > 0, false)
      error_message = "Sippy requires account_id and bucket_name when create is true."
    }
  }
}
