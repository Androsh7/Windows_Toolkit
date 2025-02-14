$Host.UI.RawUI.WindowTitle = "TCP_Scanner"

$max_connections = 100 # increase to speed up scans (100 is default)
$timeout = 1500 # milliseconds until a port is deemed to be closed (1500 is default)

$show_updates = $true # prints an update every 1,000 ports

$debug = $false # prints information on individual socket connections (not recommended)

while ($true) {
    Clear-Host
    Write-Host "Running TCP_Scanner.ps1 at $(Get-Date)" -ForegroundColor Cyan
    $target = [IpAddress](Read-Host "Enter the target IP address or hostname")
    $portsInput = Read-Host "Enter the ports to scan (e.g. 80, 443-500, 8080)"
    Write-Host "========================================================================" -ForegroundColor Cyan

    # takes port ranges and breaks them into individual ports (I.E: 1-5 to 1,2,3,4,5)
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

    # creates port array
    $ports = Parse_Ports -portsInput $portsInput

    # builds the tcp_clients
    $connectors = @()
    1..${max_connections} | ForEach-Object {
        $connector = New-Object psobject
        # States: 
        # 0 = ready to connect
        # 1 = waiting to connect
        $connector | Add-Member -MemberType NoteProperty -Name "State" -Value 0
        $connector | Add-Member -MemberType NoteProperty -Name "Port" -Value $null
        $connector | Add-Member -MemberType NoteProperty -Name "Time" -Value $null
        $connector | Add-Member -MemberType NoteProperty -Name "Tcp_Client" -Value $(New-Object System.Net.Sockets.TcpClient)
        $connectors += $connector
    }
    if ($debug) { Write-Host "Setup $($connectors.Count) connectors" -ForegroundColor Yellow }

    # run the scan
    $port_iter = 0
    $quit = $false
    $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()

    while (-not $quit) {
        # start the connections
        0..$($connectors.length - 1) | Where-Object { $connectors[$_].State -eq 0 } | ForEach-Object {
            if ($port_iter -gt $ports.Count) {
                $quit = $true
                break
            }
            $connectors[$_].Tcp_Client.ConnectAsync($target, $ports[$port_iter]) 1>$null
            $connectors[$_].Port = $ports[$port_iter]
            $connectors[$_].Time = $stopWatch.Elapsed
            $connectors[$_].State = 1
            if ($debug) { Write-Host "Setup TCP_Client $_ - ${target}:$($connectors[$_].Port) - Status $($connectors[$_].State) - Time $($connectors[$_].Time)" -ForegroundColor Yellow }
            if ($show_updates -and $port_iter % 1000 -eq 0) {
                Write-Host "Scanned $($port_iter) of $($ports.Count) ports" -ForegroundColor Yellow
            }
            $port_iter++
        }

        # check on connections
        0..$($connectors.Length - 1) | ForEach-Object {
            # check if connection is successful
            if ($connectors[$_].Tcp_Client.Connected -eq $true) {
                if ($debug) { Write-Host "Receiving TCP_Client $_ - ${target}:$($connectors[$_].Port) - " -ForegroundColor Yellow -NoNewline }
                Write-Host "Port $($connectors[$_].Port) is open" -ForegroundColor Green
                $connectors[$_].Tcp_Client.Client.Disconnect($true)
            }
            # check if connection failed
            elseif ($stopWatch.Elapsed.TotalMilliseconds - $connectors[$_].Time.TotalMilliseconds -gt $timeout) {
                if ($debug) { Write-Host "Receiving TCP_Client $_ - ${target}:$($connectors[$_].Port) - " -ForegroundColor Yellow -NoNewline }
                if ($debug) { Write-Host "Port $($connectors[$_].Port) is closed" -ForegroundColor Red }
            }
            # skip if connection is still pending
            else {
                return
            }

            # reset connector
            $connectors[$_].Tcp_Client.Dispose()
            $connectors[$_].Tcp_Client = New-Object System.Net.Sockets.TcpClient
            $connectors[$_].Time = $null
            $connectors[$_].Port = $null
            $connectors[$_].State = 0
        }
    }
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "Scanned $($ports.Count) ports in $([math]::Round($stopWatch.Elapsed.TotalSeconds, 2)) seconds" -ForegroundColor Cyan

    # destroy connector objects
    $connectors | ForEach-Object {
        $_.Tcp_Client.Dispose()
    }
    $connectors.Clear()

    $userinput = Read-Host "Press Enter to continue or Q to quit"
    if ($userinput -match "Q") { exit }
}