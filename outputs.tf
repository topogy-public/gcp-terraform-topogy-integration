output "billing_project_id" {
  description = "The ID of the project where the billing dataset is located (or would be located if created)."
  value       = local.billing_project_id
}

output "billing_dataset_id" {
  description = "The ID of the BigQuery billing dataset."
  value       = local.billing_dataset_id
}
