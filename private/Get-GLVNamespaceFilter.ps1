# ==============================================================================
# File: Private/Get-GLVNamespaceFilter.ps1
# ==============================================================================
<#
.SYNOPSIS
    Private helper to apply user/group ownership scope filtering on GitLab/Git Provider items.
.DESCRIPTION
    By default (when -Global is $false), filters input collections to items belonging to the
    authenticated user's space or managed organizations/groups.
    When -Global is $true (or when Global mode is toggled), returns the complete unfiltered collection.
.PARAMETER InputObject
    The array of project, repository, issue, or group objects to filter.
.PARAMETER Global
    Switch or boolean flag. If $false (default), filters by user/org scope. If $true, bypasses filtering.
#>
function Get-GLVNamespaceFilter {
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [array]$InputObject,

        [Parameter(Mandatory = $false)]
        [switch]$Global = $false
    )

    process {
        if (-not $InputObject -or $InputObject.Count -eq 0) {
            return @()
        }

        # If -Global is specified, return all items without scope filtering
        if ($Global) {
            return $InputObject
        }

        # Resolve authenticated user / org context
        [string]$currentUser = ""
        [string]$currentOrg  = ""

        if ($global:_glvigor -and $global:_glvigor.auth -and
            $global:_glvigor.auth.PSObject.Properties['username'] -and
            $global:_glvigor.auth.username) {
            $currentUser = $global:_glvigor.auth.username
        }
        elseif ($global:_glvigor -and $global:_glvigor.auth -and
                $global:_glvigor.auth.PSObject.Properties['user'] -and
                $global:_glvigor.auth.user) {
            $currentUser = $global:_glvigor.auth.user
        }
        elseif ($env:GITLAB_USER) { $currentUser = $env:GITLAB_USER }
        elseif ($env:GITHUB_USER) { $currentUser = $env:GITHUB_USER }

        if ($env:GITLAB_ORG) { $currentOrg = $env:GITLAB_ORG }
        elseif ($env:GITHUB_ORG) { $currentOrg = $env:GITHUB_ORG }

        # Filter items where owner / namespace matches current user or group space
        [System.Collections.Generic.List[pscustomobject]]$scoped = [System.Collections.Generic.List[pscustomobject]]::new()

        foreach ($item in $InputObject) {
            [bool]$isOwned = $false

            # GitLab path_with_namespace check
            if ($item.PSObject.Properties['path_with_namespace']) {
                [string]$nsPath = $item.path_with_namespace
                if ($currentUser -and $nsPath.StartsWith("$currentUser/", [System.StringComparison]::OrdinalIgnoreCase)) { $isOwned = $true }
                elseif ($currentOrg -and $nsPath.StartsWith("$currentOrg/", [System.StringComparison]::OrdinalIgnoreCase)) { $isOwned = $true }
            }

            # Global issue and merge-request search results do not include
            # path_with_namespace. Their web URL still begins with the owning
            # user/group namespace, so use it as the ownership source.
            if (-not $isOwned -and $item.PSObject.Properties['web_url'] -and $item.web_url) {
                [uri]$itemUri = $null
                if ([uri]::TryCreate([string]$item.web_url, [UriKind]::Absolute, [ref]$itemUri)) {
                    [string]$resourcePath = [uri]::UnescapeDataString($itemUri.AbsolutePath).TrimStart('/')
                    if ($currentUser -and $resourcePath.StartsWith("$currentUser/", [System.StringComparison]::OrdinalIgnoreCase)) { $isOwned = $true }
                    elseif ($currentOrg -and $resourcePath.StartsWith("$currentOrg/", [System.StringComparison]::OrdinalIgnoreCase)) { $isOwned = $true }
                }
            }

            # Generic owner string check (GitHub / Gitea / OGP)
            if (-not $isOwned -and $item.PSObject.Properties['owner']) {
                [string]$itemOwner = if ($item.owner -is [pscustomobject]) { $item.owner.login } else { [string]$item.owner }
                if ($currentUser -and $itemOwner.Equals($currentUser, [System.StringComparison]::OrdinalIgnoreCase)) { $isOwned = $true }
                elseif ($currentOrg -and $itemOwner.Equals($currentOrg, [System.StringComparison]::OrdinalIgnoreCase)) { $isOwned = $true }
            }

            # Missing ownership context must never broaden a default request to
            # global results. -Global is the only supported bypass.
            if (-not $currentUser -and -not $currentOrg) {
                $isOwned = $false
            }

            if ($isOwned) {
                $scoped.Add($item)
            }
        }

        return $scoped.ToArray()
    }
}
