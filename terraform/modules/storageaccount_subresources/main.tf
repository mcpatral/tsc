resource "azurerm_storage_container" "container" {
  for_each = {
    for key, value in var.containers :
    key => value
    #TODO remove "|| var.nfsv3_enabled == true" in the conditional when Terraform allows datalake filesystem creation with nfsv3 
    if var.is_hns_enabled == false || var.nfsv3_enabled == true
  }
  name                  = each.key
  storage_account_name  = var.storage_account_name
  container_access_type = local.container_access_type
}

resource "azurerm_storage_data_lake_gen2_filesystem" "fs" {
  for_each = {
    for key, value in var.containers :
    key => value
    #TODO remove "&& var.nfsv3_enabled == false" in the conditional when Terraform allows datalake filesystem creation with nfsv3 
    if var.is_hns_enabled == true && var.nfsv3_enabled == false
  }
  name               = each.key
  storage_account_id = var.storage_account_id
  ace {
    scope       = "access"
    type        = "user"
    permissions = "rwx"
  }
  ace {
    scope       = "access"
    type        = "group"
    permissions = "---"
  }
  ace {
    scope       = "access"
    type        = "other"
    permissions = "--x"
  }
}

resource "azurerm_storage_data_lake_gen2_path" "parent_folder" {
  for_each = {
    for obj in local.storage_data_lake_gen2_parent_path :
    obj.key => obj
    if var.is_hns_enabled == true
  }
  path = each.value.path
  #TODO remove azurerm_storage_container from filesystem_name parameter when Terraform allows datalake filesystem creation with nfsv3
  filesystem_name    = try(azurerm_storage_data_lake_gen2_filesystem.fs[each.value.container_key].name, azurerm_storage_container.container[each.value.container_key].name)
  storage_account_id = var.storage_account_id
  resource           = "directory"

  dynamic "ace" {
    for_each = each.value.acls != null ? each.value.acls : {}
    content {
      scope       = "access"
      type        = "user"
      id          = ace.value[0]
      permissions = ace.value[1]
    }
  }

  dynamic "ace" {
    for_each = each.value.acls != null ? each.value.acls : {}
    content {
      scope       = "default"
      type        = "user"
      id          = ace.value[0]
      permissions = ace.value[1]
    }
  }

  ace {
    scope       = "access"
    type        = "user"
    permissions = "rwx"
  }

  ace {
    scope       = "default"
    type        = "user"
    permissions = "rwx"
  }

  ace {
    scope       = "access"
    type        = "group"
    permissions = "---"
  }

  ace {
    scope       = "default"
    type        = "group"
    permissions = "---"
  }

  ace {
    scope       = "access"
    type        = "other"
    permissions = "--x"
  }

  ace {
    scope       = "default"
    type        = "other"
    permissions = "--x"
  }

  ace {
    scope       = "access"
    type        = "mask"
    permissions = "rwx"
  }

  ace {
    scope       = "default"
    type        = "mask"
    permissions = "rwx"
  }
}

resource "azurerm_storage_data_lake_gen2_path" "folder" {
  for_each = {
    for obj in local.storage_data_lake_gen2_path :
    obj.key => obj
    if var.is_hns_enabled == true
  }
  path = each.value.path
  #TODO remove azurerm_storage_container from filesystem_name parameter when Terraform allows datalake filesystem creation with nfsv3
  filesystem_name    = try(azurerm_storage_data_lake_gen2_filesystem.fs[each.value.container_key].name, azurerm_storage_container.container[each.value.container_key].name)
  storage_account_id = var.storage_account_id
  resource           = "directory"
  depends_on         = [
    azurerm_storage_data_lake_gen2_path.parent_folder
  ]

  dynamic "ace" {
    for_each = each.value.acls != null ? each.value.acls : {}
    content {
      scope       = "access"
      type        = "user"
      id          = ace.value[0]
      permissions = ace.value[1]
    }
  }

  dynamic "ace" {
    for_each = each.value.acls != null ? each.value.acls : {}
    content {
      scope       = "default"
      type        = "user"
      id          = ace.value[0]
      permissions = ace.value[1]
    }
  }
  
  ace {
    scope       = "access"
    type        = "user"
    permissions = "rwx"
  }
  
  ace {
    scope       = "default"
    type        = "user"
    permissions = "rwx"
  }
  
  ace {
    scope       = "access"
    type        = "group"
    permissions = "---"
  }
  
  ace {
    scope       = "default"
    type        = "group"
    permissions = "---"
  }
  
  ace {
    scope       = "access"
    type        = "other"
    permissions = "--x"
  }
  
  ace {
    scope       = "default"
    type        = "other"
    permissions = "--x"
  }
  
  ace {
    scope       = "access"
    type        = "mask"
    permissions = "rwx"
  }
  
  ace {
    scope       = "default"
    type        = "mask"
    permissions = "rwx"
  }
}