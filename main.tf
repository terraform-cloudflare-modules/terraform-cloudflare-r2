resource "cloudflare_r2_bucket" "this" {
  for_each = local.buckets

  account_id    = local.account_ids[each.key]
  name          = local.names[each.key]
  jurisdiction  = each.value.jurisdiction
  location      = each.value.location
  storage_class = each.value.storage_class

  lifecycle {
    precondition {
      condition     = try(length(trimspace(local.account_ids[each.key])) > 0, false)
      error_message = "Each bucket requires an account_id, either shared or per bucket."
    }
    precondition {
      condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", local.names[each.key]))
      error_message = "R2 bucket names must be 3-63 lowercase letters, digits or hyphens and start/end with a letter or digit."
    }
    precondition {
      condition = length(local.buckets) == length(distinct([
        for key, bucket in local.buckets : jsonencode([local.account_ids[key], coalesce(bucket.jurisdiction, "default"), local.names[key]])
      ]))
      error_message = "Bucket names must be unique within an account and jurisdiction."
    }
  }
}

resource "cloudflare_r2_bucket_cors" "this" {
  for_each = { for key, bucket in local.buckets : key => bucket if bucket.cors_rules != null }

  account_id   = cloudflare_r2_bucket.this[each.key].account_id
  bucket_name  = cloudflare_r2_bucket.this[each.key].name
  jurisdiction = cloudflare_r2_bucket.this[each.key].jurisdiction
  rules = [for rule in each.value.cors_rules : {
    id = rule.id
    allowed = {
      methods = rule.allowed_methods
      origins = rule.allowed_origins
      headers = rule.allowed_headers
    }
    expose_headers  = rule.expose_headers
    max_age_seconds = rule.max_age_seconds
  }]
}

resource "cloudflare_r2_bucket_lifecycle" "this" {
  for_each = { for key, bucket in local.buckets : key => bucket if bucket.lifecycle_rules != null }

  account_id   = cloudflare_r2_bucket.this[each.key].account_id
  bucket_name  = cloudflare_r2_bucket.this[each.key].name
  jurisdiction = cloudflare_r2_bucket.this[each.key].jurisdiction
  rules        = each.value.lifecycle_rules

  lifecycle {
    precondition {
      condition     = length(each.value.lifecycle_rules) == length(distinct([for rule in each.value.lifecycle_rules : rule.id]))
      error_message = "Lifecycle rule IDs must be unique within each bucket."
    }
  }
}

resource "cloudflare_r2_bucket_lock" "this" {
  for_each = { for key, bucket in local.buckets : key => bucket if bucket.lock_rules != null }

  account_id   = cloudflare_r2_bucket.this[each.key].account_id
  bucket_name  = cloudflare_r2_bucket.this[each.key].name
  jurisdiction = cloudflare_r2_bucket.this[each.key].jurisdiction
  rules        = each.value.lock_rules

  lifecycle {
    precondition {
      condition     = length(each.value.lock_rules) == length(distinct([for rule in each.value.lock_rules : rule.id]))
      error_message = "Lock rule IDs must be unique within each bucket."
    }
  }
}

resource "cloudflare_r2_managed_domain" "this" {
  for_each = { for key, bucket in local.buckets : key => bucket if bucket.managed_domain != null }

  account_id   = cloudflare_r2_bucket.this[each.key].account_id
  bucket_name  = cloudflare_r2_bucket.this[each.key].name
  jurisdiction = cloudflare_r2_bucket.this[each.key].jurisdiction
  enabled      = each.value.managed_domain.enabled
}

resource "cloudflare_r2_custom_domain" "this" {
  for_each = local.custom_domains

  account_id   = cloudflare_r2_bucket.this[each.value.bucket_key].account_id
  bucket_name  = cloudflare_r2_bucket.this[each.value.bucket_key].name
  jurisdiction = cloudflare_r2_bucket.this[each.value.bucket_key].jurisdiction
  domain       = each.value.domain
  zone_id      = each.value.zone_id
  enabled      = each.value.enabled
  min_tls      = each.value.min_tls
  ciphers      = each.value.ciphers
}

resource "cloudflare_r2_bucket_event_notification" "this" {
  for_each = local.event_notifications

  account_id   = cloudflare_r2_bucket.this[each.value.bucket_key].account_id
  bucket_name  = cloudflare_r2_bucket.this[each.value.bucket_key].name
  jurisdiction = cloudflare_r2_bucket.this[each.value.bucket_key].jurisdiction
  queue_id     = each.value.queue_id
  rules        = each.value.rules

  lifecycle {
    precondition {
      condition = length(local.buckets[each.value.bucket_key].event_notifications) == length(distinct([
        for notification in local.buckets[each.value.bucket_key].event_notifications : notification.queue_id
      ]))
      error_message = "Use one event_notifications entry per queue in a bucket, with all its rules together."
    }
  }
}

resource "cloudflare_r2_data_catalog" "this" {
  for_each = { for key, bucket in local.buckets : key => bucket if bucket.create_data_catalog }

  account_id  = cloudflare_r2_bucket.this[each.key].account_id
  bucket_name = cloudflare_r2_bucket.this[each.key].name

  lifecycle {
    precondition {
      condition     = coalesce(each.value.jurisdiction, "default") == "default"
      error_message = "The catalog resource has no jurisdiction selector; use a default-jurisdiction bucket."
    }
  }
}
