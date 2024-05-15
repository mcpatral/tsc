#Notes: Application Insights doesn’t support disaster recovery as of 2021.
#More info: https://learn.microsoft.com/en-us/answers/questions/503062/applications-insights-geo-redundancy
/*
module "appinsights" {
  # TODO: Review how many AI resources we need to create
  # Might be needed to introduce for_each in case of multiple instances
  source                        = "../modules/appinsights"
  name                          = local.appinsights.name
  resource_group_name           = local.enablers_tfstate_output.resource_group_name
  location                      = var.LOCATION
  tags                          = merge(local.common_tags, local.appinsights.tags)
  application_type              = local.appinsights.application_type
  daily_data_cap_in_gb          = local.appinsights.daily_data_cap_in_gb
  retention_in_days             = local.appinsights.retention_in_days
  local_authentication_disabled = local.appinsights.local_authentication_disabled
  internet_query_enabled        = local.appinsights.internet_query_enabled
  law_id                        = local.appinsights.law_id
}*/