# ==============================================================================
# File: Private/Get-GLVStatusCache.ps1
# ==============================================================================
<#
.SYNOPSIS
    Provides durable, atomic storage for the owner-space status snapshot.
.DESCRIPTION
    Keeps status reads local unless the user explicitly requests an update or no
    cache exists. The cache contains normalized GitLab metadata only; credentials
    and request headers are never serialized.
#>
function Get-GLVStatusCachePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    [string]$configPath = if ($global:_glvigor -and $global:_glvigor.configPath) {
        $global:_glvigor.configPath
    } else {
        [IO.Path]::Combine([Environment]::GetFolderPath('UserProfile'), '.phellams', 'glvigor', 'config.json')
    }

    return [IO.Path]::Combine([IO.Path]::GetDirectoryName($configPath), 'status-cache.json')
}

function Read-GLVStatusCache {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-GLVStatusCachePath)
    )

    if (-not [IO.File]::Exists($Path)) { return $null }

    try {
        $cache = [IO.File]::ReadAllText($Path) | ConvertFrom-Json -Depth 20
        if (-not $cache -or -not $cache.PSObject.Properties['SchemaVersion'] -or $cache.SchemaVersion -ne 1) {
            Write-Verbose "Ignoring incompatible GLVigor status cache at '$Path'."
            return $null
        }
        return $cache
    } catch {
        Write-Verbose "Ignoring unreadable GLVigor status cache at '$Path': $($_.Exception.Message)"
        return $null
    }
}

function Write-GLVStatusCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Status,

        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-GLVStatusCachePath)
    )

    [string]$directory = [IO.Path]::GetDirectoryName($Path)
    [void][IO.Directory]::CreateDirectory($directory)
    [string]$temporaryPath = [IO.Path]::Combine($directory, ".$([IO.Path]::GetRandomFileName()).tmp")

    try {
        [string]$json = $Status | ConvertTo-Json -Depth 20
        [IO.File]::WriteAllText($temporaryPath, $json, [Text.UTF8Encoding]::new($false))
        [IO.File]::Move($temporaryPath, $Path, $true)
    } finally {
        if ([IO.File]::Exists($temporaryPath)) {
            [IO.File]::Delete($temporaryPath)
        }
    }
}
