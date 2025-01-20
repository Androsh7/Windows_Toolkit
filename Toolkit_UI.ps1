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
$NetworkTab = New-Object System.Windows.Forms.TabPage
$NetworkTab.Text = "Network"

# Add tabs to the TabControl
$tabControl.TabPages.Add($ConnectTab)
$tabControl.TabPages.Add($RemoteTab)
$tabControl.TabPages.Add($ServerTab)
$tabControl.TabPages.Add($NetworkTab)

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

function Connect_Via_PSRemoting ([string]$Hostname) {
    $Port = "DEFAULT"
    if ($Hostname -contains ":") {
        $Only_Hostname = $Hostname.Split(":")[0]
        $Port = $Hostname.Split(":")[1]
    }
    try {
        if ($Port -ne "DEFAULT") {
            $Global:Session = New-PSSession -ComputerName $Only_Hostname -Port $Port
        } else {
            $Global:Session = New-PSSession -ComputerName $Hostname
        }
        return $true
    }
    catch {
        Write-Host "Connection Failed"
        $Global:Session = $null
        return $false
    }
}

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

# Create a label for the hostname
$HostLabel = New-Object System.Windows.Forms.Label
$HostLabel.text = "Hostname:"
$HostLabel.Location = New-Object System.Drawing.Point(10,148)
$HostLabel.AutoSize = $true
$ConnectTab.Controls.Add($HostLabel)

# Create a textbox for the hostname
$HostTextBox = New-Object System.Windows.Forms.TextBox
$HostTextBox.Location = New-Object System.Drawing.Point(100, 148)
$HostTextBox.Size = New-Object System.Drawing.Size(175, 20)
$ConnectTab.Controls.Add($HostTextBox)

# Create a label for the authentication method
$authLabel = New-Object System.Windows.Forms.Label
$authLabel.Text = "Auth Method:"
$authLabel.Location = New-Object System.Drawing.Point(10, 175)
$authLabel.AutoSize = $true
$ConnectTab.Controls.Add($authLabel)

# Create a ComboBox for authentication methods
$authComboBox = New-Object System.Windows.Forms.ComboBox
$authComboBox.Items.AddRange(@("PS-Remoting (Def Creds)", "PS-Remoting (Alt Creds)", "SSH Key", "OAuth", "Smart Card"))
$authComboBox.SelectedIndex = 0
$authComboBox.Location = New-Object System.Drawing.Point(100, 173)
$authComboBox.Size = New-Object System.Drawing.Size(175, 20)
$ConnectTab.Controls.Add($authComboBox)

# Create a label for the username
$usernameLabel = New-Object System.Windows.Forms.Label
$usernameLabel.Text = "Username:"
$usernameLabel.Location = New-Object System.Drawing.Point(10, 200)
$usernameLabel.AutoSize = $true
$usernameLabel.Visible = $false
$ConnectTab.Controls.Add($usernameLabel)

# Create a TextBox for the username
$usernameTextBox = New-Object System.Windows.Forms.TextBox
$usernameTextBox.Location = New-Object System.Drawing.Point(100, 200)
$usernameTextBox.Size = New-Object System.Drawing.Size(175, 20)
$usernameTextBox.Visible = $false
$ConnectTab.Controls.Add($usernameTextBox)

# Create a label for the password
$passwordLabel = New-Object System.Windows.Forms.Label
$passwordLabel.Text = "Password:"
$passwordLabel.Location = New-Object System.Drawing.Point(10, 225)
$passwordLabel.autosize = $true
$passwordLabel.Visible = $false
$ConnectTab.Controls.Add($passwordLabel)

# Create a TextBox for the password
$passwordTextBox = New-Object System.Windows.Forms.TextBox
$passwordTextBox.Location = New-Object System.Drawing.Point(100, 225)
$passwordTextBox.Size = New-Object System.Drawing.Size(175, 20)
$passwordTextBox.UseSystemPasswordChar = $true
$passwordTextBox.Visible = $false
$ConnectTab.Controls.Add($passwordTextBox)

# Create a label for the PIN (for Smart Card authentication)
$pinLabel = New-Object System.Windows.Forms.Label
$pinLabel.Text = "PIN:"
$pinLabel.Location = New-Object System.Drawing.Point(10, 200)
$pinLabel.AutoSize = $true
$pinLabel.Visible = $false
$ConnectTab.Controls.Add($pinLabel)

# Create a TextBox for the PIN (for Smart Card authentication)
$pinTextBox = New-Object System.Windows.Forms.TextBox
$pinTextBox.Location = New-Object System.Drawing.Point(100, 200)
$pinTextBox.UseSystemPasswordChar = $true
$pinTextBox.Visible = $false
$ConnectTab.Controls.Add($pinTextBox)

# Event handler for authentication method selection
$authComboBox.add_SelectedIndexChanged({
    switch ($authComboBox.SelectedItem) {
        "PS-Remoting (Alt Creds)" {
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
        "PS-Remoting (Def Creds)" {
            $usernameLabel.Visible = $false
            $usernameTextBox.Visible = $false
            $passwordLabel.Visible = $false
            $passwordTextBox.Visible = $false
            $pinLabel.Visible = $false
            $pinTextBox.Visible = $false
        }
    }
})

# Create a button for connect/disconnect
$connectButton = New-Object System.Windows.Forms.Button
$connectButton.Text = "Connect"
$connectButton.Location = New-Object System.Drawing.Point(10, 260)
$connectButton.Size = New-Object System.Drawing.Size(100, 30)
$connectButton.Add_Click({
    if ($connectButton.Text -eq "Connect") {
        $connectButton.Text = "Connecting..."
        $connectButton.Enabled = $false
        $result = Connect_Via_PSRemoting $HostTextBox.Text
        if ($result) {
            $connectButton.Text = "Disconnect"
        } else {
            $connectButton.Text = "Connect"
        }
    } else {
        $connectButton.Text = "Disconnecting..."
        $connectButton.Enabled = $false
        Remove-PSSession -Session $Global:Session
        $Global:Session = $null
        $connectButton.Text = "Connect"
    }
    $connectButton.Enabled = $true
    Query_Computer_Info
    Update_Label
})
$ConnectTab.Controls.Add($connectButton)

# ------------------------------------------------------------------------------------------------
# --------------------------------------- SERVER TAB ---------------------------------------------
# ------------------------------------------------------------------------------------------------

# Variables for server list
$servers = $null

# function to import servers from a file
function Import-Servers ([string]$servers) {
    $global:servers = Import-Csv $servers
}

# function to query the status of the servers
function Query_Servers {
    foreach ($server in $servers) {
        try {
            Test-Connection -ComputerName $server.Hostname -Count 1 -Quiet
            $server.Status = "Online"
        }
        catch {
            $server.Status = "Offline"
        }
    }
}

# Create a label for the server status
$serverStatusLabel = New-Object System.Windows.Forms.Label
$serverStatusLabel.Text = "----- Server Status -----"
$serverStatusLabel.Location = New-Object System.Drawing.Point(10, 10)
$serverStatusLabel.AutoSize = $true
$ServerTab.Controls.Add($serverStatusLabel)

# Create a button to update the server status
$RefreshButton = New-Object System.Windows.Forms.Button
$RefreshButton.Text = "Refresh"
$RefreshButton.Location = New-Object System.Drawing.Point(150, 5)
$RefreshButton.AutoSize = $true
$RefreshButton.Add_Click({
    Query_Servers
})
$ServerTab.Controls.Add($RefreshButton)

# Create a button to re-import the servers
$ImportButton = New-Object System.Windows.Forms.Button
$ImportButton.Text = "Import"
$ImportButton.Location = New-Object System.Drawing.Point(250, 5)
$ImportButton.AutoSize = $true
$ImportButton.Add_Click({
    $servers = Open-File -initialDirectory $env:USERPROFILE -filter "CSV Files (*.csv)|*.csv"
    if ($servers) {
        Import-Servers -servers $servers
    }
})
$ServerTab.Controls.Add($ImportButton)

# create a button to clear the server list
$ClearButton = New-Object System.Windows.Forms.Button
$ClearButton.Text = "Clear"
$ClearButton.Location = New-Object System.Drawing.Point(350, 5)
$ClearButton.AutoSize = $true
$ClearButton.Add_Click({

})
$ServerTab.Controls.Add($ClearButton)

# ------------------------------------------------------------------------------------------------
# ------------------------------------ NETWORK SETUP ---------------------------------------------
# ------------------------------------------------------------------------------------------------

# Create a label for the scanner section
$scannerLabel = New-Object System.Windows.Forms.Label
$scannerLabel.Text = "-- SCANNERS --"
$scannerLabel.Location = New-Object System.Drawing.Point(10, 10)
$scannerLabel.Font = New-Object System.Drawing.Font($scannerLabel.Font, [System.Drawing.FontStyle]::Bold)
$scannerLabel.AutoSize = $true
$NetworkTab.Controls.Add($scannerLabel)

# Create a button to start the ICMP scanner
$ICMP_Scanner = New-Object System.Windows.Forms.Button
$ICMP_Scanner.Text = "ICMP Scanner"
$ICMP_Scanner.Location = New-Object System.Drawing.Point(10, 40)
$ICMP_Scanner.Size = New-Object System.Drawing.Size(90, 30)
$ICMP_Scanner.Add_Click({
    Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -executionpolicy Bypass -File ./Remote_Enum_Tools/ICMP_Scanner.ps1"
})
$NetworkTab.Controls.Add($ICMP_Scanner)

# Create a button to start the TCP scanner
$TCP_Scanner = New-Object System.Windows.Forms.Button
$TCP_Scanner.Text = "TCP Scanner "
$TCP_Scanner.Location = New-Object System.Drawing.Point(10, 80)
$TCP_Scanner.Size = New-Object System.Drawing.Size(90, 30)
$TCP_Scanner.Add_Click({
    Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -executionpolicy Bypass -File ./Remote_Enum_Tools/TCP_Full_Connect_Scanner.ps1"
})
$NetworkTab.Controls.Add($TCP_Scanner)

# Create a label for the transmitters
$transmitterLabel = New-Object System.Windows.Forms.Label
$transmitterLabel.Text = "-- TRANSMITTERS --"
$transmitterLabel.Location = New-Object System.Drawing.Point(121, 10)
$transmitterLabel.Font = New-Object System.Drawing.Font($scannerLabel.Font, [System.Drawing.FontStyle]::Bold)
$transmitterLabel.AutoSize = $true
$NetworkTab.Controls.Add($transmitterLabel)

# Create a button to start the TCP scanner
$TCP_Transmitter = New-Object System.Windows.Forms.Button
$TCP_Transmitter.Text = "TCP Transmitter"
$TCP_Transmitter.Location = New-Object System.Drawing.Point(120, 40)
$TCP_Transmitter.Size = New-Object System.Drawing.Size(120, 30)
$TCP_Transmitter.Add_Click({
    Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -executionpolicy Bypass -File ./Transmitters/TCP_Transmitter.ps1"
})
$NetworkTab.Controls.Add($TCP_Transmitter)

# Create a button to start the TCP scanner
$UDP_Transmitter = New-Object System.Windows.Forms.Button
$UDP_Transmitter.Text = "UDP Transmitter"
$UDP_Transmitter.Location = New-Object System.Drawing.Point(120, 80)
$UDP_Transmitter.Size = New-Object System.Drawing.Size(120, 30)
$UDP_Transmitter.Add_Click({
    Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -executionpolicy Bypass -File ./Transmitters/UDP_Transmitter.ps1"
})
$NetworkTab.Controls.Add($UDP_Transmitter)

# Create a label for the receiver
$ReceiverLabel = New-Object System.Windows.Forms.Label
$ReceiverLabel.Text = "--- RECEIVERS ---"
$ReceiverLabel.Location = New-Object System.Drawing.Point(260, 10)
$ReceiverLabel.Font = New-Object System.Drawing.Font($scannerLabel.Font, [System.Drawing.FontStyle]::Bold)
$ReceiverLabel.AutoSize = $true
$NetworkTab.Controls.Add($ReceiverLabel)

# Create a button to start the TCP receiver
$TCP_Receiver = New-Object System.Windows.Forms.Button
$TCP_Receiver.Text = "TCP Receiver"
$TCP_Receiver.Location = New-Object System.Drawing.Point(260, 40)
$TCP_Receiver.Size = New-Object System.Drawing.Size(100, 30)
$TCP_Receiver.Add_Click({
    Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -executionpolicy Bypass -File ./Receivers/TCP_Receiver.ps1"
})
$NetworkTab.Controls.Add($TCP_Receiver)

# Create a button to start the UDP receiver
$UDP_Receiver = New-Object System.Windows.Forms.Button
$UDP_Receiver.Text = "UDP Receiver"
$UDP_Receiver.Location = New-Object System.Drawing.Point(260, 80)
$UDP_Receiver.Size = New-Object System.Drawing.Size(100, 30)
$UDP_Receiver.Add_Click({
    Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -executionpolicy Bypass -File ./Receivers/UDP_Receiver.ps1"
})
$NetworkTab.Controls.Add($UDP_Receiver)

# ------------------------------------------------------------------------------------------------
# ------------------------------------ TEXTBOX SETUP ---------------------------------------------
# ------------------------------------------------------------------------------------------------

# Show the form
$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()