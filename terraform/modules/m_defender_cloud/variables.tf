# Policy
variable "policy_assignment_name" {}
variable "policy_assignment_display_name" {}
variable "policy_definition_id" {}
# Enabling MDC Plans
variable "security_center_subscription_tier" {}
variable "security_center_subscription_resource_type" {
  type = list(string)
}
# Security Center
variable "security_center_mcas_name" {}
variable "security_center_mcas_enabled" {}
variable "security_center_mde_name" {}
variable "security_center_mde_enabled" {}
variable "security_center_auto_provision" {}
# Contact
variable "mdc_contact_email" {}
variable "mdc_contact_phone" {}
variable "mdc_alert_notifications" {}
variable "mdc_alerts_to_admins" {}
# Log Analytics
variable "resource_group_name" {}
variable "location" {}
variable "la_workspace_name" {}
variable "la_workspace_sku" {}
# Enabling Vulnerability Assessment auto-provisioning
variable "policy_assignment_va_auto_name" {}
variable "policy_assignment_va_auto_display_name" {}
variable "policy_definition_va_auto_id" {}
variable "policy_assignment_va_auto_identity" {}
variable "policy_assignment_va_auto_location" {}
variable "role_assigment_va_auto_role_id" {}
# Configuring Continuous Export settings
variable "la_exports_name" {}
variable "la_exports_action" {}
variable "la_exports_event_source" {
  type = list(string)
}
variable "la_exports_event_rule_property_path" {
  type = string
}
variable "la_exports_event_rule_operator" {
  type = string
}
variable "la_exports_event_rule_expected_value" {
  type = list(string)
}
variable "la_exports_event_rule_property_type" {
  type = string
}