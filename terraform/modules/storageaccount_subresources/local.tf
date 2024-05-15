locals {
  container_access_type = "private"
  storage_data_lake_gen2_parent_path = flatten([
    for ckey, cvalue in var.containers : [
      for path, value in cvalue.parent_directories :
      {
        key           = "${ckey}_${path}"
        container_key = ckey
        path          = path
        acls          = value.acls
      }
    ]
  ])
  storage_data_lake_gen2_path = flatten([
    for ckey, cvalue in var.containers : [
      for path, value in cvalue.directories :
      {
        key           = "${ckey}_${path}"
        container_key = ckey
        path          = path
        acls          = value.acls
      }
    ]
  ])
}