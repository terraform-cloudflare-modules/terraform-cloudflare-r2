output "sippy" {
  description = "Complete Sippy configuration, or null when disabled. Includes sensitive source and destination credentials."
  value       = one(cloudflare_r2_bucket_sippy.this)
  sensitive   = true
}
output "enabled" {
  description = "Provider-reported migration state, or null when unmanaged."
  value       = try(cloudflare_r2_bucket_sippy.this[0].enabled, null)
}
