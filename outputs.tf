output "buckets" {
  description = "Complete bucket objects indexed by stable caller keys, after all managed settings are applied."
  value       = cloudflare_r2_bucket.this
  depends_on  = [cloudflare_r2_bucket_cors.this, cloudflare_r2_bucket_lifecycle.this, cloudflare_r2_bucket_lock.this, cloudflare_r2_managed_domain.this, cloudflare_r2_custom_domain.this, cloudflare_r2_bucket_event_notification.this, cloudflare_r2_data_catalog.this]
}

output "ids" {
  description = "Provider bucket IDs indexed by stable caller keys."
  value       = { for key, bucket in cloudflare_r2_bucket.this : key => bucket.id }
  depends_on  = [cloudflare_r2_bucket_cors.this, cloudflare_r2_bucket_lifecycle.this, cloudflare_r2_bucket_lock.this, cloudflare_r2_managed_domain.this, cloudflare_r2_custom_domain.this, cloudflare_r2_bucket_event_notification.this, cloudflare_r2_data_catalog.this]
}

output "names" {
  description = "Bucket names for S3 clients and Workers bindings, indexed by stable caller keys."
  value       = { for key, bucket in cloudflare_r2_bucket.this : key => bucket.name }
  depends_on  = [cloudflare_r2_bucket_cors.this, cloudflare_r2_bucket_lifecycle.this, cloudflare_r2_bucket_lock.this, cloudflare_r2_managed_domain.this, cloudflare_r2_custom_domain.this, cloudflare_r2_bucket_event_notification.this, cloudflare_r2_data_catalog.this]
}

output "cors" {
  description = "Complete CORS configurations indexed by bucket key."
  value       = cloudflare_r2_bucket_cors.this
}

output "lifecycle" {
  description = "Complete lifecycle configurations indexed by bucket key."
  value       = cloudflare_r2_bucket_lifecycle.this
}

output "locks" {
  description = "Complete lock configurations indexed by bucket key."
  value       = cloudflare_r2_bucket_lock.this
}

output "managed_domains" {
  description = "Complete r2.dev domain objects indexed by bucket key."
  value       = cloudflare_r2_managed_domain.this
}

output "data_catalogs" {
  description = "Complete data catalog objects indexed by bucket key, including computed maintenance settings."
  value       = cloudflare_r2_data_catalog.this
}

output "custom_domains" {
  description = "Complete domain objects indexed first by bucket key, then by caller domain key."
  value       = { for key, bucket in local.buckets : key => { for domain_key, domain in bucket.custom_domains : domain_key => cloudflare_r2_custom_domain.this[jsonencode([key, domain_key])] } }
}

output "event_notifications" {
  description = "Complete notification objects indexed first by bucket key, then by caller notification key."
  value       = { for key, bucket in local.buckets : key => { for notification_key, notification in bucket.event_notifications : notification_key => cloudflare_r2_bucket_event_notification.this[jsonencode([key, notification_key])] } }
}
