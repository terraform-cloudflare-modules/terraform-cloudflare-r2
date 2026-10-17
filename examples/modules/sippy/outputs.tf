output "enabled" {
  description = "Provider-reported Sippy status."
  value       = module.migration.enabled
}
output "sippy" {
  description = "Complete migration configuration, including sensitive credentials."
  value       = module.migration.sippy
  sensitive   = true
}
