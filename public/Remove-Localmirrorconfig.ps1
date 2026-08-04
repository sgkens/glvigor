# ==============================================================================
# File: Public/Remove-Localmirrorconfig.ps1
# ==============================================================================
<#
.SYNOPSIS
Removes the local Git remote mirror configuration.

.DESCRIPTION
Executes Git commands to remove the local remote mirror configuration from the repository context.

.EXAMPLE
Remove-Localmirrorconfig
#>
function Remove-Localmirrorconfig {
    [CmdletBinding()]
    param()

    process {
        Write-GLVLog -Message "Removing local git remote mirror configuration..." -Level Info
        git remote remove mirror 2>$null
    }
}