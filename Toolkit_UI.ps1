Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Toolkit"
$form.Size = New-Object System.Drawing.Size(500, 400)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Hello, PowerShell UI!"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(100, 50)
$form.Controls.Add($label)

# Create a menu
$menu = New-Object System.Windows.Forms.MenuStrip

# ------------------------------------------------------------------------------------------------
# -------------------------------------- CONNECT MENU --------------------------------------------
# ------------------------------------------------------------------------------------------------

$ConnectMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Connect")
$ConnectHost = New-Object System.Windows.Forms.ToolStripMenuItem("Connect to Host (PS Remoting)")
$ConnectMulti = New-Object System.Windows.Forms.ToolStripMenuItem("Connect to Multiple Hosts (PS Remoting)")
$RemoteDesktop = New-Object System.Windows.Forms.ToolStripMenuItem("Remote Desktop (RDP)")
$SecureSocketShell = New-Object System.Windows.Forms.ToolStripMenuItem("Secure Socket Shell (SSH)")
$TestConnection = New-Object System.Windows.Forms.ToolStripMenuItem("Test Connection")

$ConnectMenu.DropDownItems.Add($ConnectHost)
$ConnectMenu.DropDownItems.Add($ConnectMulti)
$ConnectMenu.DropDownItems.Add($RemoteDesktop)
$ConnectMenu.DropDownItems.Add($SecureSocketShell)
$ConnectMenu.DropDownItems.Add($TestConnection)

$RemoteDesktop.ToolTipText = "Opens the Remote Desktop Connection client (mstsc.exe)"
$RemoteDesktop.Add_Click({
    Start-Process "mstsc.exe" -ArgumentList "/noConsentPrompt"
})

$SecureSocketShell.ToolTipText = "Opens the Secure Socket Shell client (ssh.exe)"
$SecureSocketShell.Add_Click({
    Start-Process "cmd.exe" -ArgumentList "/k ssh.exe"
})

$menu.Items.Add($ConnectMenu) # Add menu to the menu strip

# ------------------------------------------------------------------------------------------------
# ------------------------------------- ENUMERATE MENU -------------------------------------------
# ------------------------------------------------------------------------------------------------

# Create Enum Tools menu
$EnumToolMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Local Tools")

# Create Enum Tools menu items
$Systeminfo = New-Object System.Windows.Forms.ToolStripMenuItem("Systeminfo")
$ActiveDirectoryMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Active Directory")
    $ActiveDirectoryUserLookup = New-Object System.Windows.Forms.ToolStripMenuItem("User Lookup")
    $ActiveDirectoryGroupLookup = New-Object System.Windows.Forms.ToolStripMenuItem("Group Lookup")
    $ActiveDirectoryComputerLookup = New-Object System.Windows.Forms.ToolStripMenuItem("Computer Lookup")

# Add items to Enum Tools menu
$EnumToolMenu.DropDownItems.Add($Systeminfo)
$EnumToolMenu.DropDownItems.Add($ActiveDirectoryMenu)
    $ActiveDirectoryMenu.DropDownItems.Add($ActiveDirectoryUserLookup)
    $ActiveDirectoryMenu.DropDownItems.Add($ActiveDirectoryGroupLookup)
    $ActiveDirectoryMenu.DropDownItems.Add($ActiveDirectoryComputerLookup)

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
    $outputBox.AppendText("User Lookup saved to $env:TEMP\UserLookup.txt`n")
})

$ActiveDirectoryGroupLookup.ToolTipText = "Lookup Group in Active Directory - AD_Lookup.ps1 Group"
$ActiveDirectoryGroupLookup.Add_Click({
    $outputBox.AppendText("Running AD_Lookup.ps1 at $(Get-Date)`n")
    invoke-expression "start-process powershell.exe -ArgumentList '-executionpolicy Bypass .\AD_Lookup.ps1 Group' -WorkingDirectory .\Local_Enum_Tools"
    $outputBox.AppendText("Group Lookup saved to $env:TEMP\GroupLookup.txt`n")
})

$ActiveDirectoryComputerLookup.ToolTipText = "Lookup Computer in Active Directory - AD_Lookup.ps1 Computer"
$ActiveDirectoryComputerLookup.Add_Click({
    $outputBox.AppendText("Running AD_Lookup.ps1 at $(Get-Date)`n")
    invoke-expression "start-process powershell.exe -ArgumentList '-executionpolicy Bypass .\AD_Lookup.ps1 Computer' -WorkingDirectory .\Local_Enum_Tools"
    $outputBox.AppendText("Computer Lookup saved to $env:TEMP\ComputerLookup.txt`n")
})

# Add menu to the menu strip
$menu.Items.Add($EnumToolMenu)

# ------------------------------------------------------------------------------------------------
# --------------------------------------- JOBS MENU ----------------------------------------------
# ------------------------------------------------------------------------------------------------

# Create Jobs menu
$JobsMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Jobs")
$StartJob = New-Object System.Windows.Forms.ToolStripMenuItem("Start Job")

# Add items to Connect menu


# Add items to Jobs menu
$JobsMenu.DropDownItems.Add($StartJob)
$JobsMenu.DropDownItems.Add($EndJob)

$menu.Items.Add($JobsMenu) # Add menu to the menu strip

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