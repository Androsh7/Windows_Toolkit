$Host.UI.RawUI.WindowTitle = "Systeminfo"
Write-Host "Running Systeminfo.ps1 at $(Get-Date)" -NoNewline -ForegroundColor Cyan
"Systeminfo $(Get-Date)" > $env:TEMP\SystemInfo.txt
"Runas ${env:USERNAME} on ${env:COMPUTERNAME}" >> $env:TEMP\SystemInfo.txt
Get-ComputerInfo >> $env:TEMP\SystemInfo.txt
Clear-Host 
Get-Content $env:TEMP\SystemInfo.txt
Write-Host "System Information saved to $env:TEMP\SystemInfo.txt"
Read-Host "Press Enter to exit"