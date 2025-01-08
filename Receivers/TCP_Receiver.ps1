$Host.UI.RawUI.WindowTitle = "TCP Listener"

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

Write-Host "Running TCP_Receiver.ps1 at $(get-date)" -foreground Cyan
$port = [int](Read-Host "Select the TCP Listening Port")
try {
    $tcpListener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $port)
    $tcpListener.Start()
} catch {
    Write-Host "ERROR: Unable to establish a listening port on ${port}" -ForegroundColor Red
    Exit
}
$Host.UI.RawUI.WindowTitle = "TCP $port Listener"

$date = Get-Date
Clear-Host
Write-Host "---------------------- TCP LISTENER on port ${port} ----------------------" -ForegroundColor Cyan

try {
    while ($true) {
        try {
            if ($tcpListener.Pending()) {
                $tcpClient = $tcpListener.AcceptTcpClient()
                $networkStream = $tcpClient.GetStream()
                $buffer = New-Object byte[] 1024
                $bytesRead = $networkStream.Read($buffer, 0, $buffer.Length)
                $receivedData = [Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)
                $senderIP = $tcpClient.Client.RemoteEndPoint.Address.ToString()
                $senderPort = $tcpClient.Client.RemoteEndPoint.Port

                $date = Get-Date
                Write-Host "----- RECEIVED FROM ${senderIP}:${senderPort} AT ${date} -----" -ForegroundColor Green
                Write-Host "$receivedData"

                $networkStream.Close()
                $tcpClient.Close()
            }
        } catch {}
    }
} finally {
    Write-Host "-------------------- Stopped listening on port ${port} -------------------" -ForegroundColor Cyan
    $tcpListener.Stop()
    Enter_to_Exit
}