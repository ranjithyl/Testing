# Import AWS Modules
Write-Host "Importing AWS Modules... Wait for a min" -ForegroundColor Green
Import-Module AWSPowerShell -ErrorAction Stop

# Get user inputs
$InstanceId = Read-Host "Enter the EC2 Instance ID"
$DomainName = Read-Host "Enter Domain Name to Join"

# Get the instance Name from AWS tags
$InstanceName = (aws ec2 describe-tags --filters "Name=resource-id,Values=$InstanceId" "Name=key,Values=Name" --query "Tags[0].Value" --output text)

# If no name tag found, set default Name
if (-not $InstanceName) {
    $InstanceName = "EC2-$InstanceId"
}

# Get the public IP or private IP of the instance
$Instance = Get-EC2Instance -InstanceId $InstanceId
$PublicIp = $Instance.Instances[0].PublicIpAddress
$PrivateIp = $Instance.Instances[0].PrivateIpAddress

# Use the private IP if public IP is not available
$IpAddress = if ($PublicIp) { $PublicIp } else { $PrivateIp }

# Create a remote PowerShell session to the EC2 instance
$Session = New-PSSession -ComputerName $IpAddress -Credential (Get-Credential)

# Rename the computer on the remote instance
Invoke-Command -Session $Session -ScriptBlock {
    param($InstanceName)
    Rename-Computer -NewName $InstanceName -Force -PassThru
    Restart-Computer -Force
} -ArgumentList $InstanceName

# Wait for the instance to restart
Start-Sleep -Seconds 60

# Check if the server is already part of a Domain
$isDomainJoined = Invoke-Command -Session $Session -ScriptBlock {
    (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
}

if ($isDomainJoined) {
    Write-Host "This server is already part of a domain. Aborting domain join." -ForegroundColor Red
    exit
}

# Domain Credentials
$DomainUser = Read-Host "Enter Domain Admin Username (Format: DOMAIN\user)"
$DomainPassword = Read-Host "Enter Domain Admin Password" -AsSecureString
$Credential = New-Object System.Management.Automation.PSCredential($DomainUser, $DomainPassword)

# Join the Domain
try {
    Write-Host "Attempting to join the domain $DomainName..." -ForegroundColor Yellow
    Invoke-Command -Session $Session -ScriptBlock {
        param($DomainName, $Credential)
        Add-Computer -DomainName $DomainName -Credential $Credential -ErrorAction Stop
        Restart-Computer -Force
    } -ArgumentList $DomainName, $Credential
    Write-Host "Successfully joined the domain. Restarting the computer..." -ForegroundColor Green
} catch {
    Write-Host "Failed to join the domain: $_" -ForegroundColor Red
    exit
}

Write-Host "Instance $InstanceId successfully renamed and joined to $DomainName" -ForegroundColor Green

# Close the remote session
Remove-PSSession -Session $Session
