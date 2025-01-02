Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Toolkit"
$form.Size = New-Object System.Drawing.Size(500, 400)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = ""
$label.TextAlign = [System.Drawing.ContentAlignment]::Left
$label.Size = New-Object System.Drawing.Size(200, 20)
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(25, 40)
$form.Controls.Add($label)

# Create a menu
$menu = New-Object System.Windows.Forms.MenuStrip
# ------------------------------------------------------------------------------------------------
# -------------------------------------- VARIABLES -----------------------------------------------
# ------------------------------------------------------------------------------------------------

# Connection Information:
$Username = "User"
$Sid = "SID"
$Hostname = "Host"
$MacAddress = "MAC Address"
$IpAddress = "IP Address"
$WorkingDirectory = "Working Directory"

# Connection Credentials:
$StoredCredential = $null
$Session = $null
$SessionId = "None"
$SessionStatus = "Disconnected"

# ------------------------------------------------------------------------------------------------
# -------------------------------------- FUNCTIONS -----------------------------------------------
# ------------------------------------------------------------------------------------------------
function Open-File([string]$initialDirectory, [string]$filter) {
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = $filter
    $OpenFileDialog.ShowDialog() | Out-Null
    return $OpenFileDialog.filename
}

function Query_Computer_Info {
    $Global:Username = $env:USERNAME
    $Global:Sid = (New-Object System.Security.Principal.NTAccount($Username)).Translate([System.Security.Principal.SecurityIdentifier]).Value
    $Global:Hostname = $env:COMPUTERNAME
    $Global:MacAddress = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } | Select-Object -ExpandProperty MacAddress
    $Global:IpAddress = [System.Net.Dns]::GetHostAddresses($Hostname) | Where-Object { $_.AddressFamily -eq "InterNetwork" } | Select-Object -ExpandProperty IPAddressToString
    $Global:WorkingDirectory = Get-Location
    if ($Session) {
        $Global:SessionStatus = "Connected"
        $Global:SessionId = $Session.Id
    } else {
        $Global:SessionStatus = "Disconnected"
        $Global:SessionId = "None"
    }
}

function Update_Label {
    $label.Text = "Username: $Global:Username" + "`n" + 
                  "SID: $Global:Sid" + "`n" +
                  "Hostname: $Global:Hostname" + "`n" + 
                  "IP Address: $Global:IpAddress" + "`n" +
                  "MAC Address: $Global:MacAddress" + "`n" +
                  "Working Directory: $Global:WorkingDirectory" + "`n" +
                  "Session ID: $Global:SessionId" + "`n" +
                  "Session Status: $Global:SessionStatus"
}
Query_Computer_Info
Update_Label 

# ------------------------------------------------------------------------------------------------
# -------------------------------------- BUTTONS ------------------------------------------------
# ------------------------------------------------------------------------------------------------

# clear the screen buttonm
$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = "Clear Screen"
$clearButton.Size = New-Object System.Drawing.Size(100, 30)
$clearButton.Location = New-Object System.Drawing.Point(370, 50)
$clearButton.Add_Click({
    $outputBox.Clear()
})
$form.Controls.Add($clearButton)

# kill session button
$killButton = New-Object System.Windows.Forms.Button
$killButton.Text = "Kill Session"
$killButton.Size = New-Object System.Drawing.Size(100, 30)
$killButton.Location = New-Object System.Drawing.Point(370, 100)
$killButton.Add_Click({
    if ($Session) {
        $outputBox.AppendText("Disconnecting from $($Session.ComputerName) at $(Get-Date)`n")
        Remove-PSSession -Session $Session
        $outputBox.AppendText("Disconnected from $($Session.ComputerName)`n")
        $Global:Session = $null
    } else {
        $outputBox.AppendText("No session to disconnect`n")
    }
    $Global:SessionStatus = "Disconnected"
    Update_Label
})
$form.Controls.Add($killButton)

# ------------------------------------------------------------------------------------------------
# -------------------------------------- CONNECT MENU --------------------------------------------
# ------------------------------------------------------------------------------------------------

$ConnectMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Connect")
$ConnectHost = New-Object System.Windows.Forms.ToolStripMenuItem("Connect to Host (PS Remoting)")
$ConnectMulti = New-Object System.Windows.Forms.ToolStripMenuItem("Connect to Multiple Hosts (PS Remoting)")
$ConnectCredentials = New-Object System.Windows.Forms.ToolStripMenuItem("Store or Change Credentials (PS Remoting)")
$RemoteDesktop = New-Object System.Windows.Forms.ToolStripMenuItem("Remote Desktop (RDP)")
$SecureSocketShell = New-Object System.Windows.Forms.ToolStripMenuItem("Secure Socket Shell (SSH)")
$TestConnection = New-Object System.Windows.Forms.ToolStripMenuItem("Test Connection")

$ConnectMenu.DropDownItems.Add($ConnectHost)
$ConnectMenu.DropDownItems.Add($ConnectMulti)
$ConnectMenu.DropDownItems.Add($ConnectCredentials)
$ConnectMenu.DropDownItems.Add($RemoteDesktop)
$ConnectMenu.DropDownItems.Add($SecureSocketShell)
$ConnectMenu.DropDownItems.Add($TestConnection)

$ConnectHost.ToolTipText = "Connect to Host (PS Remoting)"
$ConnectHost.Add_Click({
    $hostnameInput = New-Object System.Windows.Forms.Form
    $hostnameInput.Text = "PowerShell Remoting"
    $hostnameInput.Size = New-Object System.Drawing.Size(300, 150)
    $hostnameInput.StartPosition = "CenterParent"

    $hostnameLabel = New-Object System.Windows.Forms.Label
    $hostnameLabel.Text = "Hostname:"
    $hostnameLabel.Location = New-Object System.Drawing.Point(10, 20)
    $hostnameLabel.AutoSize = $true
    $hostnameInput.Controls.Add($hostnameLabel)

    $hostnameTextBox = New-Object System.Windows.Forms.TextBox
    $hostnameTextBox.Location = New-Object System.Drawing.Point(80, 18)
    $hostnameTextBox.Size = New-Object System.Drawing.Size(200, 20)
    $hostnameInput.Controls.Add($hostnameTextBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(80, 60)

    $submitHostname = {
        $connectHost = $hostnameTextBox.Text
        $hostnameInput.Close()
        if ($connectHost -and $connectHost.Trim() -ne "") {
            $outputBox.AppendText("Connecting to $connectHost at $(Get-Date)`n")
            if ($Global:StoredCredential) {
                $outputBox.AppendText("Using stored credentials $($Global:StoredCredential.UserName)`n")
                $Global:Session = New-PSSession -ComputerName $connectHost -Credential $Global:StoredCredential
            } else {
                $outputBox.AppendText("No credentials stored, using current user`n")
                $Global:Session = New-PSSession -ComputerName $connectHost
            }

            if ($Session) {
                $outputBox.AppendText("Connected to $connectHost`n")
                $outputBox.AppendText("Session ID: $($Session.Id)`n")
                $outputBox.AppendText("Session Name: $($Session.Name)`n")
                $outputBox.AppendText("Session Computer Name: $($Session.ComputerName)`n")
                $outputBox.AppendText("Session State: $($Session.State)`n")
                $global:SessionStatus = "Connected"
            } else {
                $outputBox.AppendText("Failed to connect to $connectHost`n")
            }
        } else {
            $outputBox.AppendText("No hostname provided`n")
        }
        Update_Label
    }

    $okButton.Add_Click($submitHostname)
    $hostnameTextBox.Add_KeyDown({
        if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
            $submitHostname.Invoke()
        }
    })
    $hostnameInput.Controls.Add($okButton)

    $hostnameInput.ShowDialog()
})

$ConnectMulti.ToolTipText = "Connect to Multiple Hosts (PS Remoting)"
$ConnectMulti.Add_Click({
    $outputBox.AppendText("Doesn't Work Yet, Sorry!`n")
})


$ConnectCredentials.ToolTipText = "Cache credentials for PS Remoting"
$ConnectCredentials.Add_Click({
    $Global:StoredCredential = Get-Credential
})

$RemoteDesktop.ToolTipText = "Opens the Remote Desktop Connection client - mstsc.exe"
$RemoteDesktop.Add_Click({
    Start-Process "mstsc.exe" -ArgumentList "/noConsentPrompt"
})

$SecureSocketShell.ToolTipText = "Opens the Secure Socket Shell client - ssh.exe"
$SecureSocketShell.Add_Click({
    Start-Process "cmd.exe" -ArgumentList "/k ssh.exe"
})

$menu.Items.Add($ConnectMenu) # Add menu to the menu strip

# ------------------------------------------------------------------------------------------------
# ------------------------------------- ENUMERATE MENU -------------------------------------------
# ------------------------------------------------------------------------------------------------

# Create Enum Tools menu
$EnumToolMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Tools")

# Create Enum Tools menu items
$Systeminfo = New-Object System.Windows.Forms.ToolStripMenuItem("Systeminfo")
$ActiveDirectoryMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Active Directory")
    $ActiveDirectoryUserLookup = New-Object System.Windows.Forms.ToolStripMenuItem("User Lookup")
    $ActiveDirectoryGroupLookup = New-Object System.Windows.Forms.ToolStripMenuItem("Group Lookup")
    $ActiveDirectoryComputerLookup = New-Object System.Windows.Forms.ToolStripMenuItem("Computer Lookup")
    $ActiveDirectoryDomainUpdate = New-Object System.Windows.Forms.ToolStripMenuItem("Update Domains")
$NetworkScanners = New-Object System.Windows.Forms.ToolStripMenuItem("Network Scanners")
    $TCPFullConnectScanner = New-Object System.Windows.Forms.ToolStripMenuItem("TCP Full Connect Scanner")
    $ICMPScanner = New-Object System.Windows.Forms.ToolStripMenuItem("ICMP Scanner")

# Add items to Enum Tools menu
$EnumToolMenu.DropDownItems.Add($Systeminfo)
$EnumToolMenu.DropDownItems.Add($ActiveDirectoryMenu)
    $ActiveDirectoryMenu.DropDownItems.Add($ActiveDirectoryUserLookup)
    $ActiveDirectoryMenu.DropDownItems.Add($ActiveDirectoryGroupLookup)
    $ActiveDirectoryMenu.DropDownItems.Add($ActiveDirectoryComputerLookup)
    $ActiveDirectoryMenu.DropDownItems.Add($ActiveDirectoryDomainUpdate)
$EnumToolMenu.DropDownItems.Add($NetworkScanners)
    $NetworkScanners.DropDownItems.Add($TCPFullConnectScanner)
    $NetworkScanners.DropDownItems.Add($ICMPScanner)

$Systeminfo.ToolTipText = "Get System Information - Systeminfo.ps1"
$Systeminfo.Add_Click({
    $outputBox.AppendText("Running Systeminfo.ps1 at $(Get-Date)`n")
    Start-Process powershell.exe -ArgumentList "-executionpolicy Bypass .\Local_Enum_Tools\SystemInfo.ps1"
    $outputBox.AppendText("System Information saved to $env:TEMP\SystemInfo.txt`n")
})

$ActiveDirectoryUserLookup.ToolTipText = "Lookup User in Active Directory - AD_Lookup.ps1 User"
$ActiveDirectoryUserLookup.Add_Click({
    $outputBox.AppendText("Running AD_Lookup.ps1 at $(Get-Date)`n")
    invoke-expression "start-process powershell.exe -ArgumentList '-executionpolicy Bypass .\AD_Lookup.ps1 User' -WorkingDirectory .\Local_Enum_Tools"
})

$ActiveDirectoryGroupLookup.ToolTipText = "Lookup Group in Active Directory - AD_Lookup.ps1 Group"
$ActiveDirectoryGroupLookup.Add_Click({
    $outputBox.AppendText("Running AD_Lookup.ps1 at $(Get-Date)`n")
    invoke-expression "start-process powershell.exe -ArgumentList '-executionpolicy Bypass .\AD_Lookup.ps1 Group' -WorkingDirectory .\Local_Enum_Tools"
})

$ActiveDirectoryComputerLookup.ToolTipText = "Lookup Computer in Active Directory - AD_Lookup.ps1 Computer"
$ActiveDirectoryComputerLookup.Add_Click({
    $outputBox.AppendText("Running AD_Lookup.ps1 at $(Get-Date)`n")
    invoke-expression "start-process powershell.exe -ArgumentList '-executionpolicy Bypass .\AD_Lookup.ps1 Computer' -WorkingDirectory .\Local_Enum_Tools"
})

$ActiveDirectoryDomainUpdate.ToolTipText = "Get Avaliable Domains in Active Directory - AD_Update.ps1"
$ActiveDirectoryDomainUpdate.Add_Click({
    $outputBox.AppendText("Running AD_Update.ps1 at $(Get-Date)`n")
    Start-Process powershell.exe -ArgumentList "-executionpolicy Bypass .\Local_Enum_Tools\AD_Update.ps1 -WorkingDirectory .\Local_Enum_Tools"
})

$TCPFullConnectScanner.ToolTipText = "Scan for open TCP ports on a target - TCP_Full_Connect_Scanner.ps1"
$TCPFullConnectScanner.Add_Click({
    $outputBox.AppendText("Running TCP_Full_Connect_Scanner.ps1 at $(Get-Date)`n")
    Start-Process powershell.exe -ArgumentList "-executionpolicy Bypass .\Remote_Enum_Tools\TCP_Full_Connect_Scanner.ps1 -WorkingDirectory .\Remote_Enum_Tools"
})

$ICMPScanner.ToolTipText = "Scan for open ICMP ports on a target - ICMP_Scanner.ps1"
$ICMPScanner.Add_Click({
    $outputBox.AppendText("Running ICMP_Scanner.ps1 at $(Get-Date)`n")
    Start-Process powershell.exe -ArgumentList "-executionpolicy Bypass .\Remote_Enum_Tools\ICMP_Scanner.ps1 -WorkingDirectory .\Remote_Enum_Tools"
})

# Add menu to the menu strip
$menu.Items.Add($EnumToolMenu)

# ------------------------------------------------------------------------------------------------
# --------------------------------------- LOGS MENU ----------------------------------------------
# ------------------------------------------------------------------------------------------------

# Create Jobs menu
$LogMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Logs")
$ReadLog = New-Object System.Windows.Forms.ToolStripMenuItem("Read Logs")
$ClearLog = New-Object System.Windows.Forms.ToolStripMenuItem("Clear Logs")

# Add items to Jobs menu
$LogMenu.DropDownItems.Add($ReadLog)
$LogMenu.DropDownItems.Add($ClearLog)

$ReadLog.ToolTipText = "Read Logs - $(Get-Location).\Logs"
$ReadLog.Add_Click({
    $OpenFile = Open-File "$(Get-Location).\Logs" "Text Files (*.txt)|*.txt"
    if ($OpenFile) {
        Start-Process notepad.exe $OpenFile
    }
})

$ClearLog.ToolTipText = "Clear Logs - $(Get-Location).\Logs"
$ClearLog.Add_Click({
    Remove-Item "$(Get-Location).\Logs\*.txt"
})

 # Add menu to the menu strip
$menu.Items.Add($LogMenu)

# ------------------------------------------------------------------------------------------------
# ------------------------------------ TEXTBOX SETUP ---------------------------------------------
# ------------------------------------------------------------------------------------------------

# Create a TextBox to display output
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.Size = New-Object System.Drawing.Size(450, 200)
$outputBox.Location = New-Object System.Drawing.Point(20, 150)
$form.Controls.Add($outputBox)

$form.MainMenuStrip = $menu
$form.Controls.Add($menu)

# Show the form
$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()