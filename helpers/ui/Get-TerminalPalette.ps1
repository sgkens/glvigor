# ==============================================================================
# File: helpers/ui/Get-TerminalPalette.ps1
# ==============================================================================
function Get-TerminalPalette {
    <#
    .SYNOPSIS
        Resolves color palettes for TUI components.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$ColorPalette = @{ Border = "38;5;240"; Title = "38;5;255" }
    )

    process {
        return [PSCustomObject]@{
            GetStaticColor = {
                param($key)
                if ($ColorPalette.ContainsKey($key)) { return $ColorPalette[$key] }
                return "38;5;255"
            }
            Apply = {
                param($text, $colorCode)
                return "`e[${colorCode}m${text}`e[0m"
            }
        }
    }
}
