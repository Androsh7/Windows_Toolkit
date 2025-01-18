$Host.UI.RawUI.WindowTitle = "TCP Full-connect Scanner"
Write-Host "Running TCP_Full_Connect_Scanner.ps1 at $(Get-Date)" -ForegroundColor Cyan
$target = Read-Host "Enter the target IP address or hostname"
$portsInput = Read-Host "Enter the ports to scan (e.g. 80, 443-500, 8080)"

function Enter_to_Exit {
    Read-Host "Press Enter to exit"
    Exit
}

function Parse_Ports {
    param (
        [string]$portsInput
    )
    $ports = @()
    $portsInput.Split(',') | ForEach-Object {
        if ($_ -match '(\d+)-(\d+)') {
            $ports += ($matches[1]..$matches[2])
        } else {
            $ports += [int]$_
        }
    }
    return $ports
}

$ports = Parse_Ports -portsInput $portsInput

function Test-Port {
    param (
        [string]$target,
        [int]$port
    )

    $tcpClient = New-Object System.Net.Sockets.TcpClient
    try {
        $tcpClient.Connect($target, $port)
        $tcpClient.Close()
        Write-Host $true
    } catch {
        Write-Host $false
    }
}

Write-Host "==================================================" -ForegroundColor Cyan

# creates the tcp connect jobs
$total_port = ($ports | Measure-Object).Count
Write-Host "Creating TCP Scan Jobs (Total of $total_port)"
$scan_jobs = @()
$repitions = 0
$ports | ForEach-Object {
    $scan_job = New-Object -TypeName psobject
    $scan_job | Add-Member -MemberType NoteProperty -Name "Port" -Value $_
    $job = Start-Job -ScriptBlock {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        try {
            $tcpClient.Connect($target, $_)
            $tcpClient.Close()
            return $true
        } catch {
            return $false
        }
    }
    $scan_job | Add-Member -MemberType NoteProperty -Name "Job" -Value $job
    $scan_jobs += $scan_job
    $repitions += 1
    if (-not $repitions % 250 -and $repitions -ne 0) {
        Write-Host "Created $repitions of $total_port jobs"
    }
}
Write-Host "Created $total_port powershell jobs"

# validates that the scans are complete
$total_scans = 0
$repitions = 0
while ($total_scans -lt $total_port) {
    $total_scans = ($scan_jobs.job | Where-Object { $_.State -eq "Completed" } | measure-object).count
    Start-Sleep -Milliseconds 250
    $repitions += 1
    if ($repitions % 4 -and $repitions -ne 0) {
        Write-Host "Waiting on Scans - Completed $total_scans of $total_port"
    }
}
Write-Host "Completed All scans"

# prints all the jobs
Write-Host "==================================================" -ForegroundColor Cyan
$scan_jobs | ForEach-Object {
    $job_result = Receive-Job $_.job
    if ($job_result) {
        Write-Host "$target TCP port ${_.port} OPEN" -ForegroundColor Green
    } else {
        Write-Host "$target TCP port ${_.port} CLOSED" -ForegroundColor Red
    }
}

Enter_to_Exit