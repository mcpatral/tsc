locals {
  nsg_tags = {}

  inbound_intrum_vpn_rules = var.VNET_PEERED ? { for index, value in local.intrum_vpn_cidrs : "AllowVPN${index}HTTPS" => {
    access             = "Allow",
    priority           = tonumber("17${index}"),
    protocol           = "Tcp",
    port               = "443",
    src_address_prefix = value,
    dst_address_prefix = "VirtualNetwork",
    }
  } : {}

  inbound_security_rules = {
    "${local.subnet_key_names.databricks}" = {
      "InDenyAll" = {
        access             = "Deny",
        priority           = 3000,
        protocol           = "*",
        port               = "*",
        src_address_prefix = "*",
        dst_address_prefix = "*",
      }
    }

    "${local.subnet_key_names.aks_primary}" = merge({
      "InAllowAllInternal" = {
        access             = "Allow",
        priority           = 1000,
        protocol           = "*",
        port               = "*",
        src_address_prefix = var.SUBNET_AKS_PRIMARY_CIDR,
        dst_address_prefix = "VirtualNetwork",
      },
      "InAllowAKSInternal" = {
        access             = "Allow",
        priority           = 1010,
        protocol           = "*",
        port               = "*",
        src_address_prefix = local.aks.network_pod_cidr,
        dst_address_prefix = "VirtualNetwork",
      },
      "InAllowDNS" = {
        access             = "Allow",
        priority           = 1020,
        protocol           = "*",
        port               = "53",
        src_address_prefix = local.azure_dns_ip,
        dst_address_prefix = "VirtualNetwork",
      },
      "InAllowAzureLB" = {
        access             = "Allow",
        priority           = 1030,
        protocol           = "*",
        port               = "*",
        src_address_prefix = "AzureLoadBalancer",
        dst_address_prefix = "VirtualNetwork",
      },
      # "AllowAdoVertica" = {
      #   access             = "Allow",
      #   priority           = 140,
      #   protocol           = "Tcp",
      #   port               = "5433",
      #   src_address_prefix = var.SUBNET_AKS_DEVOPS_CIDR,
      #   dst_address_prefix = "VirtualNetwork",
      # },
      "InAllowAdoHTTPS" = {
        access             = "Allow",
        priority           = 1050,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = var.SUBNET_AKS_DEVOPS_CIDR,
        dst_address_prefix = "VirtualNetwork",
      },
      "InDenyAll" = {
        access             = "Deny",
        priority           = 3000,
        protocol           = "*",
        port               = "*",
        src_address_prefix = "*",
        dst_address_prefix = "*",
      }
    }, local.inbound_intrum_vpn_rules)

    "${local.subnet_key_names.devops}" = merge({
      "InAllowAllInternal" = {
        access             = "Allow",
        priority           = 1000,
        protocol           = "*",
        port               = "*",
        src_address_prefix = var.SUBNET_AKS_DEVOPS_CIDR,
        dst_address_prefix = "VirtualNetwork",
      },
      "InAllowAKSInternal" = {
        access             = "Allow",
        priority           = 1010,
        protocol           = "*",
        port               = "*",
        src_address_prefix = local.aks.network_pod_cidr,
        dst_address_prefix = "VirtualNetwork",
      },
      "InAllowDNS" = {
        access             = "Allow",
        priority           = 1020,
        protocol           = "*",
        port               = "53",
        src_address_prefix = local.azure_dns_ip,
        dst_address_prefix = "VirtualNetwork",
      },
      "InAllowAzureLB" = {
        access             = "Allow",
        priority           = 1030,
        protocol           = "*",
        port               = "*",
        src_address_prefix = "AzureLoadBalancer",
        dst_address_prefix = "VirtualNetwork",
      },
      "InDenyAll" = {
        access             = "Deny",
        priority           = 3000,
        protocol           = "*",
        port               = "*",
        src_address_prefix = "*",
        dst_address_prefix = "*",
      }
    }, local.inbound_intrum_vpn_rules)

    "${local.subnet_key_names.postgres}" = {
      "InAllowAKSMainInbound" = {
        access             = "Allow",
        priority           = 1000,
        protocol           = "Tcp",
        port               = "5432",
        src_address_prefix = var.SUBNET_AKS_PRIMARY_CIDR,
        dst_address_prefix = "VirtualNetwork",
      }
      "InAllowAKSDevOpsInbound" = {
        access             = "Allow",
        priority           = 1010,
        protocol           = "Tcp",
        port               = "5432",
        src_address_prefix = var.SUBNET_AKS_DEVOPS_CIDR,
        dst_address_prefix = "VirtualNetwork",
      }
      "InDenyAll" = {
        access             = "Deny",
        priority           = 3000,
        protocol           = "*",
        port               = "*",
        src_address_prefix = "*",
        dst_address_prefix = "*",
      }
    }
  }

  outbound_security_rules = {
    "${local.subnet_key_names.databricks}" = {
      "OutAllowAADHTTPSOutbound" = {
        access             = "Allow",
        priority           = 1010,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "VirtualNetwork",
        dst_address_prefix = "AzureActiveDirectory",
      },
      "OutAllowFrontDoorHTTPSOutbound" = {
        access             = "Allow",
        priority           = 1020,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "VirtualNetwork",
        dst_address_prefix = "AzureFrontDoor.Frontend",
      }
    }

    "${local.subnet_key_names.aks_primary}" = {
      "OutAllowDatabricksHTTPSOutbound" = {
        access             = "Allow",
        priority           = 1000,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "VirtualNetwork",
        dst_address_prefix = "AzureDatabricks",
      },
      "OutAllowDataLakeHTTPSOutbound" = {
        access             = "Allow",
        priority           = 1010,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "VirtualNetwork",
        dst_address_prefix = "AzureDataLake",
      },
      "OutAllowKeyVaultHTTPSOutbound" = {
        access             = "Allow",
        priority           = 1020,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "VirtualNetwork",
        dst_address_prefix = "AzureKeyVault.${var.LOCATION}",
      },
      "OutAllowPostgreSQL5432Outbound" = {
        access             = "Allow",
        priority           = 1030,
        protocol           = "Tcp",
        port               = "5432",
        src_address_prefix = "VirtualNetwork",
        dst_address_prefix = "VirtualNetwork",
      },
      "OutAllowStorageHTTPSOutbound" = {
        access             = "Allow",
        priority           = 1040,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "VirtualNetwork",
        dst_address_prefix = "Storage.${var.LOCATION}",
      },
      # "AllowVertica5433Outbound" = {
      #   access             = "Allow",
      #   priority           = 108,
      #   protocol           = "Tcp",
      #   port               = "5433",
      #   src_address_prefix = "VirtualNetwork",
      #   dst_address_prefix = "VirtualNetwork",
      # },
      "OutAllowAzureMonitorOutbound" = {
        access             = "Allow",
        priority           = 1050,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "VirtualNetwork",
        dst_address_prefix = "AzureMonitor",
      },
      "OutAllowAzureMonitorRequisiteOutbound" = {
        access             = "Allow",
        priority           = 1060,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "VirtualNetwork",
        dst_address_prefix = "GuestAndHybridManagement",
      }
    }

    "${local.subnet_key_names.aks_aml}" = {
      "OutAllowPortHTTPSOutbound" = {
        access             = "Allow",
        priority           = 1000,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "AzureMachineLearning",
        dst_address_prefix = "VirtualNetwork",
      },
      "OutAllowFrontDoorPortHTTPSOutbound" = {
        access             = "Allow",
        priority           = 1010,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "AzureMachineLearning",
        dst_address_prefix = "AzureFrontDoor.Frontend",
      },
      "OutAllowPort5831Outbound" = {
        access             = "Allow",
        priority           = 1020,
        protocol           = "Udp",
        port               = "5831",
        src_address_prefix = "AzureMachineLearning",
        dst_address_prefix = "VirtualNetwork",
      },
      "OutAllowBatchNodeHTTPSOutbound" = {
        access             = "Allow",
        priority           = 1030,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "AzureMachineLearning",
        dst_address_prefix = "BatchNodeManagement",
      },
      "OutAllowStorageHTTPSOutbound" = {
        access             = "Allow",
        priority           = 1040,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "AzureMachineLearning",
        dst_address_prefix = "Storage.${var.LOCATION}",
      },
      "OutAllowKeyVaultHTTPSOutbound" = {
        access             = "Allow",
        priority           = 1050,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "AzureMachineLearning",
        dst_address_prefix = "AzureKeyVault.${var.LOCATION}",
      },
      "OutAllowADHTTPSOutbound" = {
        access             = "Allow",
        priority           = 1060,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "AzureMachineLearning",
        dst_address_prefix = "AzureActiveDirectory",
      },
      "OutAllowARMHTTPSOutbound" = {
        access             = "Allow",
        priority           = 1070,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "AzureMachineLearning",
        dst_address_prefix = "AzureResourceManager",
      },
      "OutAllowACRHTTPSOutbound" = {
        access             = "Allow",
        priority           = 1080,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "AzureMachineLearning",
        dst_address_prefix = "AzureContainerRegistry.${var.LOCATION}",
      },
      "OutAllowFrontDoorFirstPartyHTTPSOutbound" = {
        access             = "Allow",
        priority           = 1090,
        protocol           = "Tcp",
        port               = "443",
        src_address_prefix = "AzureMachineLearning",
        dst_address_prefix = "AzureFrontDoor.FirstParty",
      },
      "OutAllowPort8787Outbound" = {
        access             = "Allow",
        priority           = 1100,
        protocol           = "Tcp",
        port               = "8787",
        src_address_prefix = "AzureMachineLearning",
        dst_address_prefix = "VirtualNetwork",
      },
      "OutAllowPort18881Outbound" = {
        access             = "Allow",
        priority           = 1110,
        protocol           = "Tcp",
        port               = "18881",
        src_address_prefix = "AzureMachineLearning",
        dst_address_prefix = "VirtualNetwork",
      }
      # "AllowVertica5433Outbound" = {
      #   access             = "Allow",
      #   priority           = 113,
      #   protocol           = "Tcp",
      #   port               = "5433",
      #   src_address_prefix = "AzureMachineLearning",
      #   dst_address_prefix = "VirtualNetwork",
      # }
    }
  }
}