param (
    [string]$jsonInput
)

# Convert JSON input to a PowerShell object
$jsonObject = $jsonInput | ConvertFrom-Json

# Extract conversion_type and input_data
$conversionType = $jsonObject.conversion_type
$inputData = $jsonObject.input_data

$Output = ""
try {
    switch ($conversionType) {
        "text-to-hex" { 
            $output = ($inputData.ToCharArray() | ForEach-Object { "{0:X2}" -f [byte]$_ }) -join " " 
        }
        "hex-to-text" {
            $output = -join ($inputData -split ' ' | ForEach-Object { [char][byte]("0x$_") })
        }
        "text-to-binary" {
            $output = ($inputData.ToCharArray() | ForEach-Object { [convert]::ToString([byte]$_, 2).PadLeft(8, '0') }) -join " "
        }
        "binary-to-text" {
            $output = -join ($inputData -split ' ' | ForEach-Object { [char][convert]::ToInt32($_, 2) })
        }
        "text-to-base64" {
            $output = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($inputData))
        }
        "base64-to-text" {
            $output = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($inputData))
        }
        "md5" {
            $md5 = [System.Security.Cryptography.MD5]::Create()
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($inputData)
            $hash = $md5.ComputeHash($bytes)
            $output = [BitConverter]::ToString($hash) -replace '-', ''
        }
        "sha1" {
            $sha1 = [System.Security.Cryptography.SHA1]::Create()
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($inputData)
            $hash = $sha1.ComputeHash($bytes)
            $output = [BitConverter]::ToString($hash) -replace '-', ''
        }
        "sha256" {
            $sha256 = [System.Security.Cryptography.SHA256]::Create()
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($inputData)
            $hash = $sha256.ComputeHash($bytes)
            $output = [BitConverter]::ToString($hash) -replace '-', ''
        }
        "sha384" {
            $sha384 = [System.Security.Cryptography.SHA384]::Create()
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($inputData)
            $hash = $sha384.ComputeHash($bytes)
            $output = [BitConverter]::ToString($hash) -replace '-', ''
        }
        "sha512" {
            $sha512 = [System.Security.Cryptography.SHA512]::Create()
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($inputData)
            $hash = $sha512.ComputeHash($bytes)
            $output = [BitConverter]::ToString($hash) -replace '-', ''
        }
        Default { $output = "Unsupported conversion" }
    }
}
catch {
    $output = "Error: $_"
}

return @{
    output = $output
}