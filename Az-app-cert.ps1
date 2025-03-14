# Connect to Azure
Connect-AzAccount
$subscriptionId = "50bfd09a-e376-4e72-86d9-6a493b0e1184"
Set-AzContext -Subscription $subscriptionId

# Get all resource groups in the subscription
$resourceGroups = Get-AzResourceGroup

# Initialize data collection array
$certificateData = @()

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

# Export to Excel
$certificateData | Export-Csv -Path "C:\My_Tasks\Automation\WebApps_Certificates_Report.csv" -NoTypeInformation

Write-Host "Report saved to: C:\My_Tasks\Automation\WebApps_Certificates_Report.csv" -ForegroundColor Green
