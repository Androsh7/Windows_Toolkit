# Windows Toolkit - Version 0.8

![image](https://github.com/user-attachments/assets/bba453a4-4867-48fa-978a-4612c5406228)

This is a Windows Toolkit written exclusively in PowerShell version 5.1 (see note about compatibility with pwsh.exe) with no external modules.

The purpose of this toolkit is to provide a simple replication of many common networking and basic sysadmin tools which can be used in a stock windows environment without administrator permissions.

# Feature List

- TCP Client/Listener - These allow for two-way communication either as a listener or client with a chat like UI
- UDP Transmitter/Receiver - Similar to the TCP Transmitter/Receiver this currently only allows for one-way communication
  - [ ] WIP - allow for two-way communciation
- TCP Scanner - TCP full-connect scanner that uses multiple tcp sockets attempting asynchronous connections
- ICMP Scanner - ICMP ping sweep scanner that pings multiple hosts simultaneously
- Basic Shortcuts - The program currently has shortcuts for the following programs:
  - [X] mstsc.exe (Default RDP connector on windows)
  - [X] cmd.exe (user and runas)
  - [X] powershell.exe (user and runas)
  - [X] Enter-PSSession (user and runas)
  - [X] pwsh.exe (user and runas)
- Utilities
  - [X] Current_Users.ps1 - a script that shows all active users, their sessions, and their oldest process
  - [X] All_Users.ps1 - a script to show all user's who have established an account on the machine
  - [X] SystemInfo.ps1 - a script that runs the "systeminfo" command and then opens up a notepad with the results
  - [X] Get_Strings.ps1 - a script that parses any file for valid ASCII strings of a specified length and then returns a notepad with the results
  - [X] Get_Strings.ps1 - a script to constantly query all users and their sessions (when run as admin this can detect runas processes and windows service accounts)
  - [X] View_Login.ps1 - a script to parse security event logs for all successful and failed login attempts by a user
  - [X] Remote_Shell.ps1 - a script that provides a more advanced powershell remoting (as opposed to Enter-PSSession) with prefab commands and other integrated tools
  - [ ] WIP - AD_Lookup.ps1 - This script is currently non-functional, eventually this will be integrated into the Domain_Computer_Query.html and Domain_User_Query.html pages to allow for queries done through the web form

# Compatibility with Powershell Version 7+ (pwsh.exe)
| Name | powershell.exe (v5.1) | pwsh.exe (v7.5) | Notes |
| - | :-: | :-: | - |
| powershell_web_server.ps1 | ✅ | ✅ | |
| AD Tools | ⚠️ | ⚠️ | These tools are still WIP |
| All_Users.ps1 | ✅ | ✅ | |
| Current_Users.ps1 | ✅ | ✅ | Running as a user is only allowed with version 7.5 |
| Get_Strings.ps1 | ✅ | ✅ | uses version check for compatibility |
| ICMP_Scanner.ps1 | ✅  | ✅ | |
| Remote_Shell.ps1 | ✅  | ✅ | |
| System_Info.ps1 | ✅ | ✅  | |
| TCP_Client.ps1 | ✅ | ✅  | |
| TCP_Receiver.ps1 | ✅ | ✅ | |
| TCP_Scanner.ps1 | ✅ | ✅ | |
| UDP_Receiver.ps1 | ✅ | ✅ | |
| UDP_Transmitter.ps1 | ✅ | ✅ | |
| View_Login.ps1 | ✅ | ✅ | Significantly slower in version 5.1 (or earlier) |
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
