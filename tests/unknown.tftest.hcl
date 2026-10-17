mock_provider "cloudflare" {
  mock_resource "cloudflare_r2_bucket" {
    # The fixture leaves jurisdiction computed; downstream resources validate it.
    defaults = { jurisdiction = "default" }
  }
}
run "computed_values_preserve_addresses" {
  command = plan
  module { source = "./tests/fixtures/unknown" }
  assert {
    condition     = output.bucket_keys == ["assets"] && output.domain_keys == ["public"] && output.notification_keys == ["images"] && output.cors_keys == ["assets"] && output.managed_domain_keys == ["assets"] && output.lifecycle_keys == ["assets"] && output.lock_keys == ["assets"] && output.catalog_keys == ["assets"]
    error_message = "Computed names, account/zone/queue IDs and setting values must not control resource addresses."
  }
}
