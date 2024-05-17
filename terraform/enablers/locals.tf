locals {
  provider_storage_use_azuread = true

  name_base         = "${var.ENVIRONMENT_TYPE}-${var.PROJECT}-${var.LOCATION_SHORT}"
  name_base_no_dash = replace(local.name_base, "-", "")
  name_base_central = "${var.SUBSCRIPTION_TYPE}-${var.PROJECT}-${var.LOCATION_SHORT_CENTRAL}"

  azure_dns_ip      = "168.63.129.16"
  azure_fw_ip       = var.FIREWALL_PUBLIC_IP != null ? ["${var.FIREWALL_PUBLIC_IP}/32"] : []
  mcpatral_public_ips = var.VNET_PEERED ? concat(["194.11.129.242/32"], local.azure_fw_ip) : ["194.11.129.242/32"]
  mcpatral_vpn_cidrs  = compact(["10.188.0.0/16", "10.64.0.0/16", "10.65.0.0/16", "10.192.0.0/13", "10.208.0.0/12", var.HUB_VNET_CIDR_BLOCK])
  authorized_ips = toset(
    compact(
      concat(local.mcpatral_public_ips, split(",", var.ADDITIONAL_AUTHORIZED_IPS))
    )
  )

  common_tags = {
    Country              = "Global"
    BusinessApplication  = "Gaia"
    SupportTeam          = var.SUBSCRIPTION_TYPE == "prod" ? "Infrastructure_and_Operations" : "Data_and_Analytics"
    Environment          = var.ENVIRONMENT_TYPE
    Company              = "mcpatral"
    BusinessCriticallity = var.SUBSCRIPTION_TYPE == "prod" ? "High" : "Low"
    Project              = var.PROJECT
    CostCentre           = "Common"
    DataClassification   = "Internal"
  }

  # Most fields are supported with Premium SKU only
  acr = {
    name                          = "main"
    admin_enabled                 = false
    public_network_access_enabled = false
    retention_policy_enabled      = false
    retention_policy_days         = 30
    allowed_cidrs                 = local.authorized_ips
    zone_redundancy_enabled       = true
    georeplication_enabled        = var.PAIR_PAAS
    tags                          = {}
    georeplication_locations = [
      {
        location                  = var.LOCATION_SHORT == "weu" ? "North Europe" : "West Europe"
        regional_endpoint_enabled = true
        zone_redundancy_enabled   = true
      }
    ]
    allowed_subnets = [
      module.vnet.vnet_subnets["subnet-${local.name_base}-${local.subnet_key_names.devops}"]
    ]
  }

  aks = {
    sku                           = "Standard"
    admin_username                = "azureuser"
    kubernetes_version            = "1.29.2"
    api_server_authorized_ips     = local.authorized_ips
    network_plugin                = "kubenet"
    network_policy                = "calico"
    open_service_mesh_enabled     = true
    name                          = "devops-agents"
    public_network_access_enabled = true
    private_cluster_enabled       = false
    dns_prefix                    = "${var.ENVIRONMENT_TYPE}-devops-agents"
    network_lb_sku                = "standard"
    network_outbound_type         = var.VNET_PEERED ? "userDefinedRouting" : "loadBalancer"
    identity_type                 = "UserAssigned"
    network_pod_cidr              = "10.244.0.0/16"
    tags                          = {}
  }

  aks_default_node_pool = {
    vm_size              = "Standard_DS2_v2"
    node_count           = 2
    subnet_id            = module.vnet.vnet_subnets["subnet-${local.name_base}-${local.subnet_key_names.devops}"]
    auto_scaling_enabled = false
    orchestrator_version = local.aks.kubernetes_version
  }

  aks_cluster_node_pools = {
    "adoagents" = {
      vm_size              = var.DEVOPS_AKS_SIZE
      node_count           = var.DEVOPS_AKS_NODE_COUNT
      node_max_pods        = var.DEVOPS_AKS_NODE_MAX_PODS
      subnet_id            = module.vnet.vnet_subnets["subnet-${local.name_base}-${local.subnet_key_names.devops}"]
      orchestrator_version = local.aks.kubernetes_version
      mode                 = "User"
      scale_down_mode      = "Delete"
      auto_scaling_enabled = false
      node_labels = {
        pool = "adoagents"
      }
    }
  }

  prometheus_grafana = {
    grafana_api_key_enabled                   = true
    grafana_deterministic_outbound_ip_enabled = false
    grafana_public_network_access_enabled     = true
    tags                                      = {}
    roles = {
      admin_group_ids  = toset([var.DEVOPS_GROUP_ID])
      editor_group_ids = []
      viewer_group_ids = toset([var.DEVELOPER_GROUP_ID, var.QA_GROUP_ID])
    }
  }

  managed_identities = {
    devops      = local.subnet_key_names.devops,
    aks_primary = local.subnet_key_names.aks_primary
  }

  managed_identities_assignments_vnet = {
    devops_vnet = {
      mi_key                           = "devops"
      role                             = "Network Contributor",
      scope                            = module.vnet.vnet_id
      skip_service_principal_aad_check = true
    },
    aks_primary_vnet = {
      mi_key                           = "aks_primary"
      role                             = "Network Contributor",
      scope                            = module.vnet.vnet_id
      skip_service_principal_aad_check = true
    }
  }

  managed_identities_assignments_rt = var.VNET_PEERED ? {
    devops_rt = {
      mi_key                           = "devops"
      role                             = "Network Contributor",
      scope                            = azurerm_route_table.rt["devops"].id
      skip_service_principal_aad_check = true
    },
    aks_primary_rt = {
      mi_key                           = "aks_primary"
      role                             = "Network Contributor",
      scope                            = azurerm_route_table.rt["aks_primary"].id
      skip_service_principal_aad_check = true
    }
  } : {}

  managed_identities_assignments = merge(local.managed_identities_assignments_vnet, local.managed_identities_assignments_rt)

  resource_group_tags    = {}
  monitor_resources_tags = {}
}