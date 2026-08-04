# ==============================================================================
# File: Private/Get-GLVScopedProjects.ps1
# ==============================================================================
<#
.SYNOPSIS
    Returns projects owned by the authenticated GitLab user or their groups.
.DESCRIPTION
    Queries GitLab's projects endpoint with Owner access level (50) and paginates
    the result. This includes personal projects and projects owned through a
    group or subgroup where the authenticated user has the Owner role.
.PARAMETER Search
    Optional project-name/path search value applied by GitLab.
.PARAMETER ApiPath
    Optional alternate GitLab API v4 base URL used by cross-instance commands.
.PARAMETER AccessToken
    Plain-text token paired with ApiPath. The value is retained only for the request.
.PARAMETER Detailed
    Requests full project metadata. The default lightweight response remains ideal
    for authorization checks and ordinary owner-scoped discovery.
#>
function Get-GLVScopedProjects {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Search,

        [Parameter(Mandatory = $false)]
        [string]$ApiPath,

        [Parameter(Mandatory = $false)]
        [string]$AccessToken,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    if (-not $ApiPath -and (-not $global:_glvigor -or -not $global:_glvigor.auth -or
        -not $global:_glvigor.auth.apipath -or -not $global:_glvigor.auth.apikey)) {
        throw [System.InvalidOperationException]::new(
            'GitLab authentication is required for scoped searches. Run Request-GitLabAuth first or use -Global intentionally.'
        )
    }

    if ($ApiPath -and -not $AccessToken) {
        throw [System.InvalidOperationException]::new('An access token is required when validating an alternate GitLab API endpoint.')
    }

    [string]$resolvedApiPath = if ($ApiPath) { $ApiPath.TrimEnd('/') } else { $global:_glvigor.auth.apipath }
    [string]$plainToken = if ($AccessToken) { $AccessToken } else { $global:_glvigor.auth.apikey | Undo-SecureString }
    $headers = @{
        Authorization = "Bearer $plainToken"
        'Content-Type' = 'application/json'
    }

    [string]$simple = if ($Detailed) { 'false' } else { 'true' }
    [string]$baseUri = "$resolvedApiPath/projects?min_access_level=50&simple=$simple&order_by=id&sort=asc"
    if ($Search) {
        $baseUri += "&search=$([uri]::EscapeDataString($Search))"
    }

    [System.Collections.Generic.List[pscustomobject]]$projects = [System.Collections.Generic.List[pscustomobject]]::new()
    [int]$page = 1
    [int]$perPage = 100

    do {
        $response = @(Invoke-RestMethod -Uri "$baseUri&page=$page&per_page=$perPage" -Method Get -Headers $headers)
        foreach ($project in $response) {
            $projects.Add($project)
        }
        $page++
    } while ($response.Count -eq $perPage)

    return $projects.ToArray()
}
