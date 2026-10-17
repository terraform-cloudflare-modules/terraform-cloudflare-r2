# Sippy source alternatives

Uses one existing destination bucket and selects one of four source objects. Every Sippy input and
nested field is demonstrated without configuring incompatible source types together.

Supply `account_id`, `bucket_name`, `credentials` and the fields for your chosen `source_provider`.
Destination credentials require R2 write access to that bucket. Source credentials need read access
to the source objects. Match `jurisdiction` to the destination bucket.

| Source | Configuration | Credentials |
| --- | --- | --- |
| `aws` | `source_bucket`, `source_region` | `source_access_key_id`, `source_secret_access_key` |
| `gcs` | `source_bucket` | `client_email`, `private_key` |
| `s3` | `source_bucket_url` | `source_access_key_id`, `source_secret_access_key` |
| `azure` | `source_account_name`, `source_container` | Either `account_key` or `sas_token` |

All choices require `destination_access_key_id` and `destination_secret_access_key`. Leave unrelated
credential fields unset. The Azure source fields are exposed by the checked provider schema; confirm
service availability for your account. Review [Sippy requirements](https://developers.cloudflare.com/r2/data-migration/sippy/)
for the source before enabling migration. Sensitive values remain in state; use protected storage.

`create = false` removes the migration configuration. It does not delete copied objects or the bucket.
When composing with the root module, pass its `names["archive"]` output to `bucket_name`.
