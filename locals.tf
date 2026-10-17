locals {
  buckets = {
    for key, bucket in var.buckets : key => merge(bucket, {
      for field, fallback in var.defaults : field => bucket[field] != null ? bucket[field] : fallback
    }) if var.create && bucket != null
  }
  names = { for key, bucket in local.buckets : key => bucket.name != null ? bucket.name : "${var.name_prefix}${key}" }
  account_ids = {
    for key, bucket in local.buckets : key => bucket.account_id != null ? bucket.account_id : var.account_id
  }
  custom_domains = merge({}, [for bucket_key, bucket in local.buckets : {
    for key, domain in bucket.custom_domains : jsonencode([bucket_key, key]) => merge(domain, {
      bucket_key = bucket_key
      domain     = domain.domain != null ? domain.domain : key
    })
  }]...)
  event_notifications = merge({}, [for bucket_key, bucket in local.buckets : {
    for key, notification in bucket.event_notifications : jsonencode([bucket_key, key]) => merge(notification, {
      bucket_key = bucket_key
    })
  }]...)
}
