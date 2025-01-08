$Host.UI.RawUI.WindowTitle = "TCP Transmitter"

$pshost = Get-Host              # Get the PowerShell Host.
$pswindow = $pshost.UI.RawUI    # Get the PowerShell Host's UI.

$newsize = $pswindow.BufferSize # Get the UI's current Buffer Size.
$newsize.width = 120            # Set the new buffer's width to 150 columns.
$pswindow.buffersize = $newsize # Set the new Buffer Size as active.

$newsize = $pswindow.windowsize # Get the UI's current Window Size.
$newsize.width = 80            # Set the new Window Width to 150 columns.
$pswindow.windowsize = $newsize # Set the new Window Size as active.

function Enter_to_Exit {
    Write-Host "Press ENTER to exit"
    Read-Host
    Exit
}
function Start_TCP_Transmitter {
    try {
        # Get destination IP and port from user
        $global:dst_ip = Read-Host -Prompt "Destination IP"
        $global:dst_port = [int](Read-Host -Prompt "Destination Port")
        $global:dst_proto = "(TCP)"

        Write-Host "Connecting"

        $Address = [system.net.IPAddress]::Parse($dst_ip)

        # Create IP Endpoint
        $End = New-Object System.Net.IPEndPoint $Address, $dst_port

        # Create Socket
        $saddrf = [System.Net.Sockets.AddressFamily]::InterNetwork
        $Stype = [System.Net.Sockets.SocketType]::Stream
        $Ptype = [System.Net.Sockets.ProtocolType]::TCP
        $global:Sock = New-Object System.Net.Sockets.Socket $saddrf, $stype, $ptype

        # Connect to socket
        $global:sock.Connect($End)

        # Mark transmitter as working
        $global:transmitter = 1
        
        Write-Host "Successfully started the TCP transmitter" -ForegroundColor Blue
        $Host.UI.RawUI.WindowTitle = "TCP ${dst_ip}:${dst_port} Transmitter"
        $global:prompt = "${dst_ip}:${dst_port} ${dst_proto}>"
    }
    catch {
        Write-Host "ERROR: could not setup TCP transmitter" -ForegroundColor Red
        Enter_to_Exit
    }
}

function Stop_TCP_Transmitter {
    try {
        $global:sock.Close()
        Write-Host "Successfully stopped the TCP transmitter" -ForegroundColor Blue
    }
    catch {
        Write-Host "ERROR: could not stop the TCP transmitter" -ForegroundColor Red
    }

    # note: that regardless of whether or not the close was successful, the transmitter is marked as inactive
    $global:transmitter = $false
    $global:dst_ip = ""
    $global:dst_port = 0
    $global:dst_proto = ""
    $global:prompt = ">"
}

function Transmit_TCP_Message {
    param (
        $Message
    )
    try {
        # Create encoded buffer
        $Enc = [System.Text.Encoding]::ASCII
        $Buffer = $Enc.GetBytes($Message)

        # Send the buffer via the established socket
        if ($Sock.Connected) {
            $Sock.Send($Buffer)
        } else {
            Write-Host "ERROR: Socket is not connected" -ForegroundColor Red
        }

        # Informational message for length
        $length = $Message.Length
        $date = Get-Date -UFormat "%m/%d/%Y %R UTC%Z"
        Write-Host "SENT ${length} Characters AT ${date}" -ForegroundColor Green

        # Log the transmission to the convo_file
        Add-Content -Path $convo_file -Value "----- SENT TO ${dst_ip}:${dst_port} ${dst_proto} AT ${date} -----"
        Add-Content -Path $convo_file -Value "$Message"
    }
    catch {
        Write-Host "ERROR: could not send message" -ForegroundColor Red
    }
}

Write-Host "Running TCP_Transmitter.ps1 at $(get-date)" -foreground Cyan
Start_TCP_Transmitter
try {
    while ($true) {
        Write-Host "$prompt" -NoNewLine
        $userinput = Read-Host
        Transmit_TCP_Message $userinput
    }
} catch {
    Stop_TCP_Transmitter
    Enter_to_Exit
}
