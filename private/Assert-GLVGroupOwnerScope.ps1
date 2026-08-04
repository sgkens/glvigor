# ==============================================================================
# File: Private/Assert-GLVGroupOwnerScope.ps1
# ==============================================================================
<#
.SYNOPSIS
    Stops a GitLab group operation unless the authenticated user is an owner.
.PARAMETER GroupID
    Numeric group ID or full group path.
.PARAMETER PassThru
    Returns the matched group after validation.
.PARAMETER ApiPath
    Optional alternate GitLab API v4 base URL.
.PARAMETER AccessToken
    Token used with an alternate GitLab endpoint.
#>
function Assert-GLVGroupOwnerScope {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [object]$GroupID,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru,

        [Parameter(Mandatory = $false)]
        [string]$ApiPath,

        [Parameter(Mandatory = $false)]
        [string]$AccessToken
    )

    [string]$target = [uri]::UnescapeDataString([string]$GroupID).Trim()
    if ([string]::IsNullOrWhiteSpace($target)) { throw [System.ArgumentException]::new('A GroupID or group path is required.') }

    [long]$numericGroupId = 0
    [bool]$isNumericId = [long]::TryParse($target, [ref]$numericGroupId)
    $group = @(Get-GLVOwnedGroups -ApiPath $ApiPath -AccessToken $AccessToken) | Where-Object {
        if ($isNumericId) { $_.PSObject.Properties['id'] -and [long]$_.id -eq $numericGroupId }
        else { $_.PSObject.Properties['full_path'] -and [string]::Equals([string]$_.full_path, $target, [System.StringComparison]::OrdinalIgnoreCase) }
    } | Select-Object -First 1

    if (-not $group) {
        throw [System.UnauthorizedAccessException]::new("Group '$GroupID' is outside the authenticated user's Owner scope.")
    }
    if ($PassThru) { return $group }
}
