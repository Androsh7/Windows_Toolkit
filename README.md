# Windows Toolkit

![image](https://github.com/user-attachments/assets/5054e53f-2bc2-48cf-8075-d72aac006d32)

This is a Windows Toolkit written exclusively in powershell (and a bit of html) with no external modules.

The purpose of this toolkit is to provide a simple replication of many common networking and basic sysadmin tools which can be used in a stock windows environment without administrator permissions.

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
