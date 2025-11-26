variable "gcp_org_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "gcp_billing_account_id" {
  description = "GCP Billing Account ID (required if create_billing_project is true)."
  type        = string
  default     = null
}

variable "create_billing_project" {
  description = "Whether to create a new project for billing data. If false, bigquery_project_id must be provided. If true and bigquery_project_id is not provided, a new project ID will be generated."
  type        = bool
  default     = false
}

variable "create_billing_dataset" {
  description = "Whether to create a BigQuery dataset for billing data."
  type        = bool
  default     = false
}

variable "gcp_billing_data_dataset_id" {
  description = "Dataset identifier where the billing data will be stored."
  type        = string
  default     = "all_billing_data"
}

variable "gcp_billing_data_dataset_description" {
  description = "Dataset description for the billing data."
  type        = string
  default     = "All billing data (required by Topogy)"
}

variable "billing_project_name" {
  description = "Name for the new billing project (only used if create_billing_project is true)."
  type        = string
  default     = "Billing BigQuery"
}

variable "billing_dataset_location" {
  description = "Location for the BigQuery billing dataset (e.g., US, EU)."
  type        = string
  default     = "US"
}

variable "topogy_service_account_email" {
  description = "The email of the Topogy service account (provided by Topogy, e.g. topogy-fintu-3bekh7jf5mrav324@devel-client-sa-57df.iam.gserviceaccount.com)"
  type        = string
}

variable "bigquery_jobs_role_id" {
  description = "The ID (name) of the custom BigQuery jobs role. This will be used to create and reference the role."
  type        = string
  default     = "TopogyBigQueryJobsRole"
}

variable "create_bigquery_jobs_role" {
  description = "Whether to create the BigQuery jobs custom role. Set to false if the role is already created by another module instance."
  type        = bool
  default     = true
}

variable "bigquery_project_id" {
  description = "The GCP Project ID where BigQuery operations occur (jobs role creation, billing dataset if created). Required if create_billing_project=false (to grant access to existing dataset). If create_billing_project=true and not provided, a new project ID will be generated."
  type        = string
  default     = null
}

variable "readonly_role_id" {
  description = "The ID (name) of the custom read-only role. This will be used to create and reference the role at the organization level."
  type        = string
  default     = "TopogyReadOnlyRole"
}

variable "create_readonly_role" {
  description = "Whether to create the read-only custom role. Set to false if the role is already created by another module instance."
  type        = bool
  default     = true
}

variable "project_ids" {
  description = "Optional list of project IDs where APIs should be enabled. If not provided, will attempt to auto-detect all accessible projects. Use this if the auto-detection isn't working."
  type        = list(string)
  default     = null
}

variable "enable_api_management" {
  description = "Whether to enable and manage API endpoints. Set to false to disable API management."
  type        = bool
  default     = true
}

variable "bigquery_jobs_role_permissions" {
  description = "List of permissions for the BigQuery jobs custom role."
  type        = list(string)
  default = [
    "bigquery.jobs.create",
    "bigquery.jobs.get",
    "bigquery.jobs.list",
  ]
}

variable "readonly_role_permissions" {
  description = "List of permissions for the read-only custom role."
  type        = list(string)
  default = [
    "cloudasset.assets.exportCloudresourcemanagerFolders",
    "cloudasset.assets.exportCloudresourcemanagerOrganizations",
    "cloudasset.assets.exportCloudresourcemanagerProjects",
    "cloudasset.assets.exportResource",
    "cloudasset.assets.listCloudresourcemanagerFolders",
    "cloudasset.assets.listCloudresourcemanagerOrganizations",
    "cloudasset.assets.listCloudresourcemanagerProjects",
    "cloudasset.assets.listResource",
    "cloudasset.assets.searchAllResources",
    "compute.commitments.get",
    "compute.commitments.list",
    "compute.regions.list",
    "monitoring.metricDescriptors.list",
    "monitoring.timeSeries.list",
    "resourcemanager.folders.get",
    "resourcemanager.folders.list",
    "resourcemanager.organizations.get",
    "resourcemanager.projects.get",
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.list",
  ]
}

variable "enable_billing_dataset_permissions" {
  description = "Whether to grant BigQuery Data Viewer permissions to the Topogy service account for the billing dataset. Set to false if the dataset doesn't exist or you don't have permission to grant access."
  type        = bool
  default     = true
}
