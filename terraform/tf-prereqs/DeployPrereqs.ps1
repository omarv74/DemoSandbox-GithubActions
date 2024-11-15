# REQUIRES: Azure CLI

# REQUIRES: az login --use-device-code

$azSubscriptionName = 'ME-MngEnvMCAP986157-davillar-1'
$azSubscriptionId = (az account show --name $azSubscriptionName | ConvertFrom-Json).id #'e1f7b502-6ec4-4a45-be74-59f2587c55ec'
$tfBackendRGName = 'TerraformBackendMCAPS6157'
$tfBackendRGLocation = 'southcentralus'
$tfBackendStorageAccountName = 'satfbackendmcaps6157'
$tfBackendContainerName = 'tfstate'
$GHActionsDeploySPN = 'GitHub-Actions-Deploy'

az account set --subscription $azSubscriptionId

# Create a resource group and resources for the Terraform backend
az group create --name $tfBackendRGName --location $tfBackendRGLocation
az storage account create --name $tfBackendStorageAccountName --resource-group $tfBackendRGName --location $tfBackendRGLocation --sku Standard_LRS --encryption-services blob

# Get the storage account key
$tfBackendStorageAccountKey = (az storage account keys list --account-name $tfBackendStorageAccountName --resource-group $tfBackendRGName | ConvertFrom-Json)[0].value

# Create a blob container
az storage container create --name $tfBackendContainerName --account-name $tfBackendStorageAccountName --account-key $tfBackendStorageAccountKey

# Display the storage account name and container name AND the storage account key
Write-Output "Storage Account Name: $tfBackendStorageAccountName"
Write-Output "Container Name: $tfBackendContainerName"
Write-Output "Storage Account Key: $tfBackendStorageAccountKey"

# https://learn.microsoft.com/en-us/devops/deliver/iac-github-actions#use-terraform
# Setup Azure Identity for GitHub Actions
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$AzSubscriptionId" --name="$GHActionsDeploySPN"
# Get AppId property from the output
# Get the Service Principal Object Id
az ad sp show --id $GHActionsDeploySPN --query objectId -o tsv
# Get the Service Principal Object Id
az ad sp show --id $GHActionsDeploySPN --query appId -o tsv

# Add role "Storage Blob Data Contributor" to the service principal
az role assignment create --role "Storage Blob Data Contributor" --assignee $GHActionsDeploySPN --scope "/subscriptions/$AzSubscriptionId/resourceGroups/$tfBackendRGName/providers/Microsoft.Storage/storageAccounts/$tfBackendStorageAccountName"