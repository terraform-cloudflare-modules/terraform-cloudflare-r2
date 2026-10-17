# Private buckets

Creates two private buckets, with a shared storage class and r2.dev access explicitly disabled.
The `documents` name uses the prefix; `backups` supplies an exact name. Adjust names to avoid
collisions in your account and provide `account_id` before applying. Objects are managed outside
Terraform and must be removed before destroying buckets.

See the [full example](../full) for lifecycle, retention, domains, queues, and catalog settings.
