$Host.UI.RawUI.WindowTitle = "TCP Full-connect Scanner"

$max_jobs = 30
$debug = $false

while ($true) {
    Clear-Host
    Write-Host "Running TCP_Full_Connect_Scanner.ps1 at $(Get-Date)" -ForegroundColor Cyan
    $target = Read-Host "Enter the target IP address or hostname"
    $portsInput = Read-Host "Enter the ports to scan (e.g. 80, 443-500, 8080)"
    Write-Host "========================================================================" -ForegroundColor Cyan
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

    $active_jobs = @()
    $results = @()
    for ($i = 0; $i -lt $ports.Length; $i += 1) {
        
        # Create Jobs
        if ($i % $max_jobs -eq 0) {
            if ($i -ne 0) {
                [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop - 2)
            }
            $remaining_jobs = [int](@($max_jobs, $($ports.length - $results.length)) | Measure-Object -Minimum).Minimum
            Write-Host "Scanning [" -NoNewline
            foreach ($space in 2..${remaining_jobs}) { Write-Host " " -NoNewline}
            Write-Host "]" -NoNewline
            foreach ($space in 0..$($max_jobs - $remaining_jobs)) { Write-HosT " " -NoNewLine}
            [System.Console]::SetCursorPosition([System.Console]::CursorLeft - $remaining_jobs - $($max_jobs - $remaining_jobs) - 1, [System.Console]::CursorTop)
        }
        else {Write-Host "=" -NoNewline}
        $new_job = New-Object -TypeName psobject
        $new_job | Add-Member -MemberType NoteProperty -Name "Port" -Value $ports[$i]
        $job = Start-Job -Name "TCP_SCANNER_JOB" -ScriptBlock {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            try {
                $tcpClient.Connect($target, $ports[$i])
                $tcpClient.Close()
                return $true
            } catch {
                return $false
            }
        }
        $new_job | Add-Member -MemberType NoteProperty -Name "Job" -Value $job
        $active_jobs += $new_job
        if ($debug) { Write-Host "Created Job ID: $($job.Id) out of $($active_jobs.Length)" }

        # grab output of jobs
        if (($active_jobs.Length % $max_jobs -eq 0 -and $active_jobs.Length -ne 0) -or $active_jobs.Length + $results.Length -eq $ports.Length) {
            Write-Host ""
            $repetitions = 0
            For ($z = 0; $z -lt $active_jobs.Length; $z += 1) {
                if ($active_jobs[$z].Job.State -ne "Completed") { 
                    Start-Sleep -Milliseconds 100
                    $repetitions += 1
                    if ($repetitions -eq 1) { 
                        if ($debug) { Write-Host "Waiting on Job"  -NoNewline} 
                        $z -= 1 
                    }
                    elseif ($repetitions -lt 20) { 
                        if ($debug) { write-host " ." -NoNewline }
                        $z -= 1 
                    } # this is to negate incrementing $z by the continue command
                    else { 
                        if ($debug) { write-host " skipping" } 
                        $repetitions = 0;  $z -= 1 
                    }
                    continue 
                }
                if ($repetitions -gt 0) { 
                    if ($debug) { Write-Host "" }
                    $repetitions = 0
                } # formatting

                if ($debug) { Write-Host "Receiving Job ID: $($active_jobs[$z].Job.Id)" }
                $result = Receive-Job -Job $active_jobs[$z].Job
                $result_obj = New-Object -TypeName psobject
                $result_obj | Add-Member -MemberType NoteProperty -Name "Port" -Value $active_jobs[$z].Port
                $result_obj | Add-Member -MemberType NoteProperty -Name "Result" -Value $result
                $results += $result_obj
            }
            Write-Host "Scanned $($results.Length) of $($ports.Length) ports"
            $global:active_jobs = @()
            Get-Job | Where-Object {$_.Name -eq "TCP_SCANNER_JOB"} | ForEach-Object { Remove-Job $_}
        }
    }

    Write-Host "========================================================================" -ForegroundColor Cyan
    For ($i = 0; $i -lt $results.Length; $i += 1) {
        $start_state = $results[$i].Result
        $start_port = $results[$i].Port
        $new_list = @($start_port)
        while ($true) {
            $i += 1
            if ($results[$i].Result -eq $start_state -and $results[$i].Port -eq $new_list[-1] + 1) {
                $new_list += $results[$i].Port
            } else {
                $i -= 1
                break
            }
        }

        # writes the results to the list
        if ($new_list.length -eq 1) {
            if ($start_state) { Write-Host "$target TCP Port  $start_port OPEN" -ForegroundColor Green}
            else { Write-Host "$target TCP Port  $start_port CLOSED" -ForegroundColor Red}
        } else {
            if ($start_state) { Write-Host "$target TCP Ports $($new_list[0])-$($new_list[-1]) OPEN" -ForegroundColor Green}
            else { Write-Host "$target TCP Ports $($new_list[0])-$($new_list[-1]) CLOSED" -ForegroundColor Red}
        }
    }

    $userIn = Read-Host "Press ENTER to continue or Q to quit"
    if ($userIn -contains "q") { exit }
}