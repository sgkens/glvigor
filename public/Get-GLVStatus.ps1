# ==============================================================================
# File: Public/Get-GLVStatus.ps1
# ==============================================================================
<#
.SYNOPSIS
    Shows a cache-first dashboard for the authenticated user's GitLab owner space.
.DESCRIPTION
    Reads normalized status metadata from the local cache by default. Use -Update
    to refresh projects, groups, and assigned task metadata from GitLab. A missing
    or incompatible cache is refreshed automatically.
.PARAMETER Update
    Refreshes status metadata from GitLab and atomically replaces the cache.
.PARAMETER Raw
    Returns the complete status snapshot as a PSCustomObject without rendering.
.PARAMETER CachePath
    Overrides the default ~/.phellams/glvigor/status-cache.json location.
.EXAMPLE
    glv status
.EXAMPLE
    glv status -Update
.EXAMPLE
    glv status -Raw | Select-Object -ExpandProperty RecentProjects
#>
function Get-GLVStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Update,

        [Parameter(Mandatory = $false)]
        [switch]$Raw,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Thin', 'Double', 'Rounded', 'None')]
        [string]$BorderStyle = 'Rounded',

        [Parameter(Mandatory = $false)]
        [string]$CachePath = (Get-GLVStatusCachePath)
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $status = if ($Update) { $null } else { Read-GLVStatusCache -Path $CachePath }
    if ($status -and $global:_glvigor.auth) {
        [string]$cachedHost = ([string]$status.Host).TrimEnd('/')
        [string]$sessionHost = ([string]$global:_glvigor.auth.hostname).TrimEnd('/')
        [string]$cachedUser = [string]$status.User.Username
        [string]$sessionUser = [string]$global:_glvigor.auth.username
        if ($cachedHost -ne $sessionHost -or $cachedUser -ne $sessionUser) {
            Write-Verbose 'The status cache belongs to a different GitLab session and will be refreshed.'
            $status = $null
        }
    }

    [bool]$refreshed = $false
    if (-not $status) {
        $status = Get-GLVStatusSnapshot
        Write-GLVStatusCache -Status $status -Path $CachePath
        $refreshed = $true
    }

    [timespan]$cacheAge = [datetime]::UtcNow - ([datetime]$status.GeneratedAtUtc).ToUniversalTime()
    $status | Add-Member -MemberType NoteProperty -Name Cache -Force -Value ([pscustomobject]@{
        Path       = $CachePath
        Refreshed  = $refreshed
        AgeHours   = [math]::Round([math]::Max(0, $cacheAge.TotalHours), 2)
        IsStale    = ($cacheAge.TotalHours -ge 24)
    })

    if ($Raw) { return $status }
    Show-GLVStatus -Status $status -BorderStyle $BorderStyle
}
