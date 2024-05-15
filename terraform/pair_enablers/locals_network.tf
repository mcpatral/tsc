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
    cidr_blocks = split(",", var.PAIR_VNET_CIDR_BLOCKS)

    subnets = {
      "subnet-${local.name_base}-${local.subnet_key_names.aks_primary}"        = var.PAIR_SUBNET_AKS_PRIMARY_CIDR,
      "subnet-${local.name_base}-${local.subnet_key_names.endpoints}"          = var.PAIR_SUBNET_ENDPOINTS_CIDR,
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-public"  = var.PAIR_SUBNET_DBW_PUBLIC_CIDR,
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-private" = var.PAIR_SUBNET_DBW_PRIVATE_CIDR,
      "subnet-${local.name_base}-${local.subnet_key_names.aks_aml}"            = var.PAIR_SUBNET_AKS_AML_CIDR,
      "subnet-${local.name_base}-${local.subnet_key_names.devops}"             = var.PAIR_SUBNET_AKS_DEVOPS_CIDR,
      "subnet-${local.name_base}-${local.subnet_key_names.postgres}"           = var.PAIR_SUBNET_POSTGRES_CIDR
    }

    route_tables_ids = {
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-public"  = azurerm_route_table.rt.id
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-private" = azurerm_route_table.rt.id
    }

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
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-public"  = ["Microsoft.KeyVault", "Microsoft.Storage"],
      "subnet-${local.name_base}-${local.subnet_key_names.databricks}-private" = ["Microsoft.KeyVault", "Microsoft.Storage"],
      "subnet-${local.name_base}-${local.subnet_key_names.aks_aml}"            = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.ContainerRegistry"],
      "subnet-${local.name_base}-${local.subnet_key_names.devops}"             = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.ContainerRegistry"],
      "subnet-${local.name_base}-${local.subnet_key_names.postgres}"           = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }

    subnet_enforce_private_link_endpoint_network_policies = {
      "subnet-${local.name_base}-${local.subnet_key_names.endpoints}" = true,
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
}