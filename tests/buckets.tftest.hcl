mock_provider "cloudflare" {
  mock_resource "cloudflare_r2_bucket" {
    defaults = { creation_date = "2026-01-01T00:00:00Z", jurisdiction = "default", id = "test-bucket" }
  }
  mock_resource "cloudflare_r2_managed_domain" {
    defaults = { domain = "pub-example.r2.dev" }
  }
  mock_resource "cloudflare_r2_data_catalog" {
    defaults = { id = "catalog-id", status = "active", credential_status = "absent" }
  }
}
# Explicit jurisdiction inputs must not also appear in mock defaults: OpenTofu
# rejects mocks that override configured optional/computed attributes.
mock_provider "cloudflare" {
  alias = "configured_jurisdiction"
}
variables { account_id = "0123456789abcdef0123456789abcdef" }

run "empty_by_default" {
  command = plan
  assert {
    condition     = length(output.buckets) == 0 && length(output.managed_domains) == 0
    error_message = "An empty call must not create resources."
  }
}
run "names_defaults_and_complete_outputs" {
  command = apply
  variables {
    name_prefix = "test-"
    defaults    = { location = "weur", storage_class = "InfrequentAccess" }
    buckets     = { assets = {}, exact = { name = "exact-name", storage_class = "Standard" } }
  }
  assert {
    condition     = output.names.assets == "test-assets" && output.names.exact == "exact-name" && output.ids.assets == "test-bucket"
    error_message = "Stable keys must retain derived and explicit names and provider IDs."
  }
  assert {
    condition     = output.buckets.assets.storage_class == "InfrequentAccess" && output.buckets.exact.storage_class == "Standard" && output.buckets.assets.creation_date == "2026-01-01T00:00:00Z"
    error_message = "Per-bucket overrides and complete computed attributes must be preserved."
  }
  assert {
    condition     = length(output.cors) == 0 && length(output.lifecycle) == 0 && length(output.locks) == 0 && length(output.managed_domains) == 0 && length(output.data_catalogs) == 0
    error_message = "Optional settings must be unmanaged by default."
  }
}
run "account_and_jurisdiction_inheritance" {
  providers = { cloudflare = cloudflare.configured_jurisdiction }
  command   = plan
  variables {
    defaults = { account_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", jurisdiction = "eu", cors_rules = [] }
    buckets  = { inherited = {}, overridden = { account_id = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", jurisdiction = "default" } }
  }
  assert {
    condition     = output.cors.inherited.account_id == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" && output.cors.inherited.jurisdiction == "eu" && output.cors.overridden.account_id == "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" && output.cors.overridden.jurisdiction == "default"
    error_message = "All settings must use their bucket's account and jurisdiction."
  }
}
run "cors_translation_and_whole_list_override" {
  command = plan
  variables {
    defaults = { cors_rules = [{ id = "shared", allowed_methods = ["GET"], allowed_origins = ["https://example.com"], allowed_headers = ["Range"], expose_headers = ["ETag"], max_age_seconds = 3600 }] }
    buckets = {
      inherited = {}
      replaced  = { cors_rules = [{ allowed_methods = ["HEAD"], allowed_origins = ["https://other.example.com"] }] }
      cleared   = { cors_rules = [] }
    }
  }
  assert {
    condition     = output.cors.inherited.rules[0].allowed.methods[0] == "GET" && output.cors.inherited.rules[0].allowed.headers[0] == "Range" && output.cors.inherited.rules[0].expose_headers[0] == "ETag" && output.cors.inherited.rules[0].max_age_seconds == 3600
    error_message = "The Hetzner-style CORS input must preserve every R2 field."
  }
  assert {
    condition     = length(output.cors.cleared.rules) == 0 && length(output.cors.replaced.rules) == 1 && output.cors.replaced.rules[0].id == null && output.cors.replaced.rules[0].allowed.methods[0] == "HEAD"
    error_message = "Lists replace inherited settings entirely; empty lists must clear them."
  }
}
run "lifecycle_and_retention_payloads" {
  command = plan
  variables {
    buckets = { archive = {
      lifecycle_rules = [{
        id                                 = "archive"
        conditions                         = { prefix = "logs/" }
        delete_objects_transition          = { condition = { type = "Age", max_age = 31536000 } }
        abort_multipart_uploads_transition = { condition = { type = "Age", max_age = 604800 } }
        storage_class_transitions          = [{ condition = { type = "Date", date = "2030-01-01T00:00:00Z" }, storage_class = "InfrequentAccess" }]
        }, {
        id                        = "dated"
        enabled                   = false
        delete_objects_transition = { condition = { type = "Date", date = "2031-01-01T00:00:00Z" } }
        storage_class_transitions = [{ condition = { type = "Age", max_age = 2592000 }, storage_class = "InfrequentAccess" }]
      }]
      lock_rules = [
        { id = "age", prefix = "logs/", condition = { type = "Age", max_age_seconds = 604800 } },
        { id = "date", enabled = false, condition = { type = "Date", date = "2030-01-01T00:00:00Z" } },
        { id = "forever", prefix = "legal/", condition = { type = "Indefinite" } }
      ]
    } }
  }
  assert {
    condition     = output.lifecycle.archive.rules[0].enabled && output.lifecycle.archive.rules[1].conditions.prefix == "" && !output.lifecycle.archive.rules[1].enabled && output.lifecycle.archive.rules[0].delete_objects_transition.condition.max_age == 31536000
    error_message = "Lifecycle defaults and Age/Date transition fields must survive normalization."
  }
  assert {
    condition     = output.locks.archive.rules[0].condition.max_age_seconds == 604800 && !output.locks.archive.rules[1].enabled && output.locks.archive.rules[2].condition.type == "Indefinite"
    error_message = "All three R2 retention condition types must remain configurable."
  }
}
run "empty_rule_lists_keep_ownership" {
  command = plan
  variables {
    defaults = { lifecycle_rules = [{ id = "expire", delete_objects_transition = { condition = { type = "Age", max_age = 86400 } } }], lock_rules = [{ id = "retain", condition = { type = "Indefinite" } }] }
    buckets  = { empty = { lifecycle_rules = [], lock_rules = [] } }
  }
  assert {
    condition     = length(output.lifecycle.empty.rules) == 0 && length(output.locks.empty.rules) == 0
    error_message = "Empty lists must retain resources while clearing inherited rules."
  }
}
run "public_access_and_map_overrides" {
  command = apply
  variables {
    defaults = {
      managed_domain = { enabled = true }
      custom_domains = { shared = { domain = "shared.example.com", zone_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" } }
    }
    buckets = {
      assets = {
        managed_domain = { enabled = false }
        custom_domains = { public = { domain = "assets.example.com", zone_id = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", enabled = false, min_tls = "1.2", ciphers = ["ECDHE-ECDSA-AES128-GCM-SHA256"] } }
      }
      other = { custom_domains = {} }
    }
  }
  assert {
    condition     = !output.managed_domains.assets.enabled && output.managed_domains.other.enabled && output.managed_domains.assets.domain == "pub-example.r2.dev"
    error_message = "False must explicitly disable public access without dropping ownership."
  }
  assert {
    condition     = keys(output.custom_domains.assets) == ["public"] && length(output.custom_domains.other) == 0 && !output.custom_domains.assets.public.enabled && output.custom_domains.assets.public.min_tls == "1.2"
    error_message = "Domain maps replace shared maps entirely and preserve disabled domain settings."
  }
}
run "domain_key_fallback" {
  command = plan
  variables { buckets = { assets = { custom_domains = { "assets.example.com" = { zone_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" } } } } }
  assert {
    condition     = output.custom_domains.assets["assets.example.com"].domain == "assets.example.com" && output.custom_domains.assets["assets.example.com"].enabled
    error_message = "Domain names may fall back to the map key."
  }
}
run "notifications_share_external_queue_across_buckets" {
  command = plan
  variables {
    defaults = { event_notifications = { images = { queue_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", rules = [{ actions = ["PutObject", "CopyObject", "CompleteMultipartUpload"], description = "New images", prefix = "images/", suffix = ".jpg" }] } } }
    buckets  = { first = {}, second = {}, cleared = { event_notifications = {} } }
  }
  assert {
    condition     = output.event_notifications.first.images.queue_id == output.event_notifications.second.images.queue_id && output.event_notifications.first.images.rules[0].prefix == "images/" && output.event_notifications.first.images.rules[0].suffix == ".jpg" && length(output.event_notifications.cleared) == 0
    error_message = "Shared queue notifications must retain separate bucket ownership and support empty overrides."
  }
}
run "catalog_activation_and_computed_results" {
  command = apply
  variables {
    defaults = { create_data_catalog = true }
    buckets  = { catalog = {}, plain = { create_data_catalog = false } }
  }
  assert {
    condition     = keys(output.data_catalogs) == ["catalog"] && output.data_catalogs.catalog.id == "catalog-id" && output.data_catalogs.catalog.credential_status == "absent"
    error_message = "Catalog ownership must be explicit and preserve computed results."
  }
}
run "global_disable" {
  command = plan
  variables {
    create   = false
    defaults = { cors_rules = [], lifecycle_rules = [], lock_rules = [], create_data_catalog = true, managed_domain = { enabled = true } }
    buckets  = { ignored = { custom_domains = { public = { domain = "ignored.example.com", zone_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" } }, event_notifications = { queue = { queue_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", rules = [{ actions = ["DeleteObject"] }] } } } }
  }
  assert {
    condition     = length(output.buckets) == 0 && length(output.cors) == 0 && length(output.lifecycle) == 0 && length(output.locks) == 0 && length(output.managed_domains) == 0 && length(output.data_catalogs) == 0 && length(output.custom_domains) == 0 && length(output.event_notifications) == 0
    error_message = "The global flag must suppress the entire resource graph."
  }
}
run "same_names_in_different_accounts" {
  command = plan
  variables { buckets = { first = { name = "shared" }, second = { name = "shared", account_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" } } }
  assert {
    condition     = length(output.buckets) == 2
    error_message = "Names are scoped to accounts and jurisdictions."
  }
}
run "reject_duplicate_names" {
  command = plan
  variables { buckets = { first = { name = "duplicate" }, second = { name = "duplicate" } } }
  expect_failures = [cloudflare_r2_bucket.this]
}
run "reject_invalid_name" {
  command = plan
  variables { buckets = { invalid = { name = "invalid.name" } } }
  expect_failures = [cloudflare_r2_bucket.this]
}
run "reject_missing_account" {
  command = plan
  variables {
    account_id = null
    buckets    = { invalid = {} }
  }
  expect_failures = [cloudflare_r2_bucket.this]
}
run "reject_null_bucket" {
  command = plan
  variables { buckets = { invalid = null } }
  expect_failures = [var.buckets]
}
run "reject_duplicate_lifecycle_ids" {
  command = plan
  variables { buckets = { invalid = { lifecycle_rules = [{ id = "same", delete_objects_transition = { condition = { type = "Age", max_age = 86400 } } }, { id = "same", delete_objects_transition = { condition = { type = "Age", max_age = 172800 } } }] } } }
  expect_failures = [cloudflare_r2_bucket_lifecycle.this]
}
run "reject_duplicate_lock_ids" {
  command = plan
  variables { buckets = { invalid = { lock_rules = [{ id = "same", condition = { type = "Indefinite" } }, { id = "same", condition = { type = "Indefinite" } }] } } }
  expect_failures = [cloudflare_r2_bucket_lock.this]
}
run "reject_duplicate_queue_owners" {
  command = plan
  variables { buckets = { invalid = { event_notifications = { first = { queue_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", rules = [{ actions = ["PutObject"] }] }, second = { queue_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", rules = [{ actions = ["DeleteObject"] }] } } } } }
  expect_failures = [cloudflare_r2_bucket_event_notification.this]
}
run "reject_jurisdictional_catalog" {
  providers = { cloudflare = cloudflare.configured_jurisdiction }
  command   = plan
  variables { buckets = { invalid = { jurisdiction = "eu", create_data_catalog = true } } }
  expect_failures = [cloudflare_r2_data_catalog.this]
}
