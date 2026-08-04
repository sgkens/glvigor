# ==============================================================================
# File: Private/Get-GitContext.ps1
# ==============================================================================
function Get-GitContext {
    <#
    .SYNOPSIS
        Auto-discovers GitLab project path or ID from local git configuration.
    .DESCRIPTION
        Reads .git/config in the current working directory to extract origin remote details.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
    }

    process {
        $gitConfigPath = [System.IO.Path]::Combine((Get-Location).Path, '.git', 'config')
        if (-not [System.IO.File]::Exists($gitConfigPath)) {
            return $null
        }

        try {
            $lines = [System.IO.File]::ReadAllLines($gitConfigPath)
            $urlLine = $lines | Where-Object { $_ -match 'url\s*=\s*' } | Select-Object -First 1

            if ($urlLine) {
                $rawUrl = ($urlLine -split '=')[1].Trim()
                # Parse git@gitlab.com:owner/repo.git or https://gitlab.com/owner/repo.git
                $projectPath = $rawUrl -replace '^git@[^:]+:', '' -replace '^https?://[^/]+/', '' -replace '\.git$', ''
                return [PSCustomObject]@{
                    RawUrl      = $rawUrl
                    ProjectPath = $projectPath
                }
            }
        }
        catch {
            Write-GLVLog -Message "Failed to parse local .git/config: $($_.Exception.Message)" -Level Debug
        }

        return $null
    }
}
