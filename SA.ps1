# Login to Azure
Connect-AzAccount

# List of subscription IDs to exclude
$excludedSubs = @(
)

# Get all subscriptions excluding the above
$subscriptions = Get-AzSubscription | Where-Object { $_.Id -notin $excludedSubs }

# Initialize array to hold results
$results = @()

foreach ($sub in $subscriptions) {
    Write-Host "`nProcessing subscription: $($sub.Name) [$($sub.Id)]" -ForegroundColor Cyan
    Set-AzContext -SubscriptionId $sub.Id -ErrorAction Stop | Out-Null

    try {
        $storageAccounts = Get-AzStorageAccount
    }
    catch {
        Write-Warning "Could not retrieve storage accounts for subscription $($sub.Name)"
        continue
    }

    foreach ($sa in $storageAccounts) {
        $props = $sa.StorageAccountProperties

        # Default values in case properties are missing
        $allowSharedKeyAccess    = $null
        $allowBlobPublicAccess   = $null
        $defaultToOAuthAuth      = $null

        # Safely access properties
        if ($props.PSObject.Properties.Name -contains 'AllowSharedKeyAccess') {
            $allowSharedKeyAccess = $props.AllowSharedKeyAccess
        }

        if ($props.PSObject.Properties.Name -contains 'AllowBlobPublicAccess') {
            $allowBlobPublicAccess = $props.AllowBlobPublicAccess
        }

        if ($props.PSObject.Properties.Name -contains 'DefaultToOAuthAuthentication') {
            $defaultToOAuthAuth = $props.DefaultToOAuthAuthentication
        }

        $results += [PSCustomObject]@{
            SubscriptionName            = $sub.Name
            SubscriptionId              = $sub.Id
            ResourceGroup               = $sa.ResourceGroupName
            StorageAccountName          = $sa.StorageAccountName
            Location                    = $sa.Location
            AllowSharedKeyAccess        = $allowSharedKeyAccess
            AllowBlobPublicAccess       = $allowBlobPublicAccess
            DefaultToMicrosoftEntraAuth = $defaultToOAuthAuth
            Kind                        = $sa.Kind
            Sku                         = $sa.Sku.Name
        }
    }
}

# Output file path
$outputFilePath = "$PSScriptRoot\StorageAccountAccessReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

# Export results to CSV
$results | Export-Csv -Path $outputFilePath -NoTypeInformation

Write-Host "`n✅ Report generated: $outputFilePath" -ForegroundColor Green
