$Host.UI.RawUI.WindowTitle = "TCP CLIENT"

Write-Host "------------------------- TCP CLIENT -------------------------" -ForegroundColor Yellow
$dst_ip = Read-Host -Prompt "Destination IP Address"
[int32]$dst_port = Read-Host -Prompt "Destination Port"

# Build the tcp_client object
$tcp_client = New-Object System.Net.Sockets.TcpClient

# attempt to connect
try {
    Write-Host "Attempting to connect to ${dst_ip}:${dst_port}" -ForegroundColor Cyan
    $tcp_client.Connect($dst_ip, $dst_port)
}
catch {
    Write-Host "Failed to connect to ${dst_ip}:${dst_port}" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
    Pause
    Exit
}
Clear-Host
$Host.UI.RawUI.WindowTitle = "TCP CLIENT - $($tcp_client.Client.LocalEndPoint) CONNECTED TO $($tcp_client.Client.RemoteEndPoint)"
Write-Host "---------------------------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "TCP CLIENT CONNECTION $($tcp_client.Client.LocalEndPoint) --> $($tcp_client.Client.RemoteEndPoint)" -ForegroundColor Yellow
Write-Host "---------------------------------------------------------------------------------------" -ForegroundColor Yellow

# grab stream reader
$tcp_stream = $tcp_client.GetStream()

# set the output variables
$encoding = [System.Text.Encoding]::ASCII
$out_string = ""

# set the input variables
$read_buffer = New-Object byte[] 1024

while ($tcp_client.Connected) {

    # checks if data is available to be printed
    if ($tcp_stream.DataAvailable) {

        # read the input
        $read_bytes = $tcp_stream.Read($read_buffer, 0, 1024)
        $out_string = [Text.Encoding]::ASCII.GetString($read_buffer, 0, $read_bytes)

        # write to the screen
        Write-Host "$($tcp_client.Client.RemoteEndPoint)> " -ForegroundColor Green -NoNewline
        Write-Host $out_string -NoNewline -ForegroundColor Green

        # clear the read buffer
        0..${read_bytes} | ForEach-Object {
            $read_buffer[$_] = [byte]0
        }
    }
    # checks if a keyboard input has been read (NOTE: this can readable multiple queued keypresses)
    while ([Console]::KeyAvailable) {
        $key = [console]::ReadKey()
        if ($key.Key -eq "Enter") {
            # send the out_string
            $out_buffer = $encoding.GetBytes($out_string + "`n")
            $out_bytes = $tcp_stream.Write($out_buffer, 0, $out_string.Length)

            # write to the screen
            Write-Host "$($tcp_client.Client.LocalEndPoint)> " -ForegroundColor Cyan -NoNewline
            Write-Host $out_string -ForegroundColor Cyan

            # clears the out_string
            $out_string = ""
            break
        } elseif ($key.Key -eq "Escape") {
            # this is a placeholder that will be used to cancel the input
        } else {
            $out_string += $key.KeyChar
        }
    }  
}
