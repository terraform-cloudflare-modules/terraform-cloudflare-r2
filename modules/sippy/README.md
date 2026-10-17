# Cloudflare R2 Sippy Terraform module

Manage incremental migration into one existing R2 bucket. Keeping Sippy separate allows
migration credentials and ownership to end independently of the destination bucket.

## Usage

```hcl
variable "account_id" {
  description = "Cloudflare account owning the destination bucket."
  type        = string
}
variable "migration_credentials" {
  description = "Existing source read and destination R2 write credentials."
  type = object({
    source_id          = string
    source_secret      = string
    destination_id     = string
    destination_secret = string
  })
  sensitive = true
}

module "migration" {
  source = "terraform-cloudflare-modules/r2/cloudflare//modules/sippy"

  account_id  = var.account_id
  bucket_name = "archive-migration"
  source_storage = {
    cloud_provider    = "aws"
    bucket            = "legacy-archive"
    region            = "eu-west-1"
    access_key_id     = var.migration_credentials.source_id
    secret_access_key = var.migration_credentials.source_secret
  }
  destination = {
    cloud_provider    = "r2"
    access_key_id     = var.migration_credentials.destination_id
    secret_access_key = var.migration_credentials.destination_secret
  }
}
```

The destination bucket must already exist. Use a local source path until the module is published.

## Examples

The [full migration example](../../examples/modules/sippy) demonstrates every input and all
source alternatives, including Azure's mutually exclusive account key and SAS token.

## Configuration

`source_storage` maps to the provider's `source` attribute; Terraform reserves `source` for
module addressing. The source and destination objects retain every configurable provider
field and are sensitive. They are still recorded in Terraform state. Configure a protected
state backend and use narrowly scoped source-read and destination-write credentials.

Source alternatives are `aws`, `gcs`, `s3`, and `azure` in the checked schema. Supply credentials
for the selected source only. Azure uses either `account_key` or `sas_token`, never both.
The destination's `cloud_provider` is `r2`. Jurisdiction must match the destination bucket.
Refer to [Sippy](https://developers.cloudflare.com/r2/data-migration/sippy/) for source support,
credential prerequisites and operational limits; provider fields alone do not establish
account entitlement or live API support.

Pass the root module's `names["archive"]` as `bucket_name` when it creates the bucket.
`create` alone controls the resource count, so bucket names and sensitive credentials may
be unknown during planning. `create = false` removes the resource and disables Sippy;
it does not delete the destination or reverse copies. Use only one Sippy owner per bucket.
The `sippy` output is the complete sensitive object; `enabled` is the provider-reported state.

See [provider field coverage](docs/SCHEMA.md) and the root [coverage boundaries](../../docs/COVERAGE.md).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.8 |
| cloudflare | >= 5.28.0, < 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| cloudflare | >= 5.28.0, < 6.0.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_r2_bucket_sippy.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_bucket_sippy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| account\_id | Cloudflare account that owns the destination bucket. | `string` | `null` | no |
| bucket\_name | Existing destination R2 bucket name, for example from the root module's names output. | `string` | `null` | no |
| create | Whether to manage Sippy for this bucket. Setting false removes the resource and disables migration. | `bool` | `true` | no |
| destination | R2 write credentials used by Sippy. Use credentials scoped to the destination bucket. Credentials remain in state. | ```object({ cloud_provider = optional(string) access_key_id = optional(string) secret_access_key = optional(string) })``` | `null` | no |
| jurisdiction | Destination bucket jurisdiction. Must match the bucket; null delegates to the provider. | `string` | `null` | no |
| source\_storage | Source storage configuration. Terraform reserves source for module addressing, so this maps to the provider's source field. Credentials remain in state. | ```object({ cloud_provider = optional(string) access_key_id = optional(string) secret_access_key = optional(string) bucket = optional(string) region = optional(string) bucket_url = optional(string) client_email = optional(string) private_key = optional(string) account_name = optional(string) container = optional(string) account_key = optional(string) sas_token = optional(string) })``` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| enabled | Provider-reported migration state, or null when unmanaged. |
| sippy | Complete Sippy configuration, or null when disabled. Includes sensitive source and destination credentials. |
<!-- END_TF_DOCS -->

## Contributing

See [CONTRIBUTING.md](../../docs/CONTRIBUTING.md) and [UPGRADING.md](../../docs/UPGRADING.md).

## Authors

Maintained by [Terraform Cloudflare Modules](https://github.com/terraform-cloudflare-modules).
See [AUTHORS](../../.github/AUTHORS) and [CODEOWNERS](../../.github/CODEOWNERS).

## License

MIT. See [LICENSE](../../LICENSE).
