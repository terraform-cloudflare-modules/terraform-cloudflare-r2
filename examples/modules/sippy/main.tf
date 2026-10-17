locals {
  sources = {
    aws = {
      cloud_provider    = "aws"
      bucket            = var.source_bucket
      region            = var.source_region
      access_key_id     = var.credentials.source_access_key_id
      secret_access_key = var.credentials.source_secret_access_key
    }
    gcs = {
      cloud_provider = "gcs"
      bucket         = var.source_bucket
      client_email   = var.credentials.client_email
      private_key    = var.credentials.private_key
    }
    s3 = {
      cloud_provider    = "s3"
      bucket_url        = var.source_bucket_url
      access_key_id     = var.credentials.source_access_key_id
      secret_access_key = var.credentials.source_secret_access_key
    }
    azure = {
      cloud_provider = "azure"
      account_name   = var.source_account_name
      container      = var.source_container
      account_key    = var.credentials.account_key
      sas_token      = var.credentials.sas_token
    }
  }
}

module "migration" {
  source = "../../../modules/sippy"

  create         = var.create
  account_id     = var.account_id
  bucket_name    = var.bucket_name
  jurisdiction   = var.jurisdiction
  source_storage = local.sources[var.source_provider]
  destination = {
    cloud_provider    = "r2"
    access_key_id     = var.credentials.destination_access_key_id
    secret_access_key = var.credentials.destination_secret_access_key
  }
}
