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
        $response.StatusCode = 200
        $response.StatusDescription = "OK"
    } else {
        Write-Host "Invalid Path" -ForegroundColor Red
        $responseString = get-content -path "${PSScriptRoot}\Redirect\404.html"
        $response.StatusCode = 400
        $response.StatusDescription = "Not Found"
    }
    $buffer = [Text.Encoding]::UTF8.GetBytes($responseString)
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.OutputStream.Close()
}

# shorthand functions for redirects
function 404_Not_Found { 
    Write-Host "Error 404 Page Not Found" -ForegroundColor Red
    Serve_HTML "${PSScriptRoot}\Redirect\404.html"
}
function 403_Access_Denied { 
    Write-Host "Error 403 Access Denied" -ForegroundColor Red
    Serve_HTML "${PSScriptRoot}\Redirect\403.html"
}
function 405_Method_Not_Allowed { 
    Write-Host "Error 405 Method Not Allowed" -ForegroundColor Red
    Serve_HTML "${PSScriptRoot}\Redirect\405.html"
}
function 500_Internal_Server_Error { 
    Write-Host "Error 500 Internal Server Error" -ForegroundColor Red
    Serve_HTML "${PSScriptRoot}\Redirect\500.html"
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
        $response.StatusCode = 200
        $response.StatusDescription = "OK"
    } else {
        Write-Host "Invalid Path" -ForegroundColor Red
        $response.StatusCode = 404
        $response.StatusDescription = "Not Found"
    }
    $response.OutputStream.Close()
}

function Shutdown_Actions {
    Write-Host "Shutting down the server" -ForegroundColor Red
    $response.StatusCode = 200
    $response.StatusDescription = "OK"
    $response.OutputStream.Close()
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
            Start-Process -FilePath "conhost.exe" -ArgumentList $argument_list -Verb runas
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
            "/Shutdown" { Shutdown_Actions }
            "/CMD_User" { Start_Program "cmd.exe" -noexit $true -admin $false }
            "/CMD_Admin" { Start_Program "cmd.exe" -noexit $true -admin $true }
            "/Powershell_User" { Start_Program "powershell.exe" -noexit $true -admin $false }
            "/Powershell_Admin"{ Start_Program "powershell.exe" -noexit $true -admin $true }
            "/Enter_PSSession_Admin" { Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -NoExit -executionpolicy Bypass -Command `$CPU = Read-Host -Prompt `"ComputerName`"; Enter-PSSession -ComputerName `$CPU" -Verb Runas }
            "/Enter_PSSession_User" { Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -NoExit -executionpolicy Bypass -Command `$CPU = Read-Host -Prompt `"ComputerName`"; Enter-PSSession -ComputerName `$CPU" }
            "/domain_user_query_submit" {
                $query_attributes = grab_JSON_input
                $result = & "${PSScriptRoot}\Scripts\AD_User_Lookup.ps1" $query_attributes
                respond_in_JSON $result
            }
            Default { 405_Method_Not_Allowed }
        }
    }
}