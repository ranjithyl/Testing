# Define AWS regions to check for certificates
$listofawsregions = @("us-west-2", "us-east-2")

# Define output CSV file path
$reportPath = "D:\Reports\ACM_Certificate_Report.csv"

# Initialize an array to store certificate details
$certReport = @()

# Loop through each region
ForEach ($awsRegion in $listofawsregions) {
    Write-Host "********** Checking Certificates in $awsRegion **********"

    # Retrieve the list of certificate ARNs in the region
    $certificates = Get-ACMCertificateList -Region $awsRegion

    # If certificates exist, retrieve their details
    If ($certificates.CertificateSummaryList.Count -gt 0) {
        ForEach ($cert in $certificates.CertificateSummaryList) {
            $certDetails = Get-ACMCertificateDetail -CertificateArn $cert.CertificateArn -Region $awsRegion

            # Store the certificate details in an object
            $certObject = [PSCustomObject]@{
                Region       = $awsRegion
                DomainName   = $certDetails.DomainName
                Status       = $certDetails.Status
                Issuer       = $certDetails.Issuer
                ValidFrom    = $certDetails.NotBefore
                ValidUntil   = $certDetails.NotAfter
                Type         = $certDetails.Type
                InUseBy      = ($certDetails.InUseBy -join ', ')  # Convert array to a string
            }

            # Add the object to the report array
            $certReport += $certObject
        }
    } else {
        Write-Host "No certificates found in $awsRegion"
    }
}

# Export the collected data to a CSV file
$certReport | Export-Csv -Path $reportPath -NoTypeInformation -Force

Write-Host "ACM Certificate Report saved to: $reportPath" -ForegroundColor Green
