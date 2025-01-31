$Host.UI.RawUI.WindowTitle = "Active Directory Update"
Write-Host "Running AD_Update.ps1 at $(Get-Date)"-ForegroundColor Cyan

function Enter_to_Exit {
    Read-Host "Press Enter to exit"
    Exit
}

# check if the Active Directory module is installed
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "ERROR - The Active Directory module is not installed. Please install it before running this script." -ForegroundColor Red
    Enter_to_Exit
    exit
}

# Get the list of domains
$domains = Get-ADForest | Select-Object -ExpandProperty Domains

# Write the domains to the domains.txt file if they aren't already there
$domains | ForEach-Object {
    $domain = $_
    $existing_domains = (Get-Content -Path "domains.txt" | Where-Object { $_ -notmatch "^#" })
    if ($existing_domains -notcontains $domain) {
        Add-Content -Path "domains.txt" -Value $domain
    }
}

Write-Output "The domains list has been updated successfully."
Enter_to_Exit