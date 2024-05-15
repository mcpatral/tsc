locals {
  subnet_key_names = {
    aks_primary = "aks-primary"
    endpoints   = "endpoints"
    databricks  = "dbw"
    aks_aml     = "aks-aml"
    devops      = "devops-agents"
    postgres    = "postgres"
  }

  vnet = {
    cidr_blocks = split(",", var.VNET_CIDR_BLOCKS)
    tags        = {}

    subnets = {
      "subnet-${local.name_base}-${local.subnet_key_names.aks_primary}"        = var.SUBNET_AKS_PRIMARY_CIDR,
      "subnet-${local.name_base}-${local.subnet_key_names.endpoints}"          = var.SUBNET_ENDPOINTS_CIDR,
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-public"  = var.SUBNET_DBW_PUBLIC_CIDR,
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-private" = var.SUBNET_DBW_PRIVATE_CIDR,
      "subnet-${local.name_base}-${local.subnet_key_names.aks_aml}"            = var.SUBNET_AKS_AML_CIDR,
      "subnet-${local.name_base}-${local.subnet_key_names.devops}"             = var.SUBNET_AKS_DEVOPS_CIDR,
      "subnet-${local.name_base}-${local.subnet_key_names.postgres}"           = var.SUBNET_POSTGRES_CIDR
    }

    route_tables_ids = merge({
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-public"  = azurerm_route_table.rt["databricks"].id
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-private" = azurerm_route_table.rt["databricks"].id
    }, local.vnet_peered_route_tables_ids)

    nsg_ids = {
      "subnet-${local.name_base}-${local.subnet_key_names.aks_primary}"        = module.nsg[local.subnet_key_names.aks_primary].nsg_id
      "subnet-${local.name_base}-${local.subnet_key_names.endpoints}"          = module.nsg[local.subnet_key_names.endpoints].nsg_id
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-public"  = module.nsg[local.subnet_key_names.databricks].nsg_id
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-private" = module.nsg[local.subnet_key_names.databricks].nsg_id
      "subnet-${local.name_base}-${local.subnet_key_names.aks_aml}"            = module.nsg[local.subnet_key_names.aks_aml].nsg_id
      "subnet-${local.name_base}-${local.subnet_key_names.devops}"             = module.nsg[local.subnet_key_names.devops].nsg_id
      "subnet-${local.name_base}-${local.subnet_key_names.postgres}"           = module.nsg[local.subnet_key_names.postgres].nsg_id
    }

    subnet_service_endpoints = {
      "subnet-${local.name_base}-${local.subnet_key_names.aks_primary}"        = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.ContainerRegistry"],
      "subnet-${local.name_base}-${local.subnet_key_names.endpoints}"          = ["Microsoft.KeyVault", "Microsoft.Storage"],
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-public"  = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.EventHub", "Microsoft.Sql"],
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-private" = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.EventHub", "Microsoft.Sql"],
      "subnet-${local.name_base}-${local.subnet_key_names.aks_aml}"            = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.ContainerRegistry"],
      "subnet-${local.name_base}-${local.subnet_key_names.devops}"             = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.ContainerRegistry"],
      "subnet-${local.name_base}-${local.subnet_key_names.postgres}"           = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }

    subnet_enforce_private_link_endpoint_network_policies = {
      "subnet-${local.name_base}-${local.subnet_key_names.endpoints}"          = true,
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-public"  = true,
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-private" = true,
      "subnet-${local.name_base}-${local.subnet_key_names.aks_primary}"        = true
    }

    subnet_delegation = {
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-private" = {
        "Microsoft.Databricks.workspaces" = {
          service_name = "Microsoft.Databricks/workspaces"
          service_actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action",
            "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
            "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
          ]
        }
      }

      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-public" = {
        "Microsoft.Databricks.workspaces" = {
          service_name = "Microsoft.Databricks/workspaces"
          service_actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action",
            "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
            "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
          ]
        }
      }

      "subnet-${local.name_base}-${local.subnet_key_names.postgres}" = {
        "Microsoft.DBforPostgreSQL.flexibleServers" = {
          service_name = "Microsoft.DBforPostgreSQL/flexibleServers"
          service_actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action",
          ]
        }
      }
    }
  }

  subnet_aks_route_tables = var.VNET_PEERED ? {
    devops = {
      name = local.subnet_key_names.devops,
      tags = {}
    },
    aks_primary = {
      name = local.subnet_key_names.aks_primary,
      tags = {}
    }
  } : {}

  subnet_route_tables = {
    objects = merge({
      databricks = {
        name = local.subnet_key_names.databricks,
        tags = {}
      }
    }, local.subnet_aks_route_tables),
    disable_route_propagation = true
  }

  vnet_peered_route_tables_ids = var.VNET_PEERED ? {
    "subnet-${local.name_base}-${local.subnet_key_names.devops}"      = azurerm_route_table.rt["devops"].id
    "subnet-${local.name_base}-${local.subnet_key_names.aks_primary}" = azurerm_route_table.rt["aks_primary"].id
  } : {}

  peered_subnet_routes = var.VNET_PEERED ? {
    "${local.subnet_route_tables.objects["devops"].name}_firewall" = {
      name                   = "firewall"
      route_table_name       = azurerm_route_table.rt["devops"].name
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.FIREWALL_PRIVATE_IP
    },
    "${local.subnet_route_tables.objects["aks_primary"].name}_firewall" = {
      name                   = "firewall"
      route_table_name       = azurerm_route_table.rt["aks_primary"].name
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.FIREWALL_PRIVATE_IP
    },
    "${local.subnet_route_tables.objects["databricks"].name}_firewall" = {
      name                   = "firewall"
      route_table_name       = azurerm_route_table.rt["databricks"].name
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.FIREWALL_PRIVATE_IP
    }
  } : {}

  subnet_routes = merge({
    "${local.subnet_route_tables.objects["databricks"].name}_dbw_control_plane" = {
      name                   = "dbw_control_plane"
      route_table_name       = azurerm_route_table.rt["databricks"].name
      address_prefix         = "AzureDatabricks"
      next_hop_type          = "Internet"
      next_hop_in_ip_address = null
    },
    "${local.subnet_route_tables.objects["databricks"].name}_dbw_warehouse" = {
      name                   = "dbw_warehouse"
      route_table_name       = azurerm_route_table.rt["databricks"].name
      address_prefix         = "Sql"
      next_hop_type          = "Internet"
      next_hop_in_ip_address = null
    },
    "${local.subnet_route_tables.objects["databricks"].name}_storage_accounts" = {
      name                   = "dbw_storage_accounts"
      route_table_name       = azurerm_route_table.rt["databricks"].name
      address_prefix         = "Storage"
      next_hop_type          = "Internet"
      next_hop_in_ip_address = null
    },
    "${local.subnet_route_tables.objects["databricks"].name}_eventhub" = {
      name                   = "dbw_eventhub"
      route_table_name       = azurerm_route_table.rt["databricks"].name
      address_prefix         = "EventHub"
      next_hop_type          = "Internet"
      next_hop_in_ip_address = null
    },
    "${local.subnet_route_tables.objects["databricks"].name}_dbw_extinfra" = {
      name                   = "dbw_extended_infra"
      route_table_name       = azurerm_route_table.rt["databricks"].name
      address_prefix         = "20.73.215.48/28"
      next_hop_type          = "Internet"
      next_hop_in_ip_address = null
    }
  }, local.peered_subnet_routes)
}