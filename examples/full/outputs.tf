output "storage" {
  description = "Buckets, custom domain state, queue notifications and catalog details."
  value = {
    buckets             = module.storage.buckets
    custom_domains      = module.storage.custom_domains
    event_notifications = module.storage.event_notifications
    data_catalogs       = module.storage.data_catalogs
  }
}
