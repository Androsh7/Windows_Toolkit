# Create a new HttpListener instance
$listener = New-Object System.Net.HttpListener

# Listening prefix
$prefix = "http://127.0.0.1:9000/"
$listener.Prefixes.Add($prefix)

# Start the listener
$listener.Start()
Write-Host "Listening for incoming requests on $prefix" -ForegroundColor Cyan

# Create global variables
$context = $null
$response = $null
$request = $null

# build a PS-Drive (prevent directory traversal)
if (Get-PSDrive -Name "SitePages" -ErrorAction SilentlyContinue) { Remove-PSDrive -Name SitePages }
$SitePages = New-PSDrive -Name SitePages -PSProvider FileSystem -Root "${PSScriptRoot}\SitePages\"
if (Get-PSDrive -Name "Files" -ErrorAction SilentlyContinue) { Remove-PSDrive -Name Files }
$Files = New-PSDrive -Name Files -PSProvider FileSystem -Root "${PSScriptRoot}\Files\"


function Respond_OK ([bool]$close) {
    $response.StatusCode = 200
    $response.StatusDescription = "OK"
    if ($close) { $response.OutputStream.Close() }
}

function Respond_Custom ([string]$response_message, [int]$response_code, [bool]$close) {
    $response.StatusCode = $response_code
    $response.StatusDescription = $response_message
    if ($close) { $response.OutputStream.Close() }
}

# Serves an HTML page to the host
function Serve_HTML ([string]$Path) {
    $Path = $Path.Replace('/','\') # convert from web pathing to windows pathing
    if ($Null -eq $Path) {
        Write-Host "Serve_HTML insufficient Parameters provided" -ForegroundColor Red
        return
    }
    Write-Host "Serving Page `"$Path`" - " -NoNewline
    $responseString = ""
    if (test-path -Path "$Path" -PathType Leaf) {
        Write-Host "Valid Path" -ForegroundColor Green
        $responseString = get-content -path $Path
        Respond_OK -close $false
    } else {
        Write-Host "Invalid Path" -ForegroundColor Red
        $responseString = get-content -path "${PSScriptRoot}\Redirect\404.html"
        Respond_Custom -response_message "404 Not Found" -response_code 404
    }
    $buffer = [Text.Encoding]::UTF8.GetBytes($responseString)
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.OutputStream.Close()
}

function Serve_Error ([string]$path, [string]$error_message, [int]$error_code) {
    if ($null -eq $path -and $null -eq $error_message -and $null -eq $error_code) {
        Write-Host "Serve Error insufficient parameters provided" -ForegroundColor Red
    }
    $responseString = get-content -path $path
    $buffer = [Text.Encoding]::UTF8.GetBytes($responseString)
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    Respond_Custom -response_message $error_message -response_code $error_code
    $response.OutputStream.Close()
}

# shorthand functions for redirects
function 404_Not_Found { 
    Serve_Error -path "${PSScriptRoot}\Redirect\404.html" -error_message "Error 404 Page Not Found" -error_code 404
}
function 403_Access_Denied {
    Serve_Error -path "${PSScriptRoot}\Redirect\404.html" -error_message "Error 403 Access Denied" -error_code 403
}
function 405_Method_Not_Allowed { 
    Serve_Error -path "${PSScriptRoot}\Redirect\405.html" -error_message "Error 405 Method Not Allowed" -error_code 405
}
function 500_Internal_Server_Error { 
    Serve_Error -path "${PSScriptRoot}\Redirect\500.html" -error_message "Error 500 Internal Server Error" -error_code 500
}


# Serves a File to the host
function Serve_File ($Path, $Type) {
    $Path = $Path.Replace('/','\') # convert from web pathing to windows pathing
    if ($Null -eq $Path -or $Null -eq $Type) {
        Write-Host "Serve_File insufficient Parameters provided" -ForegroundColor Red
        return
    }
    Write-Host "Serving File `"$Path`" of type $Type - " -NoNewline
    $response.ContentType = $Type
    if (Test-Path -Path "$Path" -PathType Leaf) {
        Write-Host "Valid Path" -ForegroundColor Green
        $imageBytes = [System.IO.File]::ReadAllBytes((Convert-Path "$Path"))
        $response.ContentLength64 = $imageBytes.Length
        $response.OutputStream.Write($imageBytes, 0, $imageBytes.Length)
        Respond_OK -close $false
    } else {
        Write-Host "Invalid Path" -ForegroundColor Red
        Respond_Custom -response_message "404 Not Found" -response_code 404 -close $false
    }
    $response.OutputStream.Close()
}

function Shutdown_Actions {
    Write-Host "Shutting down the server" -ForegroundColor Red
    Respond_OK -close $true
    try {
        $listener.Stop()
        exit
    }
    catch {
        Write-Host "Error closing listener $_"
        500_Internal_Server_Error
    }
    exit
}

$script_list = (Get-ChildItem -Path "${PSScriptRoot}/Scripts/" -Filter "*.ps1").Name
function Start_Script ([string]$script_name) {
    try {
        Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -executionpolicy Bypass -File ${PSScriptRoot}/Scripts/${script_name}"
        Write-Host "Starting Script ${script_name}"
        $response.StatusCode = 200
        $response.StatusDescription = "OK"
        $response.OutputStream.Close()
    }
    catch {
        Write-Host "Error attempting to run ${script_name}: $_" -ForegroundColor Red
        $response.StatusCode = 500
        $response.StatusDescription = "Internal Server Error"
        $response.OutputStream.Close()
    }
}

function Start_Program([string]$program_name, [bool]$noexit, [bool]$admin) {
    if ($null -eq $program_name) {
        Write-Host "No program name provided" -ForegroundColor Red
        return
    }
    $argument_list = "${program_name} -executionpolicy bypass"
    if ($noexit) { $argument_list += " -NoExit"}
    try {
        if ($admin) {
            Start-Process -FilePath "conhost.exe" -ArgumentList $argument_list -Verb runasuser
        } else {
            Start-Process -FilePath "conhost.exe" -ArgumentList $argument_list
        }
        Write-Host "Started process ${program_name} as " -NoNewline
        if ($admin) { Write-Host "administrator" }
        else { Write-Host "user" }
    }
    catch {
        Write-Host "Failed to start process ${program_name} as " -NoNewline -ForegroundColor Red
        if ($admin) { Write-Host "administrator" -ForegroundColor Red }
        else { Write-Host "user" -ForegroundColor Red }
    }
}


$web_formatting = @(
    #  code, replace char
    @("+"  , " "),
    @("%2B", "+"),
    @("%20", " "),
    @("%40", "@"),
    @("%3A", ":"),
    @("%2F", "/"),
    @("%3F", "?"),
    @("%23", "#"),
    @("%26", "&"),
    @("%25", "%")
)
# this removes web formatting like %20 and replaces it with an ASCII char
function remove_web_formatting ([string]$web_string) {
    $web_formatting | ForEach-Object {
        $web_string = $web_string.Replace($_[0], $_[1])
    }
    return $web_string
}

# this grabs the results of a form submission and returns it as a PS Object
function read_form_submission ([string]$form_attributes) {
    $attributes = $form_attributes.split('&')
    $out_dict = New-Object psobject
    $attributes | foreach-object {
        $attribute_name = remove_web_formatting -web_string $_.Split('=')[0]
        $attribute_value = remove_web_formatting -web_string $_.Split('=')[1]
        $out_dict | Add-Member -MemberType NoteProperty -Name $attribute_name -Value $attribute_value
    }
    return $out_dict
}

function respond_in_JSON ([string]$Raw_input) {
    $jsonResult = $Raw_input | ConvertTo-Json
    $buffer = [Text.Encoding]::UTF8.GetBytes($jsonResult)
    $response.ContentType = "application/json"
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.OutputStream.Close()
}

function grab_JSON_input {
    if ($request.InputStream.CanRead -eq $false) {
        Write-Host "Input Stream Read Error" -ForegroundColor Red
        return
    }
    $reader = New-Object System.IO.StreamReader($request.InputStream)
    $requestBody = $reader.ReadToEnd()
    $reader.Close()
    return ConvertFrom-Json $requestBody
}

while ($listener.IsListening) {
    # wait for an incoming request
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    # error printing
    Write-Host "User $($request.RemoteEndPoint) made request $($request.RawUrl)" -ForegroundColor Cyan

    # Default actions
    if     ($request.RawUrl -eq "favicon.ico") { Serve_File "Files:\\favicon.ico" "image/x-icon" }
    elseif ($request.RawUrl -eq "/") { Serve_HTML "SitePages:\\index.html" }
    elseif ($request.RawUrl -match "\.\w+$") {
        $extension = $request.RawUrl.Split(".")[-1]
        switch ($extension) {
            "html" { Serve_HTML "SitePages:\$($request.RawUrl)"}
            "ico" { Serve_File "Files:\$($request.RawUrl)" "image/x-icon" }
            "png" { Serve_File "Files:\$($request.RawUrl)" "image/png" }
            "ps1" {
                $script_list | ForEach-Object {
                    if ($request.RawUrl -eq "/$_") {
                        Start_Script $_
                        continue
                    }
                }
                404_Not_Found
            }
            Default { 404_Not_Found }
        }
    }
    else {
        switch ($request.RawUrl) {
            "/Shutdown" {
                Shutdown_Actions
            }
            "/CMD_User" {
                Start_Program "cmd.exe" -noexit $true -admin $false
                Respond_OK -close $true
            }
            "/CMD_Admin" {
                Start_Program "cmd.exe" -noexit $true -admin $true
                Respond_OK -close $true
            }
            "/Powershell_User" {
                Start_Program "powershell.exe" -noexit $true -admin $false
                Respond_OK -close $true
            }
            "/Powershell_Admin" {
                Start_Program "powershell.exe" -noexit $true -admin $true
                Respond_OK -close $true
            }
            "/PWSH_User" {
                Start_Program "pwsh.exe" -noexit $true -admin $false
                Respond_OK -close $true
            }
            "/PWSH_Admin" {
                Start_Program "pwsh.exe" -noexit $true -admin $true
                Respond_OK -close $true
            }
            "/Enter_PSSession_Admin" {
                Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -NoExit -executionpolicy Bypass -Command `$CPU = Read-Host -Prompt `"ComputerName`"; Enter-PSSession -ComputerName `$CPU" -Verb runasuser
                Respond_OK -close $true
            }
            "/Enter_PSSession_User" {
                Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -NoExit -executionpolicy Bypass -Command `$CPU = Read-Host -Prompt `"ComputerName`"; Enter-PSSession -ComputerName `$CPU"
                Respond_OK -close $true
            }
            "/Remote_Desktop" {
                Start-Process -FilePath "mstsc.exe"
                Respond_OK -close $true
            }
            # This is broken right now fix later
            "/domain_user_query_submit" {
                $query_attributes = grab_JSON_input
                $result = & "${PSScriptRoot}\Scripts\AD_User_Lookup.ps1" $query_attributes
                respond_in_JSON $result
            }
            Default { 405_Method_Not_Allowed }
        }
    }
}