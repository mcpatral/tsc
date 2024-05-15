#High availability in Azure Database for PostgreSQL - Flexible Server, which includes:

# A) Availability zones. Flexible Server supports the following high availability configurations: 
# A.1) Zone-redundant: deploys a standby replica in a different zone with automatic failover capability.
# A.2) Zonal models: A standby replica server is automatically provisioned and managed in the same availability zone.
#HA is not supported for Burstable SKUs, such as B_Standard_B1ms.

# B) Cross-region resiliency with disaster recovery. There are two options:
# B.1) Geo-redundant backup and restore: provide the ability to restore your server in a different region in the event of a disaster. 
# When the server is configured with geo-redundant backup, the backup data and transaction logs are copied to the paired region asynchronously through storage replication.
# If your server is configured with geo-redundant backup, you can perform geo-restore in the paired region. 
# A new server is provisioned and recovered to the last available data that was copied to this region.
# https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-restore-server-portal#perform-geo-restore
# Currently, PITR of geo-redundant backups is not available.
#https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-backup-restore#geo-redundant-backup-and-restore
# B.2) Cross region read replicas: In the event of region failure you can perform disaster recovery operation by promoting your read replica to be a standalone read-writeable server. 
# Read replicas are updated asynchronously using PostgreSQL's physical replication technology, and may lag the primary. 
# Read replicas are supported in general purpose and memory optimized compute tiers.

#https://learn.microsoft.com/en-us/azure/reliability/reliability-postgresql-flexible-server
# Note: In this code, I will be using geo replication.
#https://azure.microsoft.com/en-us/pricing/details/postgresql/flexible-server/

module "postgresql" {
  source                       = "../modules/postgresql"
  psql_name                    = local.postgresql.name
  rg_name                      = local.enablers_tfstate_output.resource_group_name
  location                     = var.LOCATION
  tags                         = merge(local.common_tags, local.postgresql.tags)
  zone                         = var.POSTGRES_ZONE
  sku_name                     = local.postgresql.sku_name
  psql_admin_user              = local.postgresql.psql_admin_user
  psql_admin_pwd               = local.postgresql.psql_admin_pwd #TODO recheck how it will be easier to manage and rotate
  create_mode                  = local.postgresql.create_mode
  delegated_subnet_id          = local.postgresql.delegated_subnet_id
  private_dns_zone_id          = local.postgresql.private_dns_zone_id
  storage_mb                   = local.postgresql.storage_mb
  psql_version                 = local.postgresql.psql_version
  geo_redundant_backup_enabled = local.postgresql.geo_redundant_backup_enabled
  max_connections              = local.postgresql.max_connections

  #Database
  database_name = local.postgresql.database_name
  collation     = local.postgresql.collation
  charset       = local.postgresql.charset

  #Diagnostic Settings
  diagnostic_set_name = local.postgresql.diagnostic_set_name
  diagnostic_set_id   = local.postgresql.diagnostic_set_id

  principal_name = local.postgresql.principal_name
  object_id      = local.postgresql.object_id
  tenant_id      = local.postgresql.tenant_id
}