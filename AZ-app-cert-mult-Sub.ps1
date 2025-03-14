# Connect to Azure
Connect-AzAccount

# Path to the text file containing subscription IDs
$subscriptionFilePath = "C:\My_Tasks\Automation\subscriptions.txt"

# Read subscription IDs from the text file
$subscriptionIds = Get-Content -Path $subscriptionFilePath

# Initialize data collection array
$certificateData = @()

# Loop through each subscription
foreach ($subscriptionId in $subscriptionIds) {
    # Set the context to the current subscription
    Set-AzContext -Subscription $subscriptionId

    # Get all resource groups in the current subscription
    $resourceGroups = Get-AzResourceGroup

    # Loop through each resource group
    foreach ($rg in $resourceGroups) {
        $rgName = $rg.ResourceGroupName

        # Get all Web Apps in the resource group
        $webApps = Get-AzWebApp -ResourceGroupName $rgName

        # Loop through each Web App
        foreach ($webApp in $webApps) {
            $webAppName = $webApp.Name
            $location = $webApp.Location

            # Get certificates associated with the Web App
            $certificates = Get-AzWebAppCertificate -ResourceGroupName $rgName -WebAppName $webAppName

            # Collect details for each certificate
            foreach ($certificate in $certificates) {
                $certificateInfo = [PSCustomObject]@{
                    "SubscriptionID" = $subscriptionId
                    "ResourceGroup" = $rgName
                    "WebAppName" = $webAppName
                    "Location" = $location
                    "CertificateName" = $certificate.Name
                    "Thumbprint" = $certificate.Thumbprint
                    "ExpirationDate" = $certificate.ExpirationDate
                    "Issuer" = $certificate.Issuer
                    "Subject" = $certificate.Subject
                }

                $certificateData += $certificateInfo
            }
        }
    }
}

# Export to Excel
$certificateData | Export-Csv -Path "C:\My_Tasks\Automation\WebApps_Certificates_Report.csv" -NoTypeInformation

Write-Host "Report saved to: C:\My_Tasks\Automation\WebApps_Certificates_Report.csv" -ForegroundColor Green
