param (
    [psobject]$query_attributes
)

$SearchAttributes = @{
    "FirstName" = $query_attributes.firstName
    "MiddleInitial" = $query_attributes.middleInitial
    "LastName" = $query_attributes.lastName
    "Email" = $query_attributes.email
    "Username" = $query_attributes.username
}

# Test Attributes
$SearchAttributes | ForEach-Object {
    if ($null -eq $_) {
        $_ -eq "*"
    } elseif ($null -match "[\*\`"]") {
        return "Search Query contains invalid characters"
    }
}

return $(systeminfo)