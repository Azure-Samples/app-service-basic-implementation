/*
  Deploy a web app with a managed identity, diagnostic, and a private endpoint
*/

@description('This is the base name for each Azure resource name (3-6 chars)')
@minLength(3)
@maxLength(6)
param baseName string

@description('The resource group location')
param location string = resourceGroup().location

// existing resource name params 
param logWorkspaceName string

@secure()
param sqlConnectionString string

// variables
var appName = 'app-${baseName}'
var appServicePlanName = 'asp-${appName}${uniqueString(subscription().subscriptionId)}'
var appServiceManagedIdentityName = 'id-${appName}'

var appServicePlanStandardSku = 'Standard'
var appServicePlanSettings = {
  Standard: {
    name: 'S1'
    capacity: 1
  }
}


// ---- Existing resources ----
resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' existing = {
  name: logWorkspaceName
}

// ---- Web App resources ----

// Managed Identity for App Service
resource appServiceManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: appServiceManagedIdentityName
  location: location
}

//App service plan
resource appServicePlan 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: appServicePlanName
  location: location
  sku: appServicePlanSettings[appServicePlanStandardSku]
  properties: {
    zoneRedundant: false
  }
  kind: 'app'
}

// Web App
resource webApp 'Microsoft.Web/sites@2025-03-01' = {
  name: appName
  location: location
  kind: 'app'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appServiceManagedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: false
    keyVaultReferenceIdentity: appServiceManagedIdentity.id
    hostNamesDisabled: false
    siteConfig: {
      vnetRouteAllEnabled: false
      http20Enabled: true
      publicNetworkAccess: 'Enabled'
      alwaysOn: true
    }
  }
}

// App Settings
resource appsettings 'Microsoft.Web/sites/config@2025-03-01' = {
  name: 'appsettings'
  parent: webApp
  properties: {
    AZURE_SQL_CONNECTIONSTRING: sqlConnectionString
  }
}

// App service plan diagnostic settings
resource appServicePlanDiagSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${appServicePlan.name}-diagnosticSettings'
  scope: appServicePlan
  properties: {
    workspaceId: logWorkspace.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

//Web App diagnostic settings
resource webAppDiagSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${webApp.name}-diagnosticSettings'
  scope: webApp
  properties: {
    workspaceId: logWorkspace.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        categoryGroup: null
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        categoryGroup: null
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        categoryGroup: null
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('The name of the app service plan.')
output appServicePlanName string = appServicePlan.name

@description('The name of the web app.')
output appName string = webApp.name

@description('User identity client id.')
output appServiceIdentity string = appServiceManagedIdentity.properties.clientId

@description('User identity subscription id.')
output appServiceIdentitySubscriptionId string = subscription().subscriptionId

@description('WebApp resource id.')
output appServiceResourceId string = webApp.id
