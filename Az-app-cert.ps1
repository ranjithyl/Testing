# Get certificates associated with the web app
$certificates = Get-AzWebAppCertificate -ResourceGroupName $rgName -WebAppName $webAppName

# Initialize an array to store certificate details
$certificateData = @()

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

# Export to Excel
$certificateData | Export-Csv -Path "C:\My_Tasks\Automation\WebApps_Certificates_Report.csv" -NoTypeInformation

Write-Host "Report saved to: C:\My_Tasks\Automation\WebApps_Certificates_Report.csv" -ForegroundColor Greenss
