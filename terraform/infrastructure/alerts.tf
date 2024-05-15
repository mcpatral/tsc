resource "azurerm_monitor_action_group" "action_group" {
  for_each            = local.action_groups
  name                = each.value.resource_name
  resource_group_name = local.enablers_tfstate_output.resource_group_name
  short_name          = each.value.short_name

  dynamic "email_receiver" {
    for_each = each.value.email_receiver_common
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email_receiver
      use_common_alert_schema = true
    }
  }
}

resource "azurerm_monitor_metric_alert" "alerts" {
  for_each                 = local.metric_alerts
  name                     = each.value.name
  resource_group_name      = local.enablers_tfstate_output.resource_group_name
  scopes                   = each.value.scopes
  description              = each.value.description
  auto_mitigate            = each.value.auto_mitigate
  frequency                = each.value.frequency
  severity                 = each.value.severity
  target_resource_type     = try(each.value.target_resource_type, null)
  target_resource_location = try(each.value.target_resource_location, null)
  window_size              = each.value.window_size
  tags                     = local.common_tags

  dynamic "criteria" {
    for_each = try(each.value.criterias, [])
    content {
      metric_namespace       = criteria.value.metric_namespace
      metric_name            = criteria.value.metric_name
      aggregation            = criteria.value.aggregation
      operator               = criteria.value.operator
      threshold              = criteria.value.threshold
      skip_metric_validation = criteria.value.skip_metric_validation

      dynamic "dimension" {
        for_each = try(criteria.value.dimension, [])
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "dynamic_criteria" {
    for_each = try(each.value.dynamic_criterias, [])
    content {
      metric_namespace       = dynamic_criteria.value.metric_namespace
      metric_name            = dynamic_criteria.value.metric_name
      aggregation            = dynamic_criteria.value.aggregation
      operator               = dynamic_criteria.value.operator
      alert_sensitivity      = dynamic_criteria.value.alert_sensitivity
      skip_metric_validation = dynamic_criteria.value.skip_metric_validation

      dynamic "dimension" {
        for_each = try(dynamic_criteria.value.dimension, [])
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  action {
    action_group_id = each.value.action_group_id
  }
}

resource "azurerm_monitor_activity_log_alert" "resource_health" {
  for_each            = local.resource_health_alerts
  name                = each.value.resource_name
  resource_group_name = local.enablers_tfstate_output.resource_group_name
  location            = var.LOCATION
  scopes              = each.value.scopes
  description         = "Resource Health alert. Check with Microsoft if triggered."
  tags                = local.common_tags

  criteria {
    category = "ResourceHealth"

    resource_health {
      current  = ["Unavailable", "Degraded"]
      previous = ["Available", "Unknown"]
      reason   = ["PlatformInitiated", "Unknown"]
    }
  }

  action {
    action_group_id = each.value.action_group_id
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "alerts" {
  for_each             = local.log_alerts
  name                 = each.value.resource_name
  resource_group_name  = local.enablers_tfstate_output.resource_group_name
  location             = var.LOCATION
  evaluation_frequency = each.value.evaluation_frequency
  window_duration      = each.value.window_duration
  scopes               = each.value.scopes
  severity             = each.value.severity

  criteria {
    query                   = each.value.criteria.query
    time_aggregation_method = each.value.criteria.time_aggregation_method
    threshold               = each.value.criteria.threshold
    operator                = each.value.criteria.operator

    dimension {
      name     = each.value.criteria.dimension.name
      operator = each.value.criteria.dimension.operator
      values   = each.value.criteria.dimension.values
    }

    failing_periods {
      minimum_failing_periods_to_trigger_alert = each.value.criteria.failing_periods.minimum_failing_periods_to_trigger_alert
      number_of_evaluation_periods             = each.value.criteria.failing_periods.number_of_evaluation_periods
    }
  }

  auto_mitigation_enabled = true
  description             = each.value.description
  display_name            = each.value.display_name
  enabled                 = true

  action {
    action_groups = each.value.action_groups
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.managed_identity.id,
    ]
  }
}

resource "azurerm_user_assigned_identity" "managed_identity" {
  name                = "mi-${local.name_base}-alerts"
  location            = var.LOCATION
  resource_group_name = local.enablers_tfstate_output.resource_group_name
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "role_log_reader_alert_py_err" {
  principal_id                     = azurerm_user_assigned_identity.managed_identity.principal_id
  role_definition_name             = "Log Analytics Reader"
  scope                            = module.aks["main"].aks_cluster_id
  skip_service_principal_aad_check = true
}
