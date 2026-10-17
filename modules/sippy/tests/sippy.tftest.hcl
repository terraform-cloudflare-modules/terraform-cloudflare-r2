mock_provider "cloudflare" {
  mock_resource "cloudflare_r2_bucket_sippy" { defaults = { enabled = true } }
}
variables {
  account_id  = "0123456789abcdef0123456789abcdef"
  bucket_name = "migration-target"
}
run "aws_credentials_and_complete_output" {
  command = apply
  variables {
    jurisdiction   = "eu"
    source_storage = { cloud_provider = "aws", bucket = "legacy", region = "eu-west-1", access_key_id = "example-source-id", secret_access_key = "example-source-secret" }
    destination    = { cloud_provider = "r2", access_key_id = "example-destination-id", secret_access_key = "example-destination-secret" }
  }
  assert {
    condition     = output.enabled && output.sippy.jurisdiction == "eu" && output.sippy.source.bucket == "legacy" && output.sippy.destination.cloud_provider == "r2"
    error_message = "Source, destination, jurisdiction, and computed state must be preserved."
  }
}
run "s3_compatible_source" {
  command = plan
  variables { source_storage = { cloud_provider = "s3", bucket_url = "https://legacy.example.com/bucket", access_key_id = "example-source-id", secret_access_key = "example-source-secret" } }
  assert {
    condition     = output.sippy.source.bucket_url == "https://legacy.example.com/bucket"
    error_message = "S3-compatible sources require configurable bucket URLs."
  }
}
run "google_source" {
  command = plan
  variables { source_storage = { cloud_provider = "gcs", bucket = "legacy", client_email = "migration@example.iam.gserviceaccount.com", private_key = "example-private-key" } }
  assert {
    condition     = output.sippy.source.client_email == "migration@example.iam.gserviceaccount.com" && output.sippy.source.private_key == "example-private-key"
    error_message = "GCS source fields must be preserved."
  }
}
run "azure_account_key" {
  command = plan
  variables { source_storage = { cloud_provider = "azure", account_name = "legacy", container = "archive", account_key = "example-account-key" } }
  assert {
    condition     = output.sippy.source.container == "archive" && output.sippy.source.account_key == "example-account-key" && output.sippy.source.sas_token == null
    error_message = "Azure account-key authentication must be configurable."
  }
}
run "azure_sas_token" {
  command = plan
  variables { source_storage = { cloud_provider = "azure", account_name = "legacy", container = "archive", sas_token = "example-sas-token" } }
  assert {
    condition     = output.sippy.source.account_key == null && output.sippy.source.sas_token == "example-sas-token"
    error_message = "Azure SAS authentication must remain separate from account-key authentication."
  }
}
run "disabled_without_credentials" {
  command = plan
  variables {
    create      = false
    account_id  = null
    bucket_name = null
  }
  assert {
    condition     = output.sippy == null && output.enabled == null
    error_message = "A disabled call must create no migration configuration."
  }
}
run "reject_azure_conflicting_credentials" {
  command = plan
  variables { source_storage = { cloud_provider = "azure", account_key = "example-account-key", sas_token = "example-sas-token" } }
  expect_failures = [var.source_storage]
}
run "reject_missing_bucket" {
  command = plan
  variables { bucket_name = null }
  expect_failures = [cloudflare_r2_bucket_sippy.this]
}
