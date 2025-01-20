$Host.UI.RawUI.WindowTitle = "UDP Transmitter"

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

function Start_UDP_Transmitter {
    try {
        # Get destination IP and port from user
        $global:dst_ip = Read-Host -Prompt "Destination IP"
        $global:dst_port = [int](Read-Host -Prompt "Destination Port")
        $global:dst_proto = "(UDP)"

        Write-Host "Connecting"

        $Address = [system.net.IPAddress]::Parse($dst_ip)

        # Create IP Endpoint
        $global:End = New-Object System.Net.IPEndPoint $Address, $dst_port

        # Create Socket
        $saddrf = [System.Net.Sockets.AddressFamily]::InterNetwork
        $Stype = [System.Net.Sockets.SocketType]::Dgram
        $Ptype = [System.Net.Sockets.ProtocolType]::UDP
        $global:Sock = New-Object System.Net.Sockets.Socket $saddrf, $stype, $ptype

        # Mark transmitter as working
        $global:transmitter = $true
        
        Write-Host "Successfully started the UDP transmitter" -ForegroundColor Blue
        $Host.UI.RawUI.WindowTitle = "UDP ${dst_ip}:${dst_port} Transmitter"
        $global:prompt = "${dst_ip}:${dst_port} ${dst_proto}>"
    }
    catch {
        Write-Host "ERROR: could not setup UDP transmitter" -ForegroundColor Red
        Enter_to_Exit
    }
}

function Stop_UDP_Transmitter {
    try {
        $global:sock.Close()
        Write-Host "Successfully stopped the UDP transmitter" -ForegroundColor Blue
    }
    catch {
        Write-Host "ERROR: could not stop the UDP transmitter" -ForegroundColor Red
    }

    # note: that regardless of whether or not the close was successful, the transmitter is marked as inactive
    $global:transmitter = $false
    $global:dst_ip = ""
    $global:dst_port = 0
    $global:dst_proto = ""
    $global:prompt = ">"
}

function Transmit_UDP_Message {
    param (
        $Message
    )
    try {
        if ($Sock) {
            # Create encoded buffer
            $Enc = [System.Text.Encoding]::ASCII
            $Buffer = $Enc.GetBytes($Message)

            # Send the buffer via the established socket
            $Sock.SendTo($Buffer, $End)

            # Informational message for length
            $length = $Message.Length
            $date = Get-Date -UFormat "%m/%d/%Y %R UTC%Z"
            Write-Host "SENT ${length} Characters AT ${date}" -ForegroundColor Green
        } else {
            Write-Host "ERROR: Socket is not initialized" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "ERROR: could not send message" -ForegroundColor Red
    }
}

Write-Host "Running UDP_Transmitter.ps1 at $(get-date)" -foreground Cyan
Start_UDP_Transmitter
try {
    while ($true) {
        Write-Host "$prompt" -NoNewLine
        $userinput = Read-Host
        Transmit_UDP_Message $userinput
    }
} catch {
    Stop_UDP_Transmitter
    Enter_to_Exit
}
