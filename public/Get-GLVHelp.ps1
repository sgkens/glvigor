# ==============================================================================
# File: Public/Get-GLVHelp.ps1
# ==============================================================================
function Get-GLVHelp {
    <#
    .SYNOPSIS
        Displays rich cmdlet documentation using `Export-UHWriterMetadata`, `New-UHWriter`, and `Invoke-UHPager`.

    .DESCRIPTION
        Uses AST metadata extraction (`Export-UHWriterMetadata`) to render formatted `uhwriter`
        documentation including syntax, parameter sets, and descriptions. Supports an interactive alt-buffer
        TUI pager scroller via `-Pager` and catalog rendering via `-Catalog`.

    .PARAMETER CmdletName
        Specific cmdlet name to view documentation for.

    .PARAMETER Catalog
        Switch to list the entire GLVigor cmdlet catalog using `Show-UHCommandCatalog`.

    .PARAMETER Pager
        Switch to render the help output in an interactive full-screen alt-buffer TUI scroller (`Invoke-UHPager`).

    .EXAMPLE
        Get-GLVHelp -CmdletName Request-Project
        glv help Request-Project -Pager
        glvhelp -Catalog
    #>
    [CmdletBinding()]
    [Alias('glvhelp')]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$CmdletName,

        [Parameter(Mandatory = $false)]
        [switch]$Catalog,

        [Parameter(Mandatory = $false)]
        [switch]$Pager
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
                # Case-insensitive resolution check
                $match = Get-ChildItem -Path (Join-Path $global:_glvigor.rootpath "public") -Filter "$CmdletName.ps1" | Select-Object -First 1
                if ($match) { $cmdletFile = $match.FullName }
            }

            if (Test-Path $cmdletFile) {
                $meta = Export-UHWriterMetadata -Path $cmdletFile -FunctionName $CmdletName
                if ($Pager) {
                    # Render via uhwriter and pipe into interactive Alt-Buffer TUI Pager
                    $helpText = New-UHWriter -InputObject $meta | Out-String
                    $helpText | Invoke-UHPager -Title "GLVigor Help: $CmdletName" -KeepOutput
                } else {
                    # Standard Console Output
                    New-UHWriter -InputObject $meta
                }
                return
            } else {
                # Fallback to Get-UHModuleCommand if path not matched directly
                if ($Pager) {
                    $helpText = Get-UHModuleCommand -Module 'glvigor' -Name $CmdletName | Out-String
                    $helpText | Invoke-UHPager -Title "GLVigor Help: $CmdletName" -KeepOutput
                } else {
                    Get-UHModuleCommand -Module 'glvigor' -Name $CmdletName
                }
                return
            }
        }

        # 3. Default Module Help View
        if ($Pager) {
            $aboutText = Get-UHModuleAbout -Module 'glvigor' | Out-String
            $aboutText | Invoke-UHPager -Title "GLVigor Module Help" -KeepOutput
        } else {
            Get-UHModuleAbout -Module 'glvigor'
        }
    }
}
