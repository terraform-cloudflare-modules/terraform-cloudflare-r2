mock_provider "cloudflare" {}
run "unknown_credentials_do_not_control_count" {
  command = plan
  module { source = "./tests/fixtures/unknown" }
  assert {
    condition     = output.configured
    error_message = "Unknown destination names and credentials must not prevent planning Sippy."
  }
}
