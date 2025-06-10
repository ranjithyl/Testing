# Step 1: Login to Azure
az login

# Step 2: Read storage account names from a file
$filePath = Read-Host "Enter the filepath containing Storage Accounts"
if (-not (Test-Path $filePath)) {
    Write-Host "File not found at path: $filePath" -ForegroundColor Red
    exit
}
$storageAccounts = Get-Content $filePath

# Step 3: Validate and collect only existing storage accounts
$validAccounts = @{}

foreach ($storageAccount in $storageAccounts) {
    $storageAccount = $storageAccount.Trim()
    if ([string]::IsNullOrWhiteSpace($storageAccount)) { continue }

    Write-Host "`nProcessing Storage Account: $storageAccount"

    $accountInfoRaw = az storage account show --name $storageAccount --output json 2>$null
    if (-not $accountInfoRaw) {
        Write-Host "Storage Account $storageAccount does not exist or could not be retrieved. Skipping..." -ForegroundColor Red
        continue
    }

    try {
        $accountInfo = $accountInfoRaw | ConvertFrom-Json
        if ($accountInfo -and $accountInfo.name -eq $storageAccount) {
            $validAccounts[$storageAccount] = $accountInfo
            Write-Host "Current Settings for $storageAccount:"
            Write-Host "Allow Blob Public Access: $($accountInfo.allowBlobPublicAccess)" -ForegroundColor Yellow
        }
        else {
            Write-Host "Invalid data received for $storageAccount. Skipping..." -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error parsing account info for $storageAccount. Skipping..." -ForegroundColor Red
    }
}

# Step 4: Prompt user for confirmation before disabling the setting
$confirmation = Read-Host "`nDo you want to disable 'Allow Blob anonymous access' for all valid storage accounts? (yes/no)"
if ($confirmation -ne "yes") {
    Write-Host "Operation cancelled by user."
    exit
}

# Step 5: Disable 'Allow Blob anonymous access' for valid storage accounts
foreach ($storageAccount in $validAccounts.Keys) {
    $accountInfo = $validAccounts[$storageAccount]

    if ($accountInfo.allowBlobPublicAccess -eq $true) {
        Write-Host "`nDisabling 'Allow Blob anonymous access' for $storageAccount..." -ForegroundColor Yellow
        $result = az storage account update --name $storageAccount --allow-blob-public-access false --output none 2>$null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "'Allow Blob anonymous access' has been disabled for $storageAccount." -ForegroundColor Green
        }
        else {
            Write-Host "Failed to disable setting for $storageAccount." -ForegroundColor Red
        }
    }
    else {
        Write-Host "'Allow Blob anonymous access' is already disabled for $storageAccount." -ForegroundColor Green
    }
}
