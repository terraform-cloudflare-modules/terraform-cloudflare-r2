# Cloudflare R2 Terraform module

Manage R2 buckets, browser access, object lifecycle and retention rules, public domains,
queue notifications, and data catalog activation. A separate [Sippy submodule](modules/sippy)
manages migration from existing object storage. Shared defaults and stable bucket keys follow
[the Hetzner object storage module](https://github.com/terraform-hetzner-modules/terraform-hetzner-object-storage).

## Usage

```hcl
variable "cloudflare_account_id" {
  description = "Cloudflare account with R2 enabled."
  type        = string
}

module "storage" {
  source = "terraform-cloudflare-modules/r2/cloudflare"

  account_id  = var.cloudflare_account_id
  name_prefix = "project-"
  defaults = {
    storage_class  = "Standard"
    managed_domain = { enabled = false }
  }
  buckets = {
    uploads = {
      cors_rules = [{
        allowed_methods = ["GET", "PUT"]
        allowed_origins = ["https://app.example.com"]
        allowed_headers = ["Content-Type"]
      }]
    }
    archive = { storage_class = "InfrequentAccess" }
  }
}
```

The Registry address is the intended publication address; use a local path before the first release.

## Examples

- [Basic](examples/basic): private buckets with shared defaults and explicit names.
- [Full](examples/full): every root setting, rule alternatives, domains, queues, and a catalog.
- [Sippy](examples/modules/sippy): AWS, GCS, S3-compatible, and Azure source alternatives.

## Configuration

`buckets` is a map of stable caller keys. Each name defaults to `name_prefix` plus its key;
`name` supplies an exact name. R2 accepts 3–63 lowercase letters, digits, and hyphens,
starting and ending with a letter or digit. Names must be unique within the account and
jurisdiction. Account selection is bucket → defaults → top-level `account_id`.

Non-null bucket fields replace the corresponding `defaults` field. Lists, maps and nested
objects replace as a whole; there is no deep merge. False, empty lists and empty maps are
explicit overrides. Null inherits the shared value, so clear an inherited list with `[]`.
To leave an inherited setting unmanaged for one bucket, move that default to the other buckets.

| Setting | Omitted, with no shared default | Explicit empty or false |
| --- | --- | --- |
| `cors_rules`, `lifecycle_rules`, `lock_rules` | Unmanaged | `[]` owns an empty ruleset and clears existing rules. |
| `managed_domain` | Unmanaged | `{ enabled = false }` explicitly disables r2.dev access. |
| `custom_domains`, `event_notifications` | No managed entries | `{}` removes inherited entries from the managed map. |
| `create_data_catalog` | No catalog | `false` removes an owned catalog resource. |

Setting `create = false` or removing a bucket plans destruction. Removing an optional
configuration also destroys its resource; it does not transfer ownership without an API change.
Only one Terraform resource should own each bucket-wide ruleset, public development domain,
custom hostname, or bucket/queue notification pair. Use one notification entry per queue and
place all its rules in that entry. A queue may serve several buckets.

Bucket keys, optional setting presence, nested map keys, and catalog creation flags must be
known at plan time. Names, account IDs, zone IDs, queue IDs, and nested setting values may be
computed. Domains and notifications use JSON-encoded `[bucket_key, entry_key]` addresses to
avoid delimiter collisions; their outputs are nested maps using the original keys.

### Familiar inputs and R2 differences

`create`, `name_prefix`, `defaults`, `buckets`, explicit `name`, and the flattened CORS fields
match the Hetzner module. `buckets`, `ids`, and `names` outputs keep the same role.
The [R2 S3 compatibility matrix](https://developers.cloudflare.com/r2/api/s3/api/) explains
why S3 ACLs, bucket policies, versioning and S3 Object Lock are not interchangeable with R2 settings.
This module has no synthetic `acl`, `policy`, `versioning`, `bucket_prefix`, or `force_destroy` input.
R2 uses public domains and native bucket lock rules. The provider has no object-emptying option.

`lifecycle_rules` uses R2's native transition objects, with `enabled` defaulting to true and
`conditions.prefix` defaulting to the empty string. Ages are **seconds**, so use expressions
such as `30 * 24 * 60 * 60`. Age conditions use `type = "Age"` and `max_age`; Date conditions
use `type = "Date"` and an RFC3339 `date`. Multipart abort only supports Age conditions.
Use either age or date, never both. Storage transitions support `InfrequentAccess`.
See [object lifecycles](https://developers.cloudflare.com/r2/buckets/object-lifecycles/).

`lock_rules` supports Age (`max_age_seconds`), Date (`date`), and Indefinite conditions.
Lock rules take precedence over lifecycle deletion and can prevent emptying a bucket.
[R2 bucket locks](https://developers.cloudflare.com/r2/buckets/bucket-locks/) differ from
S3 governance/compliance modes and do not require enabling versioning at creation.

`location` is a best-effort placement hint; `jurisdiction` is the residency selector and is
forwarded to all settings that support it. Follow [data location](https://developers.cloudflare.com/r2/reference/data-location/)
for compatible values. The catalog resource has no jurisdiction input; this module restricts
catalog activation to the default jurisdiction. Catalog credentials and maintenance fields are
computed-only in the checked provider schema; activation does not configure those features.

### Access and relationships

Custom domains require an existing Cloudflare zone in the bucket's account. R2 owns the
associated domain connection; do not manage its generated DNS record separately.
Custom domains and r2.dev access are independent. Disable r2.dev explicitly when access should
only pass through a custom domain. [Public bucket guidance](https://developers.cloudflare.com/r2/buckets/public-buckets/)
describes the access paths and the development endpoint's limits.

Notifications target existing Cloudflare Queues via `queue_id`; queue creation and consumers
belong to their own modules. CORS permits browser requests but does not grant object access.
Workers can bind to `module.storage.names["uploads"]` using the Workers module's `r2_bucket`
binding. Object transfer, tokens, cache rules and Zero Trust policies remain separate concerns.
See [coverage and boundaries](docs/COVERAGE.md) and [provider field coverage](docs/SCHEMA.md).

The module exports complete provider objects, including computed domain, notification and
catalog attributes. No S3 ARN or single bucket URL is invented: an R2 bucket can have several
public domains or none. Public hostnames are available through `managed_domains` and
`custom_domains`; bucket outputs wait for all managed settings.

### Deletion and migration

Empty buckets before deletion; the module does not delete their objects. Review lock rules,
clients, queue consumers, and catalog contents before removing resources. Sippy has its own
lifecycle and sensitive inputs in `modules/sippy`; disabling Sippy does not undo copied data.
Changing a stable map key needs a state move to avoid replacement.

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
| [cloudflare_r2_bucket.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_bucket) | resource |
| [cloudflare_r2_bucket_cors.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_bucket_cors) | resource |
| [cloudflare_r2_bucket_event_notification.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_bucket_event_notification) | resource |
| [cloudflare_r2_bucket_lifecycle.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_bucket_lifecycle) | resource |
| [cloudflare_r2_bucket_lock.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_bucket_lock) | resource |
| [cloudflare_r2_custom_domain.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_custom_domain) | resource |
| [cloudflare_r2_data_catalog.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_data_catalog) | resource |
| [cloudflare_r2_managed_domain.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_managed_domain) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| account\_id | Default Cloudflare account ID. May be overridden in defaults or individual buckets. | `string` | `null` | no |
| buckets | Buckets keyed by stable identifiers. Names default to name\_prefix plus the key. Optional configuration presence, map keys and create\_data\_catalog must be known at plan time; IDs and names may be computed. | ```map(object({ name = optional(string) account_id = optional(string) jurisdiction = optional(string) location = optional(string) storage_class = optional(string) cors_rules = optional(list(object({ id = optional(string) allowed_methods = list(string) allowed_origins = list(string) allowed_headers = optional(list(string)) expose_headers = optional(list(string)) max_age_seconds = optional(number) }))) lifecycle_rules = optional(list(object({ id = string enabled = optional(bool, true) conditions = optional(object({ prefix = optional(string, "") }), {}) abort_multipart_uploads_transition = optional(object({ condition = optional(object({ type = string, max_age = number })) })) delete_objects_transition = optional(object({ condition = optional(object({ type = string, max_age = optional(number), date = optional(string) })) })) storage_class_transitions = optional(list(object({ condition = object({ type = string, max_age = optional(number), date = optional(string) }) storage_class = string }))) }))) lock_rules = optional(list(object({ id = string enabled = optional(bool, true) prefix = optional(string) condition = object({ type = string, max_age_seconds = optional(number), date = optional(string) }) }))) managed_domain = optional(object({ enabled = bool })) custom_domains = optional(map(object({ domain = optional(string) zone_id = string enabled = optional(bool, true) min_tls = optional(string) ciphers = optional(list(string)) }))) event_notifications = optional(map(object({ queue_id = string rules = list(object({ actions = list(string) description = optional(string) prefix = optional(string) suffix = optional(string) })) }))) create_data_catalog = optional(bool) }))``` | `{}` | no |
| create | Whether to manage the configured buckets and settings. Setting false plans removal of existing resources. | `bool` | `true` | no |
| defaults | Shared bucket settings. Non-null bucket fields override these; nested objects, maps and lists replace as a whole. Rule lists default to null (unmanaged); [] explicitly manages an empty configuration. | ```object({ account_id = optional(string) jurisdiction = optional(string) location = optional(string) storage_class = optional(string) cors_rules = optional(list(object({ id = optional(string) allowed_methods = list(string) allowed_origins = list(string) allowed_headers = optional(list(string)) expose_headers = optional(list(string)) max_age_seconds = optional(number) }))) lifecycle_rules = optional(list(object({ id = string enabled = optional(bool, true) conditions = optional(object({ prefix = optional(string, "") }), {}) abort_multipart_uploads_transition = optional(object({ condition = optional(object({ type = string, max_age = number })) })) delete_objects_transition = optional(object({ condition = optional(object({ type = string, max_age = optional(number), date = optional(string) })) })) storage_class_transitions = optional(list(object({ condition = object({ type = string, max_age = optional(number), date = optional(string) }) storage_class = string }))) }))) lock_rules = optional(list(object({ id = string enabled = optional(bool, true) prefix = optional(string) condition = object({ type = string, max_age_seconds = optional(number), date = optional(string) }) }))) managed_domain = optional(object({ enabled = bool })) custom_domains = optional(map(object({ domain = optional(string) zone_id = string enabled = optional(bool, true) min_tls = optional(string) ciphers = optional(list(string)) })), {}) event_notifications = optional(map(object({ queue_id = string rules = list(object({ actions = list(string) description = optional(string) prefix = optional(string) suffix = optional(string) })) })), {}) create_data_catalog = optional(bool, false) })``` | `{}` | no |
| name\_prefix | Literal prefix for bucket names derived from map keys. An explicit name overrides it; no random suffix is added. | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| buckets | Complete bucket objects indexed by stable caller keys, after all managed settings are applied. |
| cors | Complete CORS configurations indexed by bucket key. |
| custom\_domains | Complete domain objects indexed first by bucket key, then by caller domain key. |
| data\_catalogs | Complete data catalog objects indexed by bucket key, including computed maintenance settings. |
| event\_notifications | Complete notification objects indexed first by bucket key, then by caller notification key. |
| ids | Provider bucket IDs indexed by stable caller keys. |
| lifecycle | Complete lifecycle configurations indexed by bucket key. |
| locks | Complete lock configurations indexed by bucket key. |
| managed\_domains | Complete r2.dev domain objects indexed by bucket key. |
| names | Bucket names for S3 clients and Workers bindings, indexed by stable caller keys. |
<!-- END_TF_DOCS -->

## Contributing

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) and [UPGRADING.md](docs/UPGRADING.md).

## Authors

Maintained by [Terraform Cloudflare Modules](https://github.com/terraform-cloudflare-modules).
See [AUTHORS](.github/AUTHORS) and [CODEOWNERS](.github/CODEOWNERS).

## License

MIT. See [LICENSE](LICENSE).
