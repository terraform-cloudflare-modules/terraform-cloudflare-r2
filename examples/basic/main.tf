module "storage" {
  source = "../.."

  account_id  = var.account_id
  name_prefix = "example-"
  defaults = {
    storage_class  = "Standard"
    managed_domain = { enabled = false }
  }
  buckets = {
    documents = {}
    backups   = { name = "example-private-backups" }
  }
}
