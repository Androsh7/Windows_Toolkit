Clear-Host
Write-Host "----- Parsing Security Event Logs for Login Events -----" -ForegroundColor Cyan
$UserFilter = Read-Host "Enter the user you want to filter on (leave blank for all users)"
if ($UserFilter -eq "") { $UserFilter = "*"}
$LogAge = Read-Host "Enter the number of days to go back in the logs (default is 7)"
if ($LogAge -eq "") { $LogAge = 7 }
Write-Host "----- Querying Security logs for User ${UserFilter} in the past ${LogAge} days-----" -ForegroundColor Cyan
$CurrentDate = Get-Date

# Description: This script will parse the security event log for login events and display them in a readable format.
Get-WinEvent -LogName "security" | Where-Object {$_.Id -match "462[45]|472[34]|4740"} | ForEach-Object {
    # Build XML object
    $event_xml = [xml]$_.ToXml()

    # Filter by User Criteria
    $TargetUser = ($event_xml.Event.EventData.ChildNodes | Where-Object { $_.Name -eq "TargetUserName"}).InnerText
    $SubjectUser = ($event_xml.Event.EventData.ChildNodes | Where-Object { $_.Name -eq "SubjectUserName"}).InnerText
    if ($UserFilter -ne "*" -and $TargetUser -notcontains $UserFilter -and $SubjectUser -notcontains $UserFilter) { return }

    
    # Build remaining variables for events
    $TargetDomain = ($event_xml.Event.EventData.ChildNodes | Where-Object { $_.Name -eq "TargetDomainName"}).InnerText
    $SubjectDomain = ($event_xml.Event.EventData.ChildNodes | Where-Object { $_.Name -eq "SubjectDomainName"}).InnerText

    # enforce time constraints
    $TimeCreated = $_.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
    if ($(New-TimeSpan -Start $_.TimeCreated -End $CurrentDate).TotalDays -gt $LogAge) { break }

    # Ignore specific users
    switch ($TargetDomain) {
        "NT AUTHORITY" { $ignore = $true }
        "Window Manager" { $ignore = $true }
        "Font Driver Host" { $ignore = $true }
        Default { $ignore = $false }
    }

    if ($ignore) { return }

    # Event ID 4624 and 4625 (Login Success/Failure)
    if ($_.Id -match "462[45]") {

        # build IP address and port variables
        $IpAddress = ($event_xml.Event.EventData.ChildNodes | Where-Object { $_.Name -eq "IpAddress"}).InnerText
        $IpPort = ($event_xml.Event.EventData.ChildNodes | Where-Object { $_.Name -eq "IpPort"}).InnerText

        # special case for local accounts
        if ($IpAddress -eq "::1") { 
            $IpAddress = "127.0.0.1"
        }

        # Print to the screen
        if ($_.ID -eq 4624) { Write-Host "Login Successful - ${TimeCreated} - ${IpAddress}:${IpPort} --> ${TargetDomain}\${TargetUser}" -ForegroundColor Green } 
        else                { Write-Host "Login Failure    - ${TimeCreated} - ${IpAddress}:${IpPort} --> ${TargetDomain}\${TargetUser}" -ForegroundColor Red }
    }
    # Event ID 4723 and 4724 (Password Reset)
    elseif ($_.Id -match "472[34]") {

        $Status = ($event_xml.Event.EventData.ChildNodes | Where-Object { $_.Name -eq "Status"}).InnerText
        $StatusMessage = ""
        switch ($Status) {
            0x0 { $StatusMessage = "SUCCESS" }
            0xC000006A { $StatusMessage = "WRONG_PASSWORD" }
            0xC000006C { $StatusMessage = "PASSWORD_RESTRICTION" }
            0xC000006D { $StatusMessage = "LOGON_FAILURE" }
            0xC000006F { $StatusMessage = "ACCOUNT_RESTRICTION" }
            0xC0000070 { $StatusMessage = "INVALID_LOGON_HOURS" }
            0xC0000071 { $StatusMessage = "PASSWORD_EXPIRED" }
            0xC0000072 { $StatusMessage = "ACCOUNT_DISABLED" }
            0xC0000064 { $StatusMessage = "NO_SUCH_USER" }
            Default { $StatusMessage = "UNKNOWN" }
        }
        
        # Print to the screen  
        if ($_.ID -eq 4723) { Write-Host "User PW Reset    - ${SubjectDomain}\${SubjectUser} --> ${TargetDomain}\${TargetUser} - $StatusMessage" -ForegroundColor Yellow }
        else                { Write-Host "Admin PW Reset   - ${SubjectDomain}\${SubjectUser} --> ${TargetDomain}\${TargetUser} - $StatusMessage" -ForegroundColor Yellow }
    }
    elseif ($_.Id -eq 4740) {
        Write-Host "Account Lockout  - ${TimeCreated} - ${TargetDomain}\${TargetUser}" -ForegroundColor Blue
    }
}