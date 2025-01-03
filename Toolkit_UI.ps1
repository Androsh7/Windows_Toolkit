Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create a TabControl
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Size = New-Object System.Drawing.Size(500, 400)
$tabControl.Location = New-Object System.Drawing.Point(0, 0)

# Create Tabs
$ConnectTab = New-Object System.Windows.Forms.TabPage
$ConnectTab.Text = "Connect"
$RemoteTab = New-Object System.Windows.Forms.TabPage
$RemoteTab.Text = "Remote"
$ServerTab = New-Object System.Windows.Forms.TabPage
$ServerTab.Text = "Server"

# Add tabs to the TabControl
$tabControl.TabPages.Add($ConnectTab)
$tabControl.TabPages.Add($RemoteTab)
$tabControl.TabPages.Add($ServerTab)

# Add TabControl to the form
$form.Controls.Add($tabControl)

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Toolkit"
$form.Size = New-Object System.Drawing.Size(500, 400)
$form.StartPosition = "CenterScreen"

$form.Controls.Add($tabControl)



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
# --------------------------------------- CONNECT TAB --------------------------------------------
# ------------------------------------------------------------------------------------------------

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = ""
Update_Label
$label.TextAlign = [System.Drawing.ContentAlignment]::Left
$label.Size = New-Object System.Drawing.Size(300, 20)
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10, 15)
$ConnectTab.Controls.Add($label)

# Create a label for the authentication method
$authLabel = New-Object System.Windows.Forms.Label
$authLabel.Text = "Auth Method:"
$authLabel.Location = New-Object System.Drawing.Point(10, 150)
$authLabel.AutoSize = $true
$ConnectTab.Controls.Add($authLabel)

# Create a ComboBox for authentication methods
$authComboBox = New-Object System.Windows.Forms.ComboBox
$authComboBox.Items.AddRange(@("Password", "SSH Key", "OAuth", "Smart Card"))
$authComboBox.SelectedIndex = 0
$authComboBox.Location = New-Object System.Drawing.Point(80, 150)
$authComboBox.Size = New-Object System.Drawing.Size(100, 20)
$ConnectTab.Controls.Add($authComboBox)

# Create a label for the username
$usernameLabel = New-Object System.Windows.Forms.Label
$usernameLabel.Text = "Username:"
$usernameLabel.Location = New-Object System.Drawing.Point(10, 175)
$usernameLabel.AutoSize = $true
$ConnectTab.Controls.Add($usernameLabel)

# Create a TextBox for the username
$usernameTextBox = New-Object System.Windows.Forms.TextBox
$usernameTextBox.Location = New-Object System.Drawing.Point(80, 175)
$usernameTextBox.Size = New-Object System.Drawing.Size(150, 20)
$ConnectTab.Controls.Add($usernameTextBox)

# Create a label for the password
$passwordLabel = New-Object System.Windows.Forms.Label
$passwordLabel.Text = "Password:"
$passwordLabel.Location = New-Object System.Drawing.Point(10, 200)
$passwordLabel.autosize = $true
$ConnectTab.Controls.Add($passwordLabel)

# Create a TextBox for the password
$passwordTextBox = New-Object System.Windows.Forms.TextBox
$passwordTextBox.Location = New-Object System.Drawing.Point(80, 200)
$passwordTextBox.Size = New-Object System.Drawing.Size(150, 20)
$passwordTextBox.UseSystemPasswordChar = $true
$ConnectTab.Controls.Add($passwordTextBox)

# Create a label for the PIN (for Smart Card authentication)
$pinLabel = New-Object System.Windows.Forms.Label
$pinLabel.Text = "PIN:"
$pinLabel.Location = New-Object System.Drawing.Point(10, 175)
$pinLabel.AutoSize = $true
$pinLabel.Visible = $false
$ConnectTab.Controls.Add($pinLabel)

# Create a TextBox for the PIN (for Smart Card authentication)
$pinTextBox = New-Object System.Windows.Forms.TextBox
$pinTextBox.Location = New-Object System.Drawing.Point(80, 175)
$pinTextBox.UseSystemPasswordChar = $true
$pinTextBox.Visible = $false
$ConnectTab.Controls.Add($pinTextBox)

# Event handler for authentication method selection
$authComboBox.add_SelectedIndexChanged({
    switch ($authComboBox.SelectedItem) {
        "Password" {
            $usernameLabel.Visible = $true
            $usernameTextBox.Visible = $true
            $passwordLabel.Visible = $true
            $passwordTextBox.Visible = $true
            $pinLabel.Visible = $false
            $pinTextBox.Visible = $false
        }
        "SSH Key" {
            $usernameLabel.Visible = $true
            $usernameTextBox.Visible = $true
            $passwordLabel.Visible = $false
            $passwordTextBox.Visible = $false
            $pinLabel.Visible = $false
            $pinTextBox.Visible = $false
        }
        "OAuth" {
            $usernameLabel.Visible = $true
            $usernameTextBox.Visible = $true
            $passwordLabel.Visible = $false
            $passwordTextBox.Visible = $false
            $pinLabel.Visible = $false
            $pinTextBox.Visible = $false
        }
        "Smart Card" {
            $usernameLabel.Visible = $false
            $usernameTextBox.Visible = $false
            $passwordLabel.Visible = $false
            $passwordTextBox.Visible = $false
            $pinLabel.Visible = $true
            $pinTextBox.Visible = $true
        }
    }
})

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
# --------------------------------------- SERVER TAB ---------------------------------------------
# ------------------------------------------------------------------------------------------------

# Create a label for the server status
$serverStatusLabel = New-Object System.Windows.Forms.Label
$serverStatusLabel.Text = "Server Status:"
$serverStatusLabel.Location = New-Object System.Drawing.Point(10, 15)
$serverStatusLabel.AutoSize = $true
$ServerTab.Controls.Add($serverStatusLabel)

# Create a ListView to display server statuses
$serverStatusListView = New-Object System.Windows.Forms.ListView
$serverStatusListView.Location = New-Object System.Drawing.Point(10, 40)
$serverStatusListView.Size = New-Object System.Drawing.Size(460, 300)
$serverStatusListView.View = [System.Windows.Forms.View]::Details
$serverStatusListView.Columns.Add("Name", -2, [System.Windows.Forms.HorizontalAlignment]::Left)
$serverStatusListView.Columns.Add("Address", -2, [System.Windows.Forms.HorizontalAlignment]::Left)
$serverStatusListView.Columns.Add("IPv4", -2, [System.Windows.Forms.HorizontalAlignment]::Left)
$serverStatusListView.Columns.Add("Status", -2, [System.Windows.Forms.HorizontalAlignment]::Left)
$ServerTab.Controls.Add($serverStatusListView)

# Import server details from a CSV file
$csvPath = "C:\path\to\servers.csv"
$servers = Import-Csv -Path $csvPath | ForEach-Object {
    @{
        Name = $_.Name
        Address = $_.Address
        IPv4 = $_.IPv4
    }
}

function Initialize-ServerStatusListView {
    $serverStatusListView.Items.Clear()
    $serverStatusListView.Columns.Clear()
    $serverStatusListView.Columns.Add("Name", -2, [System.Windows.Forms.HorizontalAlignment]::Left)
    $serverStatusListView.Columns.Add("Address", -2, [System.Windows.Forms.HorizontalAlignment]::Left)
    $serverStatusListView.Columns.Add("IPv4", -2, [System.Windows.Forms.HorizontalAlignment]::Left)
    $serverStatusListView.Columns.Add("Status", -2, [System.Windows.Forms.HorizontalAlignment]::Left)
}

function Update-ServerStatus {
    for ($i = 0; $i -lt $servers.Count; $i++) {
        $server = $servers[$i]
        $ping = Test-Connection -ComputerName $server.Address -Count 1 -Quiet
        if ($ping) {
            $status = "Online"
            $color = [System.Drawing.Color]::Green
        } else {
            $status = "Offline"
            $color = [System.Drawing.Color]::Red
        }
        if ($serverStatusListView.Items.Count -le $i) {
            $item = New-Object System.Windows.Forms.ListViewItem($server.Name)
            $item.SubItems.Add($server.Address)
            $item.SubItems.Add($server.IPv4)
            $item.SubItems.Add($status)
            $item.ForeColor = $color
            $serverStatusListView.Items.Add($item)
        } else {
            $item = $serverStatusListView.Items[$i]
            $item.SubItems[0].Text = $server.Name
            $item.SubItems[1].Text = $server.Address
            $item.SubItems[2].Text = $server.IPv4
            $item.SubItems[3].Text = $status
            $item.ForeColor = $color
        }
    }
    $serverStatusListView.AutoResizeColumns([System.Windows.Forms.ColumnHeaderAutoResizeStyle]::ColumnContent)
}

# Initialize the ListView columns
Initialize-ServerStatusListView

# Timer to update server status every 10 seconds
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 10000
$timer.Add_Tick({ Update-ServerStatus })
$timer.Start()

# Initial update of server status
Update-ServerStatus

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