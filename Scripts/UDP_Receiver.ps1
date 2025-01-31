$Host.UI.RawUI.WindowTitle = "UDP Listener"

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

Write-Host "Running UDP_Receiver.ps1 at $(get-date)" -foreground Cyan
$port = [int](Read-Host "Select the UDP Listening Port")
try {
    $udpClient = New-Object System.Net.Sockets.UdpClient($port)
    $udpClient.Client.ReceiveTimeout = 1000
} catch {
    Write-Host "ERROR: Unable to establish a listening port on ${port}" -ForegroundColor Red
    Exit
}
$Host.UI.RawUI.WindowTitle = "UDP $port Listener"

$remoteEndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)

$date = Get-Date
Clear-Host
Write-Host "---------------------- UDP LISTENER on port ${port} ----------------------" -ForegroundColor Cyan

try {
    while ($true) {
        try {
            $receiveBytes = $udpClient.Receive([ref]$remoteEndPoint)
            $receivedData = [Text.Encoding]::ASCII.GetString($receiveBytes)
            $senderIP = $remoteEndPoint.Address.ToString()
            $senderPort = $remoteEndPoint.Port

            $date = Get-Date
            Write-Host "----- RECEIVED FROM ${senderIP}:${senderPort} AT ${date} -----" -ForegroundColor Green
            Write-Host "$receivedData"

        } catch {}
    }
} finally {
    Write-Host "-------------------- Stopped listening on port ${port} -------------------" -ForegroundColor Cyan
    $udpClient.Close()
    Enter_to_Exit
}