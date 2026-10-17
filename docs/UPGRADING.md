# Adoption and verification

This is a new R2 module API. Prepare its GitHub repository and Registry publication separately;
local implementation does not imply publication. No live infrastructure is used by the test suite.

## Ownership and adoption

Give each bucket, ruleset, domain and bucket/queue notification pair one Terraform owner.
Use the installed provider's resource-specific import support; some R2 settings do not support
import. Do not assume a bucket import adopts CORS, lifecycle, locks, domains, notifications or
catalog settings. Configure the actual settings first and review the resulting plan.

For an equivalent bucket resource already in the caller's state:

```hcl
moved {
  from = cloudflare_r2_bucket.assets
  to   = module.storage.cloudflare_r2_bucket.this["assets"]
}
```

Nested domain and notification addresses use JSON-encoded pairs. For example, a domain key
`public` in bucket `assets` is stored under `["assets","public"]`, including the brackets and
quotes in the key. Use the exact address shown by the plan when moving/importing resources.

Removing optional settings or setting creation flags false plans resource destruction, not a
state-only transfer. Empty a bucket before deleting it. Review retention rules and catalog data
before destructive changes. Removing Sippy disables migration without deleting copied objects.

## Local checks

Run `pre-commit run --all-files`, then `terraform init -backend=false`, `terraform validate`,
and `terraform test` in both the root and `modules/sippy`. Repeat with OpenTofu. CI additionally
initializes and validates every tracked example and test fixture and runs TFLint.
Mock tests require no cloud credentials, but provider executables need working local plugin sockets.

Generate and check the provider coverage reports:

```sh
formr schema . -o docs/SCHEMA.md
formr check . --report docs/SCHEMA.md
formr schema modules/sippy -o modules/sippy/docs/SCHEMA.md
formr check modules/sippy --report modules/sippy/docs/SCHEMA.md
```

To use the supplied local snapshot, append `--schema-file secrets/schema.json`. It has no embedded
provenance, which is recorded as a warning rather than inventing a release attribution.
Keep schemas and credentials in gitignored `secrets/`.

## Acceptance before release

In a dedicated account, separately verify bucket creation and a second no-change plan, jurisdiction
routing, rule updates and clearing with empty lists, both public access paths, event delivery to
queues, Sippy enable/update/disable, and catalog activation/deactivation. Verify rule removal and
resource destruction semantics with the installed provider before adopting existing configuration.
Mock tests cannot establish API entitlements, credential validity, event delivery or deletion behavior.
