# Create a new HttpListener instance
$listener = New-Object System.Net.HttpListener

# Listening prefix
$prefix = "http://127.0.0.1:9090/"
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
        $global:response.StatusCode = 200
        $global:response.StatusDescription = "OK"
    } else {
        Write-Host "Invalid Path" -ForegroundColor Red
        $responseString = get-content -path "${PSScriptRoot}\Redirect\404.html"
        $global:response.StatusCode = 400
        $global:response.StatusDescription = "Not Found"
    }
    $buffer = [Text.Encoding]::UTF8.GetBytes($responseString)
    $global:response.ContentLength64 = $buffer.Length
    $global:response.OutputStream.Write($buffer, 0, $buffer.Length)
    $global:response.OutputStream.Close()
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
    $global:response.ContentType = $Type
    if (Test-Path -Path "$Path" -PathType Leaf) {
        Write-Host "Valid Path" -ForegroundColor Green
        $imageBytes = [System.IO.File]::ReadAllBytes((Convert-Path "$Path"))
        $global:response.ContentLength64 = $imageBytes.Length
        $global:response.OutputStream.Write($imageBytes, 0, $imageBytes.Length)
        $global:response.StatusCode = 200
        $global:response.StatusDescription = "OK"
    } else {
        Write-Host "Invalid Path" -ForegroundColor Red
        $global:response.StatusCode = 404
        $global:response.StatusDescription = "Not Found"
    }
    $global:response.OutputStream.Close()
}

function Shutdown_Actions {
    Write-Host "Shutting down the server" -ForegroundColor Red
    $global:response.StatusCode = 200
    $global:response.StatusDescription = "OK"
    $global:response.OutputStream.Close()
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
    Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -executionpolicy Bypass -File ${PSScriptRoot}/Scripts/${script_name}"
    $global:response.StatusCode = 200
    $global:response.StatusDescription = "OK"
    $global:response.OutputStream.Close()
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

while ($listener.IsListening) {
    # wait for an incoming request
    $global:context = $listener.GetContext()
    $global:request = $context.Request
    $global:response = $context.Response

    # error printing
    Write-Host "User $($request.RemoteEndPoint) made request $($request.RawUrl)" -ForegroundColor Cyan

    # checks against malicious activity
    #if ($request.RawUrl -match "..|[^a-zA-Z0-9/\.]") { Serve_HTML ".\Redirect\403.html" $response; continue } # invalid characters
    
    # Default actions
    if     ($request.RawUrl -eq "favicon.ico") { Serve_File "Files:\\favicon.ico" "image/x-icon" }
    elseif ($request.RawUrl -eq "/") { Serve_HTML "SitePages:\\index.html" }
    elseif ($request.RawUrl -match "\?") {
        switch ($request.RawUrl.Split('?')[0]) {
            "/Server_Management/Domain_User_Query.html" {
                $query_attributes = read_form_submission $request.RawUrl.Split('?')[1]
                $query_attributes
            }
            Default { 
                write-Host "Bad Query" -ForegroundColor Red
                405_Method_Not_Allowed 
            }
        }
        
    }
    elseif ($request.RawUrl -match "\.ps1$") {
        $script_list | ForEach-Object {
            if ($request.RawUrl -eq "/$_") {
                Start_Script $_
                continue
            }
        }
        405_Method_Not_Allowed
    }
    elseif ($request.RawUrl -match "\.\w+$") {
        $extension = $request.RawUrl.Split(".")[-1]
        switch ($extension) {
            "html" { Serve_HTML "SitePages:\$($request.RawUrl)" }
            "ico" { Serve_File "Files:\$($request.RawUrl)" "image/x-icon" }
            "png" { Serve_File "Files:\$($request.RawUrl)" "image/png" }
            "jpg" { Serve_File "Files:\$($request.RawUrl)" "image/jpeg" }
            "jpeg" { Serve_File "Files:\$($request.RawUrl)" "image/jpeg" }
            "gif" { Serve_File "Files:\$($request.RawUrl)" "image/gif" }
            "xml" { Serve_File "Files:\$($request.RawUrl)" "application/xml" }
            "pdf" { Serve_File "Files:\$($request.RawUrl)" "application/pdf" }
            Default { 404_Not_Found }
        }
    }
    else {
        switch ($request.RawUrl) {
            "/Shutdown" { Shutdown_Actions }
            "/CMD_User" { Start-Process -FilePath "conhost.exe" -ArgumentList "cmd.exe -NoExit -executionpolicy Bypass" }
            "/CMD_Admin" { Start-Process -FilePath "conhost.exe" -ArgumentList "cmd.exe -NoExit -executionpolicy Bypass" -Verb Runas}
            "/Powershell_User" { Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -NoExit -executionpolicy Bypass"}
            "/Powershell_Admin"{ Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -NoExit -executionpolicy Bypass" -Verb Runas}
            "/Enter_PSSession_Admin" { Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -NoExit -executionpolicy Bypass -Command Enter-PSSession" -Verb Runas }
            "/Enter_PSSession_User" { Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -NoExit -executionpolicy Bypass -Command Enter-PSSession" }
            Default { 405_Method_Not_Allowed }
        }
    }
}