@description('The location in which all resources should be deployed.')
param location string = resourceGroup().location

@description('This is the base name for each Azure resource name (3-6 chars)')
@minLength(3)
@maxLength(6)
param baseName string

@description('The administrator username of the SQL server')
param sqlAdministratorLogin string

@description('The administrator password of the SQL server.')
@secure()
param sqlAdministratorLoginPassword string

var logWorkspaceName = 'log-${baseName}'

// ---- Log Analytics workspace ----
resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' = {
  name: logWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Deploy a SQL server with a sample database, a private endpoint and a DNS zone
module databaseModule 'database.bicep' = {
  name: 'databaseDeploy'
  params: {
    location: location
    baseName: baseName
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
  }
}

// Deploy a web app
module webappModule 'webapp.bicep' = {
  name: 'webappDeploy'
  params: {
    location: location
    baseName: baseName
    logWorkspaceName: logWorkspace.name
    sqlConnectionString: databaseModule.outputs.sqlConnectionString
  }
}
