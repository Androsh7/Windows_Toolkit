Add-Type -AssemblyName System.Windows.Forms

$Host.UI.RawUI.WindowTitle = "GetStrings"

Write-Host "Running GetStrings.ps1 at $(Get-Date)"-ForegroundColor Cyan

$out_file = "${env:TEMP}\Strings.txt"
$update_frequency = 3 #changes the seconds elapsed between progress updates

# opens a prompt to select a file
Write-Host "Please select a file"
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
$OpenFileDialog.Filter = "All files (*.*)|*.*"
$OpenFileDialog.Multiselect = $false

if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $selectedFile = $OpenFileDialog.FileName
    Write-Host "Selected file: $selectedFile" -ForegroundColor Cyan
} else {
    Write-Host "No file selected." -ForegroundColor Red
    Exit
}

# prompts the user to select the minimum string length
[int]$min_string_len = Read-Host "Select the minimum string length (default 3)"
if ($null -eq $min_string_len) { $min_string_len = 3 }

# tests to ensure the file exists
if (Test-Path $selectedFile) {
    Write-Host "File is accessible, proceeding to parse for strings" -ForegroundColor Green
} else {
    Write-Host "File is inaccessible, verify you have permissions to read this file" -ForegroundColor Red
    Read-Host "`nPress ENTER to exit"
    Exit
}

# grab byte stream
Write-Host "Grabbing Byte Stream for $selectedFile"

# note: this uses the older Powershell syntax (version 5.1)
# To make this script compatible with powershell version 7.5 change the command below to: Get-Content -Raw $selectedFile -AsByteStream
$byte_stream = Get-Content -Raw $selectedFile -Encoding Byte 

# add output file headers
"GetStrings.ps1 running on $(Get-Date)" > $out_file
"Parsing File: `"$selectedFile`"" >> $out_file
"Minimum String Length: $min_string_len" >> $out_file
"This file is saved in $out_file" >> $out_file
"------------------------------------------------------------------------------" >> $out_file

# parses the byte stream for strings
$total_bytes = $byte_stream.Count
Write-Host "Parsing Byte Stream (Total of $total_bytes Bytes)" -ForegroundColor Cyan

# create a stopwatch to show the progress of the operation
$stopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
$stopWatch.Start()
$last_update = 0

$out_string = ""
for ($i = 0; $i -lt $byte_stream.Count; $i++) {
    if ($byte_stream[$i] -gt 31 -and $byte_stream[$i] -lt 128) {
        $out_string += $([char]($byte_stream[$i]))
    } elseif ($out_string.length -ge $min_string_len) {
        $out_string >> $out_file
        $out_string = ""
    }
    if ($stopWatch.Elapsed.Seconds % $update_frequency -eq 0 -and $stopWatch.Elapsed.Seconds -ne $last_update) {
        Write-Host "$([int](($i / $total_bytes) * 100))% complete ($i of $total_bytes bytes)" -ForegroundColor Yellow
        $last_update = $stopWatch.Elapsed.Seconds
    }
}
$stopWatch.Stop()

Start-Process -FilePath "Notepad.exe" -ArgumentList $out_file