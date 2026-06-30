/*
  Deploy a SQL server with a sample database, a private endpoint and a private DNS zone
*/
@description('This is the base name for each Azure resource name (3-6 chars)')
param baseName string

@description('The resource group location')
param location string = resourceGroup().location

@description('The administrator username of the SQL server')
param sqlAdministratorLogin string

@description('The administrator password of the SQL server.')
@secure()
param sqlAdministratorLoginPassword string

// variables
var sqlServerName = 'sql-${baseName}'
var sampleSqlDatabaseName = 'sqldb-adventureworks'
var sqlConnectionString = 'Server=tcp:${sqlServerName}${environment().suffixes.sqlServerHostname},1433;Initial Catalog=${sampleSqlDatabaseName};Persist Security Info=False;User ID=${sqlAdministratorLogin};Password=${sqlAdministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'

// ---- Sql resources ----

// sql server
resource sqlServer 'Microsoft.Sql/servers@2025-01-01' = {
  name: sqlServerName
  location: location
  tags: {
    displayName: sqlServerName
  }
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }
}

resource sqlServer_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2025-01-01' = {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlServer
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

//database
resource slqDatabase 'Microsoft.Sql/servers/databases@2025-01-01' = {
  name: sampleSqlDatabaseName
  parent: sqlServer
  location: location

  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  tags: {
    displayName: sampleSqlDatabaseName
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 104857600
    sampleName: 'AdventureWorksLT'
  }
}

@description('The connection string to the sample database.')
output sqlConnectionString string = sqlConnectionString

@description('Database Resource ID')
output databaseResourceId string = slqDatabase.id
