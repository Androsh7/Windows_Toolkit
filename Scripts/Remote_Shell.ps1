$Host.UI.RawUI.WindowTitle = "Remote Shell"

$need_admin = $true

# Check if the script is running as administrator
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($need_admin -eq $false) {
        Write-Host "Current user is not an administrator. Ignoring" -ForegroundColor Yellow
    } else {
        Write-Host "Current user is not an administrator. Attempting to run with elevated permissions..." -ForegroundColor Yellow
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        Exit
    }
} else {
    Write-Host "Running with administrator privileges." -ForegroundColor Green
}

$Computer_Name = Read-Host "Computer Name"

$session = New-PSSession -ComputerName $Computer_Name

function Fake_Loading ([int]$milliseconds_per, [int]$repetitions) {
    for ($i = 0; $i -lt $repetitions; $i++) {
        Start-Sleep -Milliseconds $milliseconds_per
        Write-Host "." -NoNewline
    }
}

# Test the session to ensure validity
if ($session -and $session.State -eq "Opened") {
    Write-Host "Session established with $($session.ComputerName)" -ForegroundColor Green
    $Host.UI.RawUI.WindowTitle = "Remote Shell - $($session.ComputerName) - Session ID: $($session.Id)"
} else {
    Write-Host "Session could not be established" -ForegroundColor Red
    Write-Host "Press ENTER to exit" -NoNewline -ForegroundColor Red
    Read-Host 
    Exit
}

function Run_Remote_Command ([string]$cmd) {
    if ($session.State -eq "Opened") {
        Invoke-Command -Session $session -ScriptBlock {
            param (
                [string]$cmd
            )
            Invoke-Expression $cmd
        } -ArgumentList $cmd
    } else {
        Write-Host "Session $($session.Id) is closed" -ForegroundColor Red
        return $null
    }
}

# commands

# finds all "explorer.exe" processes and gets the user and domain of the owner
# NOTE: this grabs all active users on the machine
$GET_GUI_USERS = {
    $current_date = $(get-date)
    Get-CimInstance Win32_Process -Filter "name LIKE 'explorer.exe'" | ForEach-Object { 
        $output = Invoke-CimMethod -InputObject $_ -MethodName GetOwner | Select-Object User, Domain
        $uptime = New-Timespan -start $_.CreationDate -End $current_date
        $uptime_formatted = $uptime.ToString("dd\:hh\:mm\:ss")
        $output | Add-Member -MemberType NoteProperty -Name Uptime -Value $uptime_formatted
        $output
    }
}
# this just grabs all the local and domain accounts on the machine
$GET_USERS = {
    Get-CimInstance Win32_UserAccount | Select-Object Name, Domain, Disabled, SID | Sort-Object -Property Disabled
}

# this detects all users including runas processes and their sessions
# NOTE: this requires admin privileges
$GET_SESSIONS_ADMIN = {
    $sessions = @()
    get-process -IncludeUserName | Sort-Object -Property Username -Unique | ForEach-Object {
        if ($null -eq $_.Username -and $_.SessionId -eq 0) {
            continue
        }
        $session = New-Object PSObject -Property @{
            "Session" = $_.SessionID
            "User" = $_.UserName
        }
        $sessions += $session
    }
    return $($sessions | Sort-Object -Property Session)
}
# this grabs all processes with a unique session id and then works backward to get the user and domain of the owner
# NOTE: this will detect users who are connected remotely via PSRemoting but will not detect users who are connected via RDP
$GET_SESSIONS = {
    $sessions = @()
    Get-CimInstance Win32_Process | Sort-Object -Property SessionId -Unique | ForEach-Object {
        $session_info = New-Object PSObject
        $session_info | Add-Member -MemberType NoteProperty -Name "SessionId" -Value $_.SessionId
        $owner = Invoke-CimMethod -InputObject $_ -MethodName GetOwner
        if ($_.SessionId -eq 0) {
            $owner.User = "ROOT"
            $owner.Domain = "N/A"
        }
        $session_info | Add-Member -MemberType NoteProperty -Name "User" -Value $owner.User
        $session_info | Add-Member -MemberType NoteProperty -Name "Domain" -Value $owner.Domain
        $sessions += $session_info 
    }
    $sessions | Select-Object User, Domain, SessionId | Sort-Object -Property SessionId
}

# Begin the remote shell
function Print_Header {
    Write-Host "----- Remote Shell $($session.ComputerName) ID-$($session.Id) ------" -ForegroundColor Cyan
    Write-Host "----- Type #help for a list of commands -----" -ForegroundColor Cyan
}

Print_Header
$exit = $false
while (-not $exit) {
    Write-Host "PS $($session.ComputerName) ID-$($session.Id)" -NoNewline
    if ($session.State -eq "Opened") { 
        Write-Host " CONNECTED" -ForegroundColor Green -NoNewline
    } else {
        Write-Host " DISCONNECTED" -ForegroundColor Red -NoNewline
    }
    Write-Host ">" -NoNewline
    
    $cmd = Read-Host

    if ($cmd[0] -eq "#") {
        switch ($cmd[1..($cmd.Length - 1)] -join '') {
            "help" {
                Write-Host "Available commands:" -ForegroundColor Cyan
                Write-Host "    #help - Show this help message" -ForegroundColor Cyan
                Write-Host "    #exit or #quit - Exit the remote shell" -ForegroundColor Cyan
                Write-Host "    #cls or #clear - Clear the screen" -ForegroundColor Cyan
                Write-Host "    #status - Show session status" -ForegroundColor Cyan
                Write-Host "    #kill - Terminate the session gracefully" -ForegroundColor Cyan
                Write-Host "    #get-users - Get a list of all users on the remote machine" -ForegroundColor Cyan
                Write-Host "    #get-gui-users - Gets the active gui users on the machine (by detecting explorer.exe)" -ForegroundColor Cyan
                Write-Host "    #get-sessions - Gets all sessions on the machine" -ForegroundColor Cyan
                Write-Host "    #get-sessions-admin - This detects all users and their sessions (including commands runas other users)" -ForegroundColor Cyan
                Write-Host "    #exfiltrate - saves the output of a specified command to the local machine" -ForegroundColor Cyan
                Write-Host "Note: any command not starting with `#` will be executed on the remote machine" -ForegroundColor Cyan
            }
            "exit" { $exit = $true }
            "q" { $exit = $true }
            "quit" { $exit = $true }
            "cls" { 
                Clear-Host 
                Print_Header
            }
            "clear" { 
                Clear-Host 
                Print_Header
            }
            "status" {
                Write-Host "Session Name: " -NoNewline -ForegroundColor Yellow
                    Write-Host "$($session.Name)"
                Write-Host "Transport Type: " -NoNewline -ForegroundColor Yellow
                    Write-Host "$($session.Transport)"
                Write-Host "State: " -NoNewline -ForegroundColor Yellow
                $color = "Green"
                if ($session.State -ne "Opened") { $color = "Red" }
                    Write-Host "$($session.State)" -ForegroundColor $color
                Write-Host "Session ID: "-NoNewline -ForegroundColor Yellow
                    Write-Host "$($session.Id)"
                Write-Host "Connected to: " -NoNewline -ForegroundColor Yellow
                    Write-Host "$($session.ComputerName)"
            }
            "get-users" {
                $output = Run_Remote_Command $GET_USERS
                if ($null -ne $output) { $output | Select-Object Name, Domain, SID | Format-Table -AutoSize }
            }
            "get-gui-users" {
                $output = Run_Remote_Command $GET_GUI_USERS
                if ($null -ne $output) { $output | Select-Object User, Domain | Format-Table -AutoSize }
            }
            "get-sessions" {
                $output = Run_Remote_Command $GET_SESSIONS
                if ($null -ne $output) { $output | Format-Table -AutoSize }
            }
            "get-sessions-admin" {
                $output = Run_Remote_Command $GET_SESSIONS_ADMIN
                if ($null -ne $output) { $output | Format-Table -AutoSize }
            }
            "exfiltrate" {
                $outfile = Read-Host "Enter the outfile path (local machine)"
                $cmd = Read-Host "Enter the command to run (remote machine) or `#cancel to cancel"
                if ($cmd -eq "#cancel") { 
                    Write-Host "exfiltrate cancelled" -ForegroundColor Yellow
                    continue 
                }
                $output = Run_Remote_Command $cmd
                if ($null -ne $output) {
                    Write-Host "Command executed successfully" -ForegroundColor Green
                    $output | Out-File $outfile 
                    if (Test-Path $outfile) {
                        Write-Host "Output saved to $outfile" -ForegroundColor Green
                    } else {
                        Write-Host "Failed to save output to $outfile" -ForegroundColor Red
                    }
                } else {
                    Write-Host "Command failed to execute or generated no output" -ForegroundColor Red
                }
            }
            "kill" {
                Remove-PSSession -Session $session
                Write-Host "Session $($session.Id) killed successfully" -ForegroundColor Green
            }
            Default {
                Write-Host "Unknown command: $cmd" -ForegroundColor Red
                Write-Host "Type #help for a list of commands" -ForegroundColor Red
            }
        }
    } elseif ($session.State -eq "Opened") {
        if ($cmd -eq "exit") {
            Write-Host "WARNING: this will close the remote shell and non-gracefully terminate the session (use #exit to close the shell or #kill to gracefully terminate the session)" -ForegroundColor Yellow
            Write-Host "Would you like to proceed in terminating the session? (Y/N): " -NoNewline -ForegroundColor Yellow
            $kill = Read-Host
            if ($kill -ne "Y" -and $kill -ne "y") {
                Write-Host "Aborting session termination" -ForegroundColor Yellow
                continue
            }
        }
        Invoke-Command -Session $session -ScriptBlock {
            param (
                [string]$cmd
            )
            Invoke-Expression $cmd
        } -ArgumentList $cmd
    } else {
        Write-Host "Session $($session.Id) is closed" -ForegroundColor Red
    }
}

Write-Host "Would you like to kill the session? (Y/N): " -NoNewline
$kill = Read-Host
if ($kill -eq "Y" -or $kill -eq "y") {
    Remove-PSSession -Session $session
    Write-Host "Session $($session.Id) killed" -ForegroundColor Green -NoNewline
} else {
    Write-Host "Quitting without killing the session" -ForegroundColor Yellow -NoNewline
}
Start-Sleep 1