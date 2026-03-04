# Set variable values
$subscription_id = "813e007a-50d7-49cf-9495-ba7e4125aeae"
$resource_group = "ResourceGroup1"
$location = "Sweden Central"
$expiry_date = "2028-01-01T00:00:00Z"

# Get random numbers to create unique resource names
$unique_id = Get-Random -Minimum 1 -Maximum 99999

# Check if resource group exists, create if it doesn't
Write-Host "Checking resource group..."
$rg_exists = az group exists --name "$resource_group" --subscription "$subscription_id"
if ($rg_exists -eq "false") {
    Write-Host "Creating resource group..."
    az group create --name "$resource_group" --location "$location" --subscription "$subscription_id"
}

# Create a storage account in your Azure resource group
Write-Host "Creating storage..."
Write-Host "Storage account name: ai102form$unique_id"
az storage account create --name "ai102form$unique_id" --subscription "$subscription_id" --resource-group "$resource_group" --location "$location" --sku Standard_LRS --encryption-services blob --default-action Allow --allow-blob-public-access true
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to create storage account"
    exit 1
}

Write-Host "Uploading files..."
# Get storage key to create a container in the storage account
$key_json = az storage account keys list --subscription "$subscription_id" --resource-group "$resource_group" --account-name "ai102form$unique_id" --query "[?keyName=='key1'].{keyName:keyName, permissions:permissions, value:value}" | ConvertFrom-Json
if (-not $key_json -or $key_json.Count -eq 0) {
    Write-Host "Error: Failed to retrieve storage account keys"
    exit 1
}
$AZURE_STORAGE_KEY = $key_json[0].value

# Create a container
az storage container create --account-name "ai102form$unique_id" --name sampleforms --public-access blob --auth-mode key --account-key "$AZURE_STORAGE_KEY" --output none

# Upload files from your local sample-forms folder to a container called sampleforms in the storage account
az storage blob upload-batch -d sampleforms -s ./sample-forms --account-name "ai102form$unique_id" --auth-mode key --account-key "$AZURE_STORAGE_KEY" --output none

# Set a variable value for future use
$STORAGE_ACCT_NAME = "ai102form$unique_id"

# Get a Shared Access Signature
$SAS_TOKEN = az storage container generate-sas --account-name "ai102form$unique_id" --name sampleforms --expiry "$expiry_date" --permissions rwl --account-key "$AZURE_STORAGE_KEY" --output tsv
if ($SAS_TOKEN) {
    $URI = "https://$STORAGE_ACCT_NAME.blob.core.windows.net/sampleforms?$SAS_TOKEN"
} else {
    Write-Host "Error: Failed to generate SAS token"
    exit 1
}

# Print the generated Shared Access Signature URI
Write-Host "-------------------------------------"
Write-Host "SAS URI: $URI"
