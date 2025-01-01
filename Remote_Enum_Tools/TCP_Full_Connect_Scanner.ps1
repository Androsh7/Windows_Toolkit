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
        return $true
    } catch {
        return $false
    }
}

#Write-Host "TCP Full-connect Scan on $target" -ForegroundColor Cyan
#Write-Host "Scanning Ports $($portsInput -join ', ')" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
try {
    foreach ($port in $ports) {
        if (Test-Port -target $target -port $port) {
            Write-Host "Port $port is open on $target" -ForegroundColor Green
        } else {
            Write-Host "Port $port is closed on $target" -ForegroundColor Red
        }
    }
}
finally {
    Enter_to_Exit
}
Enter_to_Exit