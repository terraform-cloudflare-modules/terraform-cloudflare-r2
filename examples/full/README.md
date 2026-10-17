# Complete R2 configuration

Demonstrates every root input and nested configuration field. Shared settings live in `defaults`;
`buckets.assets` overrides identity and adds a custom domain and queue notifications. Every shared
setting can also be set per bucket with the same shape. The catalog bucket clears inherited rules.

Provide `account_id`, `zone_id`, `assets_domain`, and `queue_id`. R2 must be enabled, the zone and queue
must already exist in that account, and the hostname must be available. Catalog activation requires
access to that product; remove the catalog bucket if unavailable. Queue consumers and catalog credentials
are managed separately. Change example names, origins, dates and prefixes before applying.

This example enables public access through the supplied custom domain and explicitly disables r2.dev.
Change `managed_domain.enabled` to true only for intentional public development access. To disable a
custom domain while retaining its connection, set its `enabled` to false. To use a hostname as the map
key, omit `domain`; stable descriptive keys with explicit names are shown here.

Age and Date transition conditions are alternatives, so both appear in separate rules. Ages use seconds
and arithmetic expressions; Date conditions use RFC3339 timestamps. Multipart abort only accepts Age.
Lock rules also allow Indefinite, with neither date nor duration. Disabled rules illustrate alternatives
without activating every retention policy. Omit `conditions` to apply a lifecycle rule to the whole bucket.

`location` is a best-effort hint; jurisdiction constrains residency. A regional bucket can use `jurisdiction = "eu"`
with `location = null` when no shared location is configured. Catalog activation cannot select a jurisdiction.
Storage class may be `Standard` or `InfrequentAccess`; review service costs and minimum storage duration.

Null inherits a default; empty lists explicitly clear inherited rules, and empty maps remove inherited
entries. `create = false` plans destruction of everything in the call. Empty buckets before deletion and
review lock policies first. CORS and retention settings do not grant access by themselves.
