# ==============================================================================
# File: Private/Get-GLVOwnedGroups.ps1
# ==============================================================================
<#
.SYNOPSIS
    Returns GitLab groups where the authenticated user has Owner access.
.DESCRIPTION
    Queries the groups endpoint with min_access_level=50 and returns all pages.
.PARAMETER Search
    Optional group name or path search value.
.PARAMETER ApiPath
    Optional alternate GitLab API v4 base URL.
.PARAMETER AccessToken
    Token used with an alternate GitLab endpoint.
#>
function Get-GLVOwnedGroups {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Search,

        [Parameter(Mandatory = $false)]
        [string]$ApiPath,

        [Parameter(Mandatory = $false)]
        [string]$AccessToken
    )

    if (-not $ApiPath -and (-not $global:_glvigor -or -not $global:_glvigor.auth -or
        -not $global:_glvigor.auth.apipath -or -not $global:_glvigor.auth.apikey)) {
        throw [System.InvalidOperationException]::new('GitLab authentication is required for owner-scoped group operations.')
    }
    if ($ApiPath -and -not $AccessToken) {
        throw [System.InvalidOperationException]::new('An access token is required when validating an alternate GitLab API endpoint.')
    }

    [string]$resolvedApiPath = if ($ApiPath) { $ApiPath.TrimEnd('/') } else { $global:_glvigor.auth.apipath }
    [string]$plainToken = if ($AccessToken) { $AccessToken } else { $global:_glvigor.auth.apikey | Undo-SecureString }
    $headers = @{ Authorization = "Bearer $plainToken"; 'Content-Type' = 'application/json' }
    [string]$baseUri = "$resolvedApiPath/groups?min_access_level=50&order_by=id&sort=asc"
    if ($Search) { $baseUri += "&search=$([uri]::EscapeDataString($Search))" }

    [System.Collections.Generic.List[pscustomobject]]$groups = [System.Collections.Generic.List[pscustomobject]]::new()
    [int]$page = 1
    [int]$perPage = 100
    do {
        $response = @(Invoke-RestMethod -Uri "$baseUri&page=$page&per_page=$perPage" -Method Get -Headers $headers)
        foreach ($group in $response) { $groups.Add($group) }
        $page++
    } while ($response.Count -eq $perPage)

    return $groups.ToArray()
}
