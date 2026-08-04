# ==============================================================================
# File: Public/Get-GLVHelp.ps1
# ==============================================================================
function Get-GLVHelp {
    <#
    .SYNOPSIS
        Displays cmdlet documentation using `uhwriter`.

    .DESCRIPTION
        Uses AST metadata extraction (`Export-UHWriterMetadata`) and `New-UHWriter` to render formatted
        documentation including syntax, parameter sets, and descriptions via `uhwriter`.

    .PARAMETER CmdletName
        Specific cmdlet name to view documentation for.

    .PARAMETER Catalog
        Switch to list the entire GLVigor cmdlet catalog using `Show-UHCommandCatalog`.

    .EXAMPLE
        Get-GLVHelp -CmdletName Request-Project
        glv help Request-Project
        glvhelp -Catalog
    #>
    [CmdletBinding()]
    [Alias('glvhelp')]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$CmdletName,

        [Parameter(Mandatory = $false)]
        [switch]$Catalog
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
    }

    process {
        # 1. Catalog Mode
        if ($Catalog) {
            Write-GLVLog -Message "Generating GLVigor Cmdlet Catalog via uhwriter..." -Level Info
            Show-UHCommandCatalog -Module 'glvigor'
            return
        }

        # 2. Command Specific Help via AST Metadata Extraction
        if ($CmdletName) {
            $cmdletFile = Join-Path $global:_glvigor.rootpath "public/$CmdletName.ps1"
            if (-not (Test-Path $cmdletFile)) {
                $match = Get-ChildItem -Path (Join-Path $global:_glvigor.rootpath "public") -Filter "$CmdletName.ps1" | Select-Object -First 1
                if ($match) { $cmdletFile = $match.FullName }
            }

            if (Test-Path $cmdletFile) {
                $meta = Export-UHWriterMetadata -Path $cmdletFile -FunctionName $CmdletName
                if ($meta -is [hashtable]) {
                    $meta['sourcetype'] = $null
                } elseif ($meta.PSObject.Properties['sourcetype']) {
                    $meta.sourcetype = $null
                }
                New-UHWriter -InputObject $meta -Layout Minimal
                return
            } else {
                Get-UHModuleCommand -Module 'glvigor' -Name $CmdletName
                return
            }
        }

        # 3. Default Module Help View
        Get-UHModuleAbout -Module 'glvigor'
    }
}
