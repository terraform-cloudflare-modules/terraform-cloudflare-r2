resource "terraform_data" "upstream" {
  input = { account_id = "0123456789abcdef0123456789abcdef", name = "computed-bucket", zone_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", queue_id = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", enabled = false, age = 86400 }
}
module "r2" {
  source     = "../../.."
  account_id = terraform_data.upstream.output.account_id
  buckets = { assets = {
    name                = terraform_data.upstream.output.name
    managed_domain      = { enabled = terraform_data.upstream.output.enabled }
    cors_rules          = [{ allowed_methods = ["GET"], allowed_origins = ["https://example.com"] }]
    custom_domains      = { public = { domain = "assets.example.com", zone_id = terraform_data.upstream.output.zone_id } }
    event_notifications = { images = { queue_id = terraform_data.upstream.output.queue_id, rules = [{ actions = ["PutObject"] }] } }
    lifecycle_rules     = [{ id = "expire", delete_objects_transition = { condition = { type = "Age", max_age = terraform_data.upstream.output.age } } }]
    lock_rules          = [{ id = "retain", condition = { type = "Age", max_age_seconds = terraform_data.upstream.output.age } }]
    create_data_catalog = true
  } }
}
output "bucket_keys" {
  description = "Known resource keys for unknown-value planning."
  value       = keys(module.r2.buckets)
}
output "domain_keys" {
  description = "Known resource keys for unknown-value planning."
  value       = keys(module.r2.custom_domains.assets)
}
output "notification_keys" {
  description = "Known resource keys for unknown-value planning."
  value       = keys(module.r2.event_notifications.assets)
}
output "cors_keys" {
  description = "Known resource keys for unknown-value planning."
  value       = keys(module.r2.cors)
}
output "managed_domain_keys" {
  description = "Known resource keys for unknown-value planning."
  value       = keys(module.r2.managed_domains)
}
output "lifecycle_keys" {
  description = "Known resource keys for unknown-value planning."
  value       = keys(module.r2.lifecycle)
}
output "lock_keys" {
  description = "Known resource keys for unknown-value planning."
  value       = keys(module.r2.locks)
}
output "catalog_keys" {
  description = "Known resource keys for unknown-value planning."
  value       = keys(module.r2.data_catalogs)
}
