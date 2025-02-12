# Windows Toolkit - Version 0.8

![image](https://github.com/user-attachments/assets/8741af83-a114-4ac2-8282-9ff2c8216e8a)

This is a Windows Toolkit written exclusively in PowerShell version 5.1 (and a bit of html) with no external modules.

The purpose of this toolkit is to provide a simple replication of many common networking and basic sysadmin tools which can be used in a stock windows environment without administrator permissions.

# Feature List

- TCP Transmitter/Receiver - These currently work but only allow one-way traffic (I.E: Transmitter can't show replies and Receiver can't send packets)
  - [X] TCP_Client.ps1 - allow for two-way communciation
  - [ ] WIP - TCP_Receiver.ps1 - allow for two-way communication
- UDP Transmitter/Receiver - Similar to the TCP Transmitter/Receiver this currently only allows for one-way communication
  - [ ] WIP - allow for two-way communciation
- TCP Scanner - TCP full-connect scanner that uses PS job to scan multiple ports at once
- ICMP Scanner - ICMP ping sweep scanner that pings each specified host or a range of hosts one-by-one
  - [ ] WIP - optimize with PS jobs to allow multiple simultaneous scans 
- Basic Shortcuts - The program currently has shortcuts for the following programs:
  - [X] mstsc.exe (Default RDP connector on windows)
  - [X] cmd.exe (user and runas)
  - [X] powershell.exe (user and runas)
  - [X] Enter-PSSession (user and runas)
  - [X] pwsh.exe (user and runas)
- Utilities
  - [X] SystemInfo.ps1 - a script that runs the "systeminfo" command and then opens up a notepad with the results
  - [X] Get_Strings.ps1 - a script that parses any file for valid ASCII strings of a specified length and then returns a notepad with the results
  - [X] Remote_Shell.ps1 - a script that provides a more advanced powershell remoting (as opposed to Enter-PSSession) with prefab commands and other integrated tools
  - [ ] WIP - AD_Lookup.ps1 - This script is currently non-functional, eventually this will be integrated into the Domain_Computer_Query.html and Domain_User_Query.html pages to allow for queries done through the web form

# Escaping Email and Web Filters

Generally email filters will restrict sending .ps1 files, furthermore certain web filters will prevent downloading .ps1 files.

For filtering done ONLY by extension use the following script to append .txt to each of the powershell scripts to evade filters:

```
Get-ChildItem -Recurse | Where-Object { $_.FullName -match "\.ps1$" } | ForEach-Object { Rename-Item -Path $_.FullName -NewName $_.Name.Replace(".ps1",".ps1.txt") }
```

Then to remove the .txt extension run:

```
Get-ChildItem -Recurse | Where-Object { $_.FullName -match "\.ps1.txt$" } | ForEach-Object { Rename-Item -Path $_.FullName -NewName $_.Name.Replace(".ps1.txt",".ps1") }
```
