<#
.SYNOPSIS
    Deletes multiple AWS EBS snapshots from a list of snapshot IDs.
.DESCRIPTION
    This script reads snapshot IDs from a file, validates them, asks for confirmation,
    and then deletes them while tracking progress and results.
.NOTES
    Requires AWS PowerShell module and appropriate IAM permissions.
#>

Write-Host "Importing AWS PowerShell modules..." -ForegroundColor Green
Import-Module AWSPowerShell -ErrorAction Stop

# Get snapshot IDs from file
$filePath = Read-Host "Enter the filepath containing snapshot IDs"
if (-not (Test-Path $filePath)) {
    Write-Host "File not found: $filePath" -ForegroundColor Red
    exit
}

# Read and validate snapshot IDs
$snapshotIds = Get-Content $filePath | Where-Object { $_ -match '^snap-[a-f0-9]{8,}$' }

if (-not $snapshotIds) {
    Write-Host "No valid EBS snapshot IDs found in the file." -ForegroundColor Yellow
    exit
}

# Display snapshots to be deleted
Write-Host "Found the following EBS snapshots to delete:" -ForegroundColor Cyan
$snapshotIds | ForEach-Object { Write-Host "- $_" }

# Confirm deletion
$confirm = Read-Host "Are you sure you want to delete these $($snapshotIds.Count) snapshots? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit
}

# Delete snapshots with progress tracking
$success = 0
$failed = 0

foreach ($snap in $snapshotIds) {
    try {
        Write-Host "Deleting $snap..." -NoNewline
        Remove-EC2Snapshot -SnapshotId $snap -Force -ErrorAction Stop
        Write-Host " [DONE]" -ForegroundColor Green
        $success++
    } catch {
        Write-Host " [FAILED: $_]" -ForegroundColor Red
        $failed++
    }
}

# Show results
Write-Host "`nDeletion completed" -ForegroundColor Cyan
Write-Host "Successfully deleted: $success" -ForegroundColor Green
Write-Host "Failed to delete: $failed" -ForegroundColor Red

if ($failed -gt 0) {
    Write-Host "Note: Snapshots may fail to delete if they're in use or you don't have permissions." -ForegroundColor Yellow
}
