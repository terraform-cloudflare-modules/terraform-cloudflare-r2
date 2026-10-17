variable "create" {
  description = "Whether to manage the configured buckets and settings. Setting false plans removal of existing resources."
  type        = bool
  default     = true
  nullable    = false
}

variable "account_id" {
  description = "Default Cloudflare account ID. May be overridden in defaults or individual buckets."
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Literal prefix for bucket names derived from map keys. An explicit name overrides it; no random suffix is added."
  type        = string
  default     = ""
  nullable    = false
}

variable "defaults" {
  description = "Shared bucket settings. Non-null bucket fields override these; nested objects, maps and lists replace as a whole. Rule lists default to null (unmanaged); [] explicitly manages an empty configuration."
  type = object({

    account_id    = optional(string)
    jurisdiction  = optional(string)
    location      = optional(string)
    storage_class = optional(string)
    cors_rules = optional(list(object({
      id              = optional(string)
      allowed_methods = list(string)
      allowed_origins = list(string)
      allowed_headers = optional(list(string))
      expose_headers  = optional(list(string))
      max_age_seconds = optional(number)
    })))
    lifecycle_rules = optional(list(object({
      id         = string
      enabled    = optional(bool, true)
      conditions = optional(object({ prefix = optional(string, "") }), {})
      abort_multipart_uploads_transition = optional(object({
        condition = optional(object({ type = string, max_age = number }))
      }))
      delete_objects_transition = optional(object({
        condition = optional(object({ type = string, max_age = optional(number), date = optional(string) }))
      }))
      storage_class_transitions = optional(list(object({
        condition     = object({ type = string, max_age = optional(number), date = optional(string) })
        storage_class = string
      })))
    })))
    lock_rules = optional(list(object({
      id        = string
      enabled   = optional(bool, true)
      prefix    = optional(string)
      condition = object({ type = string, max_age_seconds = optional(number), date = optional(string) })
    })))
    managed_domain = optional(object({ enabled = bool }))
    custom_domains = optional(map(object({
      domain  = optional(string)
      zone_id = string
      enabled = optional(bool, true)
      min_tls = optional(string)
      ciphers = optional(list(string))
    })), {})
    event_notifications = optional(map(object({
      queue_id = string
      rules = list(object({
        actions     = list(string)
        description = optional(string)
        prefix      = optional(string)
        suffix      = optional(string)
      }))
    })), {})
    create_data_catalog = optional(bool, false)
  })
  default  = {}
  nullable = false
}

variable "buckets" {
  description = "Buckets keyed by stable identifiers. Names default to name_prefix plus the key. Optional configuration presence, map keys and create_data_catalog must be known at plan time; IDs and names may be computed."
  type = map(object({
    name = optional(string)

    account_id    = optional(string)
    jurisdiction  = optional(string)
    location      = optional(string)
    storage_class = optional(string)
    cors_rules = optional(list(object({
      id              = optional(string)
      allowed_methods = list(string)
      allowed_origins = list(string)
      allowed_headers = optional(list(string))
      expose_headers  = optional(list(string))
      max_age_seconds = optional(number)
    })))
    lifecycle_rules = optional(list(object({
      id         = string
      enabled    = optional(bool, true)
      conditions = optional(object({ prefix = optional(string, "") }), {})
      abort_multipart_uploads_transition = optional(object({
        condition = optional(object({ type = string, max_age = number }))
      }))
      delete_objects_transition = optional(object({
        condition = optional(object({ type = string, max_age = optional(number), date = optional(string) }))
      }))
      storage_class_transitions = optional(list(object({
        condition     = object({ type = string, max_age = optional(number), date = optional(string) })
        storage_class = string
      })))
    })))
    lock_rules = optional(list(object({
      id        = string
      enabled   = optional(bool, true)
      prefix    = optional(string)
      condition = object({ type = string, max_age_seconds = optional(number), date = optional(string) })
    })))
    managed_domain = optional(object({ enabled = bool }))
    custom_domains = optional(map(object({
      domain  = optional(string)
      zone_id = string
      enabled = optional(bool, true)
      min_tls = optional(string)
      ciphers = optional(list(string))
    })))
    event_notifications = optional(map(object({
      queue_id = string
      rules = list(object({
        actions     = list(string)
        description = optional(string)
        prefix      = optional(string)
        suffix      = optional(string)
      }))
    })))
    create_data_catalog = optional(bool)
  }))
  default  = {}
  nullable = false
  validation {
    condition     = alltrue([for bucket in var.buckets : bucket != null])
    error_message = "Bucket entries must be objects, not null."
  }
}
