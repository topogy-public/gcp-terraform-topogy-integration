// Get all active projects accessible to the current user/service account
// Note: This gets all projects the Terraform runner has access to, not just org projects
// The google_projects data source doesn't reliably filter by organization when projects are in folders
data "google_projects" "all_projects" {
  count  = var.project_ids == null ? 1 : 0
  filter = "lifecycleState:ACTIVE"
}

// Random ID for billing project suffix (only used if creating a new project)
resource "random_id" "billing_project_suffix" {
  count       = var.create_billing_project ? 1 : 0
  byte_length = 4
  prefix      = ""
}

// Local values
locals {
  // Required APIs to enable
  required_apis = [
    "cloudasset.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "monitoring.googleapis.com",
    "recommender.googleapis.com",
  ]
  // Billing-related APIs
  billing_apis = [
    "bigquery.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "cloudbilling.googleapis.com",
  ]
  // Determine the BigQuery project ID where the role should be created
  // If creating a new project, use bigquery_project_id if provided, otherwise generate one
  // If not creating, use bigquery_project_id (must be provided)
  bigquery_project_id = var.create_billing_project ? (
    var.bigquery_project_id != null ? var.bigquery_project_id : "topogy-billing-${random_id.billing_project_suffix[0].hex}"
  ) : var.bigquery_project_id
  // Determine billing project ID (same as bigquery_project_id)
  billing_project_id = local.bigquery_project_id
  // Determine billing dataset ID
  billing_dataset_id = var.gcp_billing_data_dataset_id
  // Use provided project IDs or auto-detect from data source
  // If project_ids is provided, create project objects from the list
  // Otherwise, use the data source results
  org_projects = var.project_ids != null ? [
    for project_id in var.project_ids : {
      project_id = project_id
      name       = "projects/${project_id}"
      number     = null
    }
  ] : (length(data.google_projects.all_projects) > 0 ? data.google_projects.all_projects[0].projects : [])
  // Create a map of all project-service combinations
  project_service_combinations = {
    for combo in flatten([
      for project in local.org_projects : [
        for api in local.required_apis : {
          key        = "${project.project_id}:${api}"
          project_id = project.project_id
          service    = api
        }
      ]
    ]) : combo.key => combo
  }
  // Construct the role name (format is always projects/{project}/roles/{role_id})
  bigquery_jobs_role_name = "projects/${local.bigquery_project_id}/roles/${var.bigquery_jobs_role_id}"
  // Construct the organization-level role name (format is organizations/{org_id}/roles/{role_id})
  readonly_role_name = "organizations/${var.gcp_org_id}/roles/${var.readonly_role_id}"
}

// Create billing project (if create_billing_project is true)
// Note: project_id will use bigquery_project_id if provided, otherwise generate one
resource "google_project" "billing_data_project" {
  count = var.create_billing_project ? 1 : 0

  name            = var.billing_project_name
  project_id      = local.billing_project_id
  org_id          = var.gcp_org_id
  billing_account = var.gcp_billing_account_id
}

// Enable billing-related APIs in billing project
// These APIs are needed for billing export to work, whether creating or using existing dataset
resource "google_project_service" "billing_apis" {
  for_each = local.billing_project_id != null ? toset(local.billing_apis) : toset([])

  project = local.billing_project_id
  service = each.value

  disable_on_destroy = false

  depends_on = [google_project.billing_data_project]
}

// Create BigQuery dataset for billing data
resource "google_bigquery_dataset" "billing_dataset" {
  count = var.create_billing_dataset ? 1 : 0

  project       = local.billing_project_id
  dataset_id    = local.billing_dataset_id
  friendly_name = local.billing_dataset_id
  description   = var.gcp_billing_data_dataset_description
  location      = var.billing_dataset_location

  depends_on = [google_project_service.billing_apis]
}

// Enable required APIs for service account functionality in all projects
resource "google_project_service" "required_apis" {
  for_each = local.project_service_combinations

  project = each.value.project_id
  service = each.value.service

  disable_on_destroy = false
}

// Create custom role for BigQuery jobs (only if create_bigquery_jobs_role is true)
resource "google_project_iam_custom_role" "bigquery_jobs_role" {
  count = var.create_bigquery_jobs_role ? 1 : 0

  project     = local.bigquery_project_id
  role_id     = var.bigquery_jobs_role_id
  title       = "Topogy BigQuery Jobs Role"
  description = "Custom role for BigQuery job operations (create, get, list)"
  permissions = var.bigquery_jobs_role_permissions

  depends_on = [google_project_service.required_apis]
}

// Grant BigQuery jobs role to service account
resource "google_project_iam_member" "bigquery_jobs_role" {
  project = local.bigquery_project_id
  role    = local.bigquery_jobs_role_name
  member  = "serviceAccount:${var.topogy_service_account_email}"

  depends_on = [
    google_project_iam_custom_role.bigquery_jobs_role,
    google_project_service.required_apis
  ]
}

// Create custom role for read-only access at organization level
resource "google_organization_iam_custom_role" "readonly_role" {
  count = var.create_readonly_role ? 1 : 0

  org_id      = var.gcp_org_id
  role_id     = var.readonly_role_id
  title       = "Topogy Read Only Role"
  description = "Custom role to grant Topogy read only access to the organization"
  permissions = var.readonly_role_permissions

  depends_on = [google_project_service.required_apis]
}

// Grant read-only role to service account at organization level
resource "google_organization_iam_member" "readonly_role" {
  org_id = var.gcp_org_id
  role   = local.readonly_role_name
  member = "serviceAccount:${var.topogy_service_account_email}"

  depends_on = [google_project_service.required_apis]
}

// Grant Recommender Viewer role to service account at organization level
resource "google_organization_iam_member" "recommender_viewer" {
  org_id = var.gcp_org_id
  role   = "roles/recommender.viewer"
  member = "serviceAccount:${var.topogy_service_account_email}"

  depends_on = [google_project_service.required_apis]
}

// Grant BigQuery Data Viewer role to service account for the billing dataset
// Grant access to the billing dataset (either created or existing)
resource "google_bigquery_dataset_access" "billing_data_viewer" {
  dataset_id    = local.billing_dataset_id
  project       = local.bigquery_project_id
  role          = "roles/bigquery.dataViewer"
  user_by_email = var.topogy_service_account_email

  depends_on = [google_bigquery_dataset.billing_dataset]
}
