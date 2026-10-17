# R2 coverage and boundaries

The implementation covers the nine `cloudflare_r2_*` resources present in the supplied
provider schema. The module requires Cloudflare >= 5.28.0 and < 6.0.0, matching the other
Cloudflare modules. The snapshot has no embedded engine/provider provenance, so Formr
reports that limitation explicitly. Current web documentation can differ from this snapshot.

| Provider resource | Module input | Scope |
| --- | --- | --- |
| `cloudflare_r2_bucket` | `buckets`, `defaults`, `account_id`, `name_prefix` | Bucket identity, placement, jurisdiction and storage class |
| `cloudflare_r2_bucket_cors` | `cors_rules` | Complete CORS rules, with Hetzner-compatible flat fields |
| `cloudflare_r2_bucket_lifecycle` | `lifecycle_rules` | Deletion, multipart abort and storage transitions |
| `cloudflare_r2_bucket_lock` | `lock_rules` | Age, Date and Indefinite retention rules |
| `cloudflare_r2_managed_domain` | `managed_domain` | Explicit public development access |
| `cloudflare_r2_custom_domain` | `custom_domains` | Existing-zone domain connections, TLS and ciphers |
| `cloudflare_r2_bucket_event_notification` | `event_notifications` | Event rules routed to existing queues |
| `cloudflare_r2_data_catalog` | `create_data_catalog` | Activation only; credentials and maintenance are computed |
| `cloudflare_r2_bucket_sippy` | `modules/sippy` | Source/destination credentials and migration configuration |

Every configurable attribute of these resources has a caller-controlled source or a relationship
to the configured bucket. Read-only attributes are returned in complete objects. This is provider
resource coverage, not a claim that every R2 service API operation is available through Terraform.
The [root schema report](SCHEMA.md) and [Sippy schema report](../modules/sippy/docs/SCHEMA.md)
provide the field inventory. Formr does not fully trace some nested-map and `one(...)` output
expressions; attributes classified as unused there are nevertheless included in whole-object outputs.

## Separate concerns and provider gaps

- Object upload/download, multipart operations, presigned URLs and object-emptying are data operations;
  use S3 clients or Workers. No object resource or force-destroy field exists in this snapshot.
- S3 ACLs, policy documents, versioning, replication and S3 Object Lock configuration are not equivalent
  R2 controls. Consult [S3 API compatibility](https://developers.cloudflare.com/r2/api/s3/api/).
- Queues and their consumers belong to the Queues product; this module only owns R2 notifications.
- Worker code and R2 bindings belong to `terraform-cloudflare-workers` and consume bucket names here.
- API token issuance, cache rules, WAF and Zero Trust Access belong to their corresponding products.
- Bulk Super Slurper jobs, data access log configuration, local uploads and temporary credential issuance
  have no dedicated managed resource in this snapshot. They are not implemented through shell commands.
- Catalog activation does not manage table definitions, credential provisioning, compaction policies,
  snapshot expiration, query engines or SQL features. The catalog resource's only configurable fields
  are account and bucket name; it has no jurisdiction selector.

## References

- [Cloudflare provider R2 bucket schema](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_bucket)
- [R2 lifecycle schema](https://github.com/cloudflare/terraform-provider-cloudflare/blob/v5.28.0/docs/resources/r2_bucket_lifecycle.md)
- [Bucket locks](https://developers.cloudflare.com/r2/buckets/bucket-locks/)
- [Event notifications](https://developers.cloudflare.com/r2/buckets/event-notifications/)
- [Sippy](https://developers.cloudflare.com/r2/data-migration/sippy/)
