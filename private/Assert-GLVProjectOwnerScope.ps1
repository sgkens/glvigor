# ==============================================================================
# File: Private/Assert-GLVProjectOwnerScope.ps1
# ==============================================================================
<#
.SYNOPSIS
    Stops a GitLab project operation unless the authenticated user is an owner.
.DESCRIPTION
    Resolves the owner-only project collection and matches either a numeric
    project ID or a URL-encoded path_with_namespace. The function throws before
    the caller sends its project resource request when ownership is not present.
.PARAMETER ProjectID
    Numeric GitLab project ID or path_with_namespace.
.PARAMETER PassThru
    Returns the matched project object after validation.
.PARAMETER ApiPath
    Optional alternate GitLab API v4 base URL.
.PARAMETER AccessToken
    Token used to validate ownership on an alternate GitLab endpoint.
#>
function Assert-GLVProjectOwnerScope {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [object]$ProjectID,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru,

        [Parameter(Mandatory = $false)]
        [string]$ApiPath,

        [Parameter(Mandatory = $false)]
        [string]$AccessToken
    )

    if ($null -eq $ProjectID -or [string]::IsNullOrWhiteSpace([string]$ProjectID)) {
        throw [System.ArgumentException]::new('A ProjectID or project path is required for owner-scope validation.')
    }

    [string]$target = [uri]::UnescapeDataString([string]$ProjectID).Trim()
    [long]$numericProjectId = 0
    [bool]$isNumericId = [long]::TryParse($target, [ref]$numericProjectId)
    $ownedProjects = @(Get-GLVScopedProjects -ApiPath $ApiPath -AccessToken $AccessToken)

    $project = $ownedProjects | Where-Object {
        if ($isNumericId) {
            $_.PSObject.Properties['id'] -and [long]$_.id -eq $numericProjectId
        }
        else {
            $_.PSObject.Properties['path_with_namespace'] -and
            [string]::Equals([string]$_.path_with_namespace, $target, [System.StringComparison]::OrdinalIgnoreCase)
        }
    } | Select-Object -First 1

    if (-not $project) {
        throw [System.UnauthorizedAccessException]::new(
            "Project '$ProjectID' is outside the authenticated user's owner scope. GLVigor only manages personal projects and group/subgroup projects where the user has the Owner role."
        )
    }

    if ($PassThru) {
        return $project
    }
}
