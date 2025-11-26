# Topogy Terraform for GCP Integration

This module sets up Topogy integration with your GCP organization, including optional billing data setup and service account access configuration.

## Overview

This module:
1. **Optionally creates billing infrastructure**:
   - Creates a new GCP project for billing data (optional)
   - Creates a BigQuery dataset for billing data (optional)
   - Enables required APIs (BigQuery, BigQuery Data Transfer, Cloud Billing)
2. **Grants Topogy service account access**:
   - Enables required APIs in all projects (or specified projects)
   - Creates and grants custom IAM roles:
     - `TopogyReadOnlyRole` - Organization-level read-only access to cloud assets, resources, and monitoring data
     - `TopogyBigQueryJobsRole` - Project-level BigQuery job operations
   - Grants the built-in `Recommender Viewer` role at the organization level
   - Grants BigQuery Data Viewer access to the billing dataset

## Usage

### Basic Usage (with billing dataset creation)

```hcl
module "topogy_integration" {
  source = "./modules/gcp-terraform-topogy-integration"

  gcp_org_id                   = "YOUR_ORG_ID"
  gcp_billing_account_id       = "YOUR_BILLING_ACCOUNT_ID"
  topogy_service_account_email = "topogy-service-account@project.iam.gserviceaccount.com"

  # Create billing dataset
  create_billing_project = true
  create_billing_dataset = true
}
```

### Using Existing Billing Dataset

```hcl
module "topogy_integration" {
  source = "git::https://github.com/topogy-public/gcp-terraform-topogy-integration.git?ref=main"

  gcp_org_id                   = "YOUR_ORG_ID"
  topogy_service_account_email = "TOPOGY_SERVICE_ACCOUNT_EMAIL" # This can be found in the GCP integration page in Topogy

  # Use existing billing dataset
  create_billing_project       = false
  create_billing_dataset       = false
  bigquery_project_id          = "existing-billing-project"  # Used for both BigQuery operations and billing dataset
  gcp_billing_data_dataset_id  = "existing_billing_dataset"

  # If you want terraform to create billing project and dataset
  create_billing_project = true
  create_billing_dataset = true
  billing_account_id     = ""
}
```

## Required Information

- **GCP Organization ID**: Your GCP organization ID
- **Topogy Service Account Email**: Provided by Topogy (e.g., `topogy-fintu-xxxxx@prod-client-sa-xxxxx.iam.gserviceaccount.com`)
- **Billing Account ID**: Required only if `create_billing_project = true`
- **BigQuery Project ID**: The project where BigQuery operations occur (jobs role, billing dataset if created). Required if `create_billing_dataset = true` and `create_billing_project = false`. If `create_billing_project = true` and not provided, a new project ID will be generated.

No keys, tokens, or other credentials are needed.

## What Gets Created

### If `create_billing_dataset = true`:
- **Billing Project**:
  - New GCP project for billing data
  - APIs enabled: BigQuery, BigQuery Data Transfer, Cloud Billing

- **Billing Dataset**:
  - BigQuery dataset for storing billing export data
  - Automatically granted to Topogy service account

### Always Created:
- **APIs enabled** in all accessible projects (or specified via `project_ids`):
  - Cloud Asset API
  - Cloud Billing API
  - Cloud Resource Manager API
  - Monitoring API
  - Recommender API

- **Custom roles**:
  - `TopogyReadOnlyRole` (organization-level)
  - `TopogyBigQueryJobsRole` (project-level, in BigQuery project)

- **IAM bindings**:
  - Organization-level: `TopogyReadOnlyRole`, `roles/recommender.viewer`
  - Project-level: `TopogyBigQueryJobsRole`
  - Dataset-level: `roles/bigquery.dataViewer` for the billing dataset

## Outputs

- `billing_project_id`: ID of the billing project
- `billing_dataset_id`: ID of the billing dataset

## Pre-requirements

The service account running this Terraform script needs the following permissions (if creating billing project):
- Organization Administrator
- Service Account Admin
- Service Account Key Admin
- Service Usage Admin
- Billing Account Administrator
- Project Creator

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.0.0, < 7.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 5.0.0, < 7.0.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_bigquery_dataset.billing_dataset](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset) | resource |
| [google_bigquery_dataset_access.billing_data_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset_access) | resource |
| [google_organization_iam_custom_role.readonly_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_organization_iam_custom_role) | resource |
| [google_organization_iam_member.readonly_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_organization_iam#google_organization_iam_member) | resource |
| [google_organization_iam_member.recommender_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_organization_iam#google_organization_iam_member) | resource |
| [google_project.billing_data_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project) | resource |
| [google_project_iam_custom_role.bigquery_jobs_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam_custom_role) | resource |
| [google_project_iam_member.bigquery_jobs_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam#google_project_iam_member) | resource |
| [google_project_service.billing_apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) | resource |
| [google_project_service.required_apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service) | resource |
| [random_id.billing_project_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [google_projects.all_projects](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bigquery_jobs_role_id"></a> [bigquery\_jobs\_role\_id](#input\_bigquery\_jobs\_role\_id) | The ID (name) of the custom BigQuery jobs role. This will be used to create and reference the role. | `string` | `"TopogyBigQueryJobsRole"` | no |
| <a name="input_bigquery_jobs_role_permissions"></a> [bigquery\_jobs\_role\_permissions](#input\_bigquery\_jobs\_role\_permissions) | List of permissions for the BigQuery jobs custom role. | `list(string)` | <pre>[<br/>  "bigquery.jobs.create",<br/>  "bigquery.jobs.get",<br/>  "bigquery.jobs.list"<br/>]</pre> | no |
| <a name="input_bigquery_project_id"></a> [bigquery\_project\_id](#input\_bigquery\_project\_id) | The GCP Project ID where BigQuery operations occur (jobs role creation, billing dataset if created). Required if create\_billing\_project=false (to grant access to existing dataset). If create\_billing\_project=true and not provided, a new project ID will be generated. | `string` | `null` | no |
| <a name="input_billing_dataset_location"></a> [billing\_dataset\_location](#input\_billing\_dataset\_location) | Location for the BigQuery billing dataset (e.g., US, EU). | `string` | `"US"` | no |
| <a name="input_billing_project_name"></a> [billing\_project\_name](#input\_billing\_project\_name) | Name for the new billing project (only used if create\_billing\_project is true). | `string` | `"Billing BigQuery"` | no |
| <a name="input_create_bigquery_jobs_role"></a> [create\_bigquery\_jobs\_role](#input\_create\_bigquery\_jobs\_role) | Whether to create the BigQuery jobs custom role. Set to false if the role is already created by another module instance. | `bool` | `true` | no |
| <a name="input_create_billing_dataset"></a> [create\_billing\_dataset](#input\_create\_billing\_dataset) | Whether to create a BigQuery dataset for billing data. | `bool` | `false` | no |
| <a name="input_create_billing_project"></a> [create\_billing\_project](#input\_create\_billing\_project) | Whether to create a new project for billing data. If false, bigquery\_project\_id must be provided. If true and bigquery\_project\_id is not provided, a new project ID will be generated. | `bool` | `false` | no |
| <a name="input_create_readonly_role"></a> [create\_readonly\_role](#input\_create\_readonly\_role) | Whether to create the read-only custom role. Set to false if the role is already created by another module instance. | `bool` | `true` | no |
| <a name="input_gcp_billing_account_id"></a> [gcp\_billing\_account\_id](#input\_gcp\_billing\_account\_id) | GCP Billing Account ID (required if create\_billing\_project is true). | `string` | `null` | no |
| <a name="input_gcp_billing_data_dataset_description"></a> [gcp\_billing\_data\_dataset\_description](#input\_gcp\_billing\_data\_dataset\_description) | Dataset description for the billing data. | `string` | `"All billing data (required by Topogy)"` | no |
| <a name="input_gcp_billing_data_dataset_id"></a> [gcp\_billing\_data\_dataset\_id](#input\_gcp\_billing\_data\_dataset\_id) | Dataset identifier where the billing data will be stored. | `string` | `"all_billing_data"` | no |
| <a name="input_gcp_org_id"></a> [gcp\_org\_id](#input\_gcp\_org\_id) | GCP Organization ID | `string` | n/a | yes |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | Optional list of project IDs where APIs should be enabled. If not provided, will attempt to auto-detect all accessible projects. Use this if the auto-detection isn't working. | `list(string)` | `null` | no |
| <a name="input_readonly_role_id"></a> [readonly\_role\_id](#input\_readonly\_role\_id) | The ID (name) of the custom read-only role. This will be used to create and reference the role at the organization level. | `string` | `"TopogyReadOnlyRole"` | no |
| <a name="input_readonly_role_permissions"></a> [readonly\_role\_permissions](#input\_readonly\_role\_permissions) | List of permissions for the read-only custom role. | `list(string)` | <pre>[<br/>  "cloudasset.assets.exportCloudresourcemanagerFolders",<br/>  "cloudasset.assets.exportCloudresourcemanagerOrganizations",<br/>  "cloudasset.assets.exportCloudresourcemanagerProjects",<br/>  "cloudasset.assets.exportResource",<br/>  "cloudasset.assets.listCloudresourcemanagerFolders",<br/>  "cloudasset.assets.listCloudresourcemanagerOrganizations",<br/>  "cloudasset.assets.listCloudresourcemanagerProjects",<br/>  "cloudasset.assets.listResource",<br/>  "cloudasset.assets.searchAllResources",<br/>  "compute.commitments.get",<br/>  "compute.commitments.list",<br/>  "compute.regions.list",<br/>  "monitoring.metricDescriptors.list",<br/>  "monitoring.timeSeries.list",<br/>  "resourcemanager.folders.get",<br/>  "resourcemanager.folders.list",<br/>  "resourcemanager.organizations.get",<br/>  "resourcemanager.projects.get",<br/>  "resourcemanager.projects.getIamPolicy",<br/>  "resourcemanager.projects.list"<br/>]</pre> | no |
| <a name="input_topogy_service_account_email"></a> [topogy\_service\_account\_email](#input\_topogy\_service\_account\_email) | The email of the Topogy service account (provided by Topogy, e.g. topogy-fintu-3bekh7jf5mrav324@devel-client-sa-57df.iam.gserviceaccount.com) | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_billing_dataset_id"></a> [billing\_dataset\_id](#output\_billing\_dataset\_id) | The ID of the BigQuery billing dataset. |
| <a name="output_billing_project_id"></a> [billing\_project\_id](#output\_billing\_project\_id) | The ID of the project where the billing dataset is located (or would be located if created). |
<!-- END_TF_DOCS -->
