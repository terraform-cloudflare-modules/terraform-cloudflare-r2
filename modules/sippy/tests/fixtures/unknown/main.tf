resource "terraform_data" "upstream" {
  input = { account_id = "0123456789abcdef0123456789abcdef", bucket_name = "computed-bucket", secret = "example-secret" }
}
module "sippy" {
  source         = "../../.."
  account_id     = terraform_data.upstream.output.account_id
  bucket_name    = terraform_data.upstream.output.bucket_name
  source_storage = { cloud_provider = "aws", bucket = "legacy", region = "eu-west-1", access_key_id = "example-source-id", secret_access_key = terraform_data.upstream.output.secret }
  destination    = { cloud_provider = "r2", access_key_id = "example-destination-id", secret_access_key = terraform_data.upstream.output.secret }
}
output "configured" {
  description = "Whether the resource is present despite computed credentials."
  value       = module.sippy.sippy != null
  sensitive   = true
}
