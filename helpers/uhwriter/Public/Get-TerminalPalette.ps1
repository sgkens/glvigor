function Get-TerminalPalette {
    <#
    .SYNOPSIS
      Returns a dynamically generated terminal palette object.
    .DESCRIPTION
      Returns a hashtable-like custom object containing Apply, GetFillColor, and GetStaticColor scriptblocks.
      Handles RGB arrays, names, and 256-color indices.
    .PARAMETER ColorPalette
      A hashtable defining the static colors.
    .PARAMETER ColorMode
      Color mode: 'Solid', 'Conditional', or 'Gradient'.
    .PARAMETER ColorThresholds
      A hashtable of thresholds for conditional mode.
    .PARAMETER GradientStart
      RGB array [r, g, b] for gradient start.
    .PARAMETER GradientEnd
      RGB array [r, g, b] for gradient end.
    .PARAMETER CurrentValue
      Current value for conditional threshold check.
    .PARAMETER MaxValue
      Maximum value. Default is 100.
    .ALIAS terpal, Get-TerminalPallete
    #>
    [CmdletBinding()]
    [Alias('terpal', 'Get-TerminalPallete')]
    param (
        [hashtable]$ColorPalette,
        [string]$ColorMode,
        [hashtable]$ColorThresholds,
        [int[]]$GradientStart,
        [int[]]$GradientEnd,
        [int]$CurrentValue,
        [int]$MaxValue = 100
    )

    $esc = [char]27
    $reset = "$esc[0m"

    $parseColor = {
        param($Value)
        if ($null -eq $Value) { return $null }
        if ($Value -is [array] -and $Value.Count -ge 3) {
            return "38;2;$([int]$Value[0]);$([int]$Value[1]);$([int]$Value[2])"
        }
        return [string]$Value
    }

    $paletteObj = [PSCustomObject]@{
        Apply  = {
            param([string]$Text, [string]$Code)
            if ([string]::IsNullOrWhiteSpace($Code) -or [string]::IsNullOrEmpty($Text)) { return $Text }
            return "$esc[$Code`m$Text$reset"
        }.GetNewClosure()

        GetFillColor = {
            param([int]$Index, [int]$TotalFill)

            if ($ColorMode -eq 'Conditional') {
                $matchingThreshold = $null
                $minKey = [int]::MaxValue
                foreach ($k in $ColorThresholds.Keys) {
                    if ($k -ge $CurrentValue -and $k -lt $minKey) {
                        $minKey = $k
                        $matchingThreshold = $k
                    }
                }
                if ($null -ne $matchingThreshold) {
                    return (& $parseColor $ColorThresholds[$matchingThreshold])
                }
                return $null
            }

            if ($ColorMode -eq 'Gradient') {
                $ratio = 0
                if ($TotalFill -gt 1) { $ratio = $Index / ($TotalFill - 1) }
                $r = [math]::Round($GradientStart[0] + ($GradientEnd[0] - $GradientStart[0]) * $ratio)
                $g = [math]::Round($GradientStart[1] + ($GradientEnd[1] - $GradientStart[1]) * $ratio)
                $b = [math]::Round($GradientStart[2] + ($GradientEnd[2] - $GradientStart[2]) * $ratio)
                return "38;2;$r;$g;$b"
            }

            # Default Solid
            foreach ($k in $ColorPalette.Keys) {
                if ($k -ieq 'Fill') {
                    return (& $parseColor $ColorPalette[$k])
                }
            }
            return $null
        }.GetNewClosure()

        GetStaticColor = {
            param([string]$Key)
            foreach ($k in $ColorPalette.Keys) {
                if ($k -ieq $Key) {
                    return (& $parseColor $ColorPalette[$k])
                }
            }
            return $null
        }.GetNewClosure()
    }

    return $paletteObj
}
