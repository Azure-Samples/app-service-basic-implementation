# App Services Basic Architecture

This repository contains the Bicep code to deploy an Azure App Services basic architecture.

## Deploy

The following are prerequisites.

### Prerequisites

1. Ensure you have an [Azure Account](https://azure.microsoft.com/pricing/purchase-options/azure-account?cid=msft_learn)
1. Ensure you have the [Azure CLI installed](https://learn.microsoft.com/cli/azure/install-azure-cli)
1. Ensure you have the [az Bicep tools installed](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install)

Use the following to deploy the infrastructure.

### Deploy the infrastructure

The following steps are required to deploy the infrastructure from the command line.

1. In your command-line tool where you have the Azure CLI and Bicep installed, navigate to the root directory of this repository.

```bash
  git clone https://github.com/Azure-Samples/app-service-basic-implementation.git
  cd app-service-basic-implementation
```

1. Log in and set the subscription if needed

```bash
  az login 
  # az account set --subscription xxxxx
```

1. Run the following command to create a resource group and deploy the infrastructure. Make sure:

   - The BASE_NAME contains only lowercase letters and is between 3 and 6 characters. All resources will be named using this base name.
   - You choose a valid resource group name

```bash
   LOCATION=westus3
   BASE_NAME=<base-resource-name (between 3 and 6 characters)>
  
   SQL_ADMINISTRATOR_LOGIN="sqlAdministrator"
   # Note: Take into account that SQL databases enforce [password complexity](https://learn.microsoft.com/sql/relational-databases/security/password-policy?view=sql-server-ver16#password-complexity)
   # Generate a strong password meeting SQL complexity requirements: minimum 8 characters, at least one uppercase, one lowercase, one digit, and one special character
   SQL_ADMINISTRATOR_LOGIN_PASSWORD='<your-secure-password>'
   # This password must meet Azure SQL Database password complexity requirements and must not be hardcoded in scripts or version control.

   RESOURCE_GROUP=rg-app-service-${LOCATION}
   az group create --location $LOCATION --resource-group $RESOURCE_GROUP

   # [This takes about ten minutes.]
   az deployment group create --template-file ./infra-as-code/bicep/main.bicep \
     --resource-group $RESOURCE_GROUP \
     --parameters baseName=$BASE_NAME sqlAdministratorLogin=$SQL_ADMINISTRATOR_LOGIN sqlAdministratorLoginPassword=$SQL_ADMINISTRATOR_LOGIN_PASSWORD
```

### Publish the web app

Deploy zip file from [App Service Sample Workload](https://github.com/Azure-Samples/app-service-sample-workload)

```bash
APPSERVICE_NAME=app-$BASE_NAME
az webapp deploy --resource-group $RESOURCE_GROUP --name $APPSERVICE_NAME --type zip --src-url https://raw.githubusercontent.com/Azure-Samples/app-service-sample-workload/main/website/SimpleWebApp.zip
```

### Validate the web app

Retrieve the web application URL and open it in your default web browser.

```bash
APPSERVICE_URL=https://$APPSERVICE_NAME.azurewebsites.net
echo $APPSERVICE_URL
```

## Optional Step: Service Connector

This implementation uses a classic connection string to access the database; the connection string is stored in an App Service setting called "AZURE_SQL_CONNECTIONSTRING". You can use [Service Connector](https://learn.microsoft.com/azure/service-connector/overview) to configure the connection. Service Connector makes it easy to establish and maintain connections between services, reducing manual configuration and maintenance overhead. You can use Service Connector from the Azure portal, the Azure CLI, or even Visual Studio to create connections.

You must open [Azure Cloud Shell in bash mode](https://learn.microsoft.com/azure/cloud-shell/quickstart) to execute these CLI commands. The commands need to connect to the database, and only Azure services are allowed in the current configuration.

```bash
   # Set variables on Azure Cloud Shell
   LOCATION=westus3
   BASE_NAME=<base-resource-name>
   RESOURCE_GROUP=<resource-group-name>
   APPSERVICE_NAME=app-$BASE_NAME
   RESOURCEID_DATABASE=$(az deployment group show -g $RESOURCE_GROUP -n databaseDeploy --query properties.outputs.databaseResourceId.value -o tsv)
   RESOURCEID_WEBAPP=$(az deployment group show -g $RESOURCE_GROUP -n webappDeploy --query properties.outputs.appServiceResourceId.value -o tsv)
   USER_IDENTITY_WEBAPP_CLIENTID=$(az deployment group show -g $RESOURCE_GROUP -n webappDeploy --query properties.outputs.appServiceIdentity.value -o tsv)
   USER_IDENTITY_WEBAPP_SUBSCRIPTION=$(az deployment group show -g $RESOURCE_GROUP -n webappDeploy --query properties.outputs.appServiceIdentitySubscriptionId.value -o tsv)
   
   # Delete the current App Service connection string; you can verify that the key was deleted from the Azure portal
   az webapp config appsettings delete --name $APPSERVICE_NAME --resource-group $RESOURCE_GROUP --setting-names AZURE_SQL_CONNECTIONSTRING

   # Install the service connector CLI extension
   az extension add --name serviceconnector-passwordless --upgrade

   # Invoke the service connection command
   az webapp connection create sql --connection sql_adventureconn --source-id $RESOURCEID_WEBAPP --target-id $RESOURCEID_DATABASE --client-type dotnet --user-identity client-id=$USER_IDENTITY_WEBAPP_CLIENTID subs-id=$USER_IDENTITY_WEBAPP_SUBSCRIPTION
   # The AZURE_SQL_CONNECTIONSTRING is recreated, but the connection string now includes "Authentication=ActiveDirectoryManagedIdentity"
   
```

## Clean Up

After you have finished exploring the AppService reference implementation, it is recommended that you delete Azure resources to prevent undesired costs from accruing.

```bash
az group delete --name $RESOURCE_GROUP -y
```
## Contributions

Please see our [contributor guide](./CONTRIBUTING.md).

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact <opencode@microsoft.com> with any additional questions or comments.
