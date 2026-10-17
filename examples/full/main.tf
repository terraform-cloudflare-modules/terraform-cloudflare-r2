module "storage" {
  source = "../.."

  create      = true
  account_id  = var.account_id
  name_prefix = "example-"
  defaults = {
    account_id    = var.account_id
    jurisdiction  = "default"
    location      = "weur"
    storage_class = "Standard"
    cors_rules = [{
      id              = "application"
      allowed_methods = ["GET", "HEAD", "PUT"]
      allowed_origins = ["https://app.example.com"]
      allowed_headers = ["Content-Type", "Range"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3600
    }]
    lifecycle_rules = [{
      id         = "archive-logs"
      enabled    = true
      conditions = { prefix = "logs/" }
      abort_multipart_uploads_transition = {
        condition = { type = "Age", max_age = 7 * 24 * 60 * 60 }
      }
      delete_objects_transition = {
        condition = { type = "Age", max_age = 365 * 24 * 60 * 60 }
      }
      storage_class_transitions = [{
        condition     = { type = "Age", max_age = 30 * 24 * 60 * 60 }
        storage_class = "InfrequentAccess"
      }]
      }, {
      id         = "dated-campaign"
      enabled    = false
      conditions = { prefix = "campaign/" }
      delete_objects_transition = {
        condition = { type = "Date", date = "2031-01-01T00:00:00Z" }
      }
      storage_class_transitions = [{
        condition     = { type = "Date", date = "2030-01-01T00:00:00Z" }
        storage_class = "InfrequentAccess"
      }]
    }]
    lock_rules = [{
      id        = "retain-logs"
      enabled   = true
      prefix    = "logs/"
      condition = { type = "Age", max_age_seconds = 7 * 24 * 60 * 60 }
      }, {
      id        = "retain-until-date"
      enabled   = false
      prefix    = "dated/"
      condition = { type = "Date", date = "2030-01-01T00:00:00Z" }
      }, {
      id        = "retain-indefinitely"
      enabled   = false
      prefix    = "legal/"
      condition = { type = "Indefinite" }
    }]
    managed_domain      = { enabled = false }
    custom_domains      = {}
    event_notifications = {}
    create_data_catalog = false
  }
  buckets = {
    assets = {
      name          = "example-public-assets"
      account_id    = var.account_id
      jurisdiction  = "default"
      location      = "weur"
      storage_class = "Standard"
      custom_domains = {
        public = {
          domain  = var.assets_domain
          zone_id = var.zone_id
          enabled = true
          min_tls = "1.2"
          ciphers = ["ECDHE-ECDSA-AES128-GCM-SHA256", "ECDHE-RSA-AES128-GCM-SHA256"]
        }
      }
      event_notifications = {
        images = {
          queue_id = var.queue_id
          rules = [{
            actions     = ["PutObject", "CopyObject", "CompleteMultipartUpload"]
            description = "New image objects"
            prefix      = "images/"
            suffix      = ".jpg"
            }, {
            actions     = ["DeleteObject", "LifecycleDeletion"]
            description = "Removed image objects"
            prefix      = "images/"
            suffix      = ".jpg"
          }]
        }
      }
    }
    catalog = {
      # Keep generic expiration/retention rules away from catalog-managed files.
      cors_rules          = []
      lifecycle_rules     = []
      lock_rules          = []
      managed_domain      = { enabled = false }
      custom_domains      = {}
      event_notifications = {}
      create_data_catalog = true
    }
  }
}
