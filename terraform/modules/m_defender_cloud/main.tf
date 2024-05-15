data "azurerm_subscription" "current" {}

# Enabling the default Azure Security Benchmark Policy initiative
resource "azurerm_subscription_policy_assignment" "asb_assignment" {
  name                 = var.policy_assignment_name
  display_name         = var.policy_assignment_display_name
  policy_definition_id = var.policy_definition_id
  subscription_id      = data.azurerm_subscription.current.id
}

# Enabling MDC Plans
## Now that we’ve already set up Security Posture, let’s move on to Workload Protection. After choosing which Defender Plans you want to enable, you’ll declare a Terraform resource for each plan.
resource "azurerm_security_center_subscription_pricing" "mdc_kv" {
  count         = length(var.security_center_subscription_resource_type)
  tier          = var.security_center_subscription_tier
  resource_type = var.security_center_subscription_resource_type[count.index]
}

resource "azurerm_security_center_subscription_pricing" "mdc_sa" {
  tier          = "Standard"
  resource_type = "StorageAccounts"
}

# Enabling integrations with MDE and MDCA
## The integrations with Microsoft Defender for Endpoint and Microsoft Defender for Cloud Apps are enabled by default, but you may want to manage them as code.
resource "azurerm_security_center_setting" "setting_mcas" {
  setting_name = var.security_center_mcas_name
  enabled      = var.security_center_mcas_enabled
}

resource "azurerm_security_center_setting" "setting_mde" {
  setting_name = var.security_center_mde_name
  enabled      = var.security_center_mde_enabled
}

# Setting up security contacts
## If MDC needs to notify you about a security incident, it’s a good idea to have e-mail and phone contacts set up.
resource "azurerm_security_center_contact" "mdc_contact" {
  email               = var.mdc_contact_email
  phone               = var.mdc_contact_phone
  alert_notifications = var.mdc_alert_notifications
  alerts_to_admins    = var.mdc_alerts_to_admins
}

# Enabling Log Analytics agent auto-provisioning
resource "azurerm_security_center_auto_provisioning" "auto-provisioning" {
  auto_provision = var.security_center_auto_provision
}

## There’s a specific resource for that and it’s very simple to deal with. It’s just an On/Off property. Next, we are going to associate Defender for Servers to a specific Log Analytics workspace.
# resource "azurerm_security_center_workspace" "la_workspace" {
#   scope        = data.azurerm_subscription.current.id
#   workspace_id = "/subscriptions/<subscription id>/resourcegroups/<resource group name>/providers/microsoft.operationalinsights/workspaces/<workspace name>"
# }

## The declaration above will work for an existing Log Analytics workspace. If you want to create the Log Analytics workspace together with MDC, you will use a slightly different approach:
resource "azurerm_resource_group" "security_rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_log_analytics_workspace" "la_workspace" {
  name                = var.la_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.la_workspace_sku
}

resource "azurerm_security_center_workspace" "la_workspace" {
  scope        = data.azurerm_subscription.current.id
  workspace_id = azurerm_log_analytics_workspace.la_workspace.id
}

# Enabling Vulnerability Assessment auto-provisioning
## Unlike the Log Analytics counterpart, Vulnerability Assessment auto-provisioning is configured with the help of an Azure Policy assignment. The choice between leveraging Qualys or MDE vulnerability assessment is done as a Policy assignment parameter.
resource "azurerm_subscription_policy_assignment" "va-auto-provisioning" {
  name                 = var.policy_assignment_va_auto_name
  display_name         = var.policy_assignment_va_auto_display_name
  policy_definition_id = var.policy_definition_va_auto_id
  subscription_id      = data.azurerm_subscription.current.id
  identity {
    type = var.policy_assignment_va_auto_identity
  }
  location   = var.policy_assignment_va_auto_location
  parameters = <<PARAMS
{ "vaType": { "value": "mdeTvm" } }
PARAMS
}

resource "azurerm_role_assignment" "va-auto-provisioning-identity-role" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = var.role_assigment_va_auto_role_id
  principal_id       = azurerm_subscription_policy_assignment.va-auto-provisioning.identity[0].principal_id
}

# Configuring Continuous Export settings
## We are exporting to a specific Log Analytics workspace High/Medium Security Alerts and all the Secure Score controls.
resource "azurerm_security_center_automation" "la-exports" {
  name                = var.la_exports_name
  location            = var.location
  resource_group_name = var.resource_group_name

  action {
    type        = var.la_exports_action
    resource_id = azurerm_log_analytics_workspace.la_workspace.id
  }

  source {
    event_source = var.la_exports_event_source[0]
    rule_set {
      rule {
        property_path  = var.la_exports_event_rule_property_path
        operator       = var.la_exports_event_rule_operator
        expected_value = var.la_exports_event_rule_expected_value[0]
        property_type  = var.la_exports_event_rule_property_type
      }
      rule {
        property_path  = var.la_exports_event_rule_property_path
        operator       = var.la_exports_event_rule_operator
        expected_value = var.la_exports_event_rule_expected_value[1]
        property_type  = var.la_exports_event_rule_property_type
      }
    }
  }

  source {
    event_source = var.la_exports_event_source[1]
  }

  source {
    event_source = var.la_exports_event_source[2]
  }

  scopes = [data.azurerm_subscription.current.id]
}