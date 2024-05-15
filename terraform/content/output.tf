output "catalog_name" {
  value       = databricks_catalog.silver.name
  description = "Databricks Catalog name"
}

output "databricks_single_cluster_id" {
  value = module.databricks_cluster["single"].databricks_cluster_id
}

output "databricks_provision_cluster_id" {
  value = module.databricks_cluster["provision"].databricks_cluster_id
}
