resource "azurerm_application_insights" "ai" {
  name                                  = var.name
  location                              = var.location
  resource_group_name                   = var.resource_group_name
  application_type                      = var.application_type
  daily_data_cap_in_gb                  = var.daily_data_cap_in_gb
  retention_in_days                     = var.retention_in_days
  local_authentication_disabled         = var.local_authentication_disabled
  internet_query_enabled                = var.internet_query_enabled
  sampling_percentage                   = local.sampling_percentage
  disable_ip_masking                    = local.disable_ip_masking
  internet_ingestion_enabled            = local.internet_ingestion_enabled
  daily_data_cap_notifications_disabled = local.daily_data_cap_notifications_disabled
  force_customer_storage_for_profiler   = local.force_customer_storage_for_profiler
  tags                                  = var.tags
  # TODO: Enable it as soon as project gets LAW ID of IT team or if needed
  workspace_id                          = var.law_id
}
