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

# Get credentials for the local EC2 instance
$LocalCredential = Get-Credential -Message "Enter local administrator credentials for the EC2 instance"

# Rename the computer (first session)
try {
    $Session = New-PSSession -ComputerName $IpAddress -Credential $LocalCredential -ErrorAction Stop
    
    Write-Host "Renaming computer to $InstanceName..." -ForegroundColor Yellow
    Invoke-Command -Session $Session -ScriptBlock {
        param($InstanceName)
        Rename-Computer -NewName $InstanceName -Force
    } -ArgumentList $InstanceName
    
    Write-Host "Restarting computer to apply name change..." -ForegroundColor Yellow
    Invoke-Command -Session $Session -ScriptBlock {
        Restart-Computer -Force
    }
    
    Remove-PSSession $Session
}
catch {
    Write-Host "Error during rename operation: $_" -ForegroundColor Red
    exit
}

# Wait for reboot and re-establish connection
Write-Host "Waiting for computer to reboot (90 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 90

# Recreate session after reboot
try {
    $Session = New-PSSession -ComputerName $IpAddress -Credential $LocalCredential -ErrorAction Stop
}
catch {
    Write-Host "Failed to reconnect after reboot: $_" -ForegroundColor Red
    Write-Host "Please verify the instance is back online and try again." -ForegroundColor Yellow
    exit
}

# Domain Credentials
$DomainUser = Read-Host "Enter Domain Admin Username (Format: DOMAIN\user)"
$DomainPassword = Read-Host "Enter Domain Admin Password" -AsSecureString
$DomainCredential = New-Object System.Management.Automation.PSCredential($DomainUser, $DomainPassword)

# Join the Domain
try {
    Write-Host "Attempting to join the domain $DomainName..." -ForegroundColor Yellow
    Invoke-Command -Session $Session -ScriptBlock {
        param($DomainName, $DomainCredential)
        Add-Computer -DomainName $DomainName -Credential $DomainCredential -ErrorAction Stop
        Write-Host "Successfully joined domain $DomainName. Restarting..." -ForegroundColor Green
        Restart-Computer -Force
    } -ArgumentList $DomainName, $DomainCredential
}
catch {
    Write-Host "Failed to join the domain: $_" -ForegroundColor Red
    exit
}
finally {
    if ($Session) { Remove-PSSession $Session }
}

Write-Host "Domain join process completed successfully. The computer will restart to complete the process." -ForegroundColor Green
