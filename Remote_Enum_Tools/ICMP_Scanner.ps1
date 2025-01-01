$Host.UI.RawUI.WindowTitle = "ICMP Scanner"
Write-Host "Running ICMP_Scanner.ps1 at $(Get-Date)" -ForegroundColor Cyan
$input = Read-Host "Enter IP addresses I.E: (192.168.1.1, 10.15.1.1-10.15.1.255, Machine15)"
$machines = $input -split ","
# Check if the input contains a range of IP addresses
if ($input -match '(\d+\.){3}\d+-(\d+\.){3}\d+') {
    $range = $input -split "-"
    $startIP = [System.Net.IPAddress]::Parse($range[0])
    $endIP = [System.Net.IPAddress]::Parse($range[1])
    $startBytes = $startIP.GetAddressBytes()
    $endBytes = $endIP.GetAddressBytes()
    
    $machines = @()
    for ($i = $startBytes[3]; $i -le $endBytes[3]; $i++) {
        $machines += "$($startBytes[0]).$($startBytes[1]).$($startBytes[2]).$i"
    }
} else {
    $machines = $input -split ","
}

# Function to ping a machine
function Test-ICMP {
    param (
        [string]$Target
    )
    $pingResult = Test-Connection -ComputerName $Target -Count 1 -ErrorAction SilentlyContinue
    if (-not $pingResult) {
        Write-Host "$Target is not reachable - $(get-date -UFormat '%H:%M:%S')" -ForegroundColor Red
    }
    elseif ($pingResult.StatusCode -eq 0) {
        Write-Host "$Target is reachable.    - $(get-date -UFormat "%H:%M:%S") - $($pingResult.ResponseTime)ms delay" -ForegroundColor Green
    }
}

# Ping each machine in the list
Write-Host "==================================================" -ForegroundColor Cyan
try {
    while ($true) {
        foreach ($machine in $machines) {
            Test-ICMP -Target $machine
        }
    }
}
catch {
    Enter_to_Exit
}
Enter_to_Exit