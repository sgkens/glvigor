# ==============================================================================
# File: Private/Invoke-GLVFormCard.ps1
# ==============================================================================
<#
.SYNOPSIS
    Interactive Alt-Buffer TUI Form Card for Create ('C') and Update ('U') actions.
.DESCRIPTION
    Presents an interactive keyboard-navigable card form in Alt-Buffer for collecting or editing
    parameters before invoking public cmdlets. Supports field pre-population for updates,
    subtle Orange->Blue gradient borders, live input preview, and Esc/Enter action keys.
#>

function Invoke-GLVFormCard {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [array]$Fields,

        [Parameter(Mandatory = $false)]
        [object]$ExistingData
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    # Fallback for non-interactive / redirected console environments
    if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) {
        Write-GLVLog -Message "Non-interactive host detected. Prompting via console..." -Level Warning
        $result = @{}
        foreach ($f in $Fields) {
            $def = if ($ExistingData -and $ExistingData.PSObject.Properties[$f.name]) { $ExistingData.$($f.name) } elseif ($f.default) { $f.default } else { "" }
            $val = Read-Host -Prompt "[$($f.label)] (Default: '$def')"
            $result[$f.name] = if ($val) { $val } else { $def }
        }
        return $result
    }

    $esc = [char]27
    $reset = "${esc}[0m"
    $selectedStyle = "${esc}[7m"
    $hideCursor = "${esc}[?25l"
    $showCursor = "${esc}[?25h"
    $enterAlt = "${esc}[?1049h"
    $leaveAlt = "${esc}[?1049l"

    # Pre-populate field values if ExistingData is supplied
    $values = @{}
    foreach ($f in $Fields) {
        $existingVal = if ($ExistingData -and $ExistingData.PSObject.Properties[$f.name]) {
            $ExistingData.$($f.name)
        } elseif ($ExistingData -and $ExistingData -is [hashtable] -and $ExistingData.ContainsKey($f.name)) {
            $ExistingData[$f.name]
        } else { $null }

        $values[$f.name] = if ($null -ne $existingVal) {
            $existingVal.ToString()
        } elseif ($f.default) {
            $f.default.ToString()
        } else { "" }
    }

    $fieldIndex = 0
    $fieldCount = $Fields.Count

    try {
        [Console]::Write($enterAlt + $hideCursor)

        while ($true) {
            $width = [Math]::Max(60, [Math]::Min(90, [Console]::WindowWidth))
            $height = [Math]::Max(12, [Console]::WindowHeight)

            $builder = [System.Text.StringBuilder]::new()
            [void]$builder.Append("${esc}[2J${esc}[H")

            # Border gradient stops (Orange 208 -> Blue 33)
            $borderSteps = @(208, 166, 130, 74, 39, 33)

            # Header Banner
            $cardHeaderRaw = "┌─ CARD: $Title ──"
            $cardHeaderRaw = $cardHeaderRaw.PadRight($width - 1, [char]'─') + "┐"
            [void]$builder.AppendLine((New-AsciiGradient -Type fg -Steps $borderSteps -String $cardHeaderRaw))

            [void]$builder.AppendLine("│ " + (" " * ($width - 4)) + " │")

            # Render Fields
            for ($i = 0; $i -lt $fieldCount; $i++) {
                $f = $Fields[$i]
                $reqMark = if ($f.required) { "*" } else { " " }
                $labelStr = "$reqMark $($f.label):".PadRight(20)
                $currentVal = $values[$f.name]

                $inputBoxWidth = $width - 26
                if ($currentVal.Length -gt ($inputBoxWidth - 2)) {
                    $currentVal = $currentVal.Substring(0, [Math]::Max(1, $inputBoxWidth - 3)) + "…"
                }

                $boxContent = (" " + $currentVal).PadRight($inputBoxWidth)

                if ($i -eq $fieldIndex) {
                    $fieldLine = "│ $labelStr " + "${selectedStyle}[${boxContent}]${reset}" + " │"
                } else {
                    $fieldLine = "│ $labelStr [${boxContent}] │"
                }

                [void]$builder.AppendLine($fieldLine)
            }

            [void]$builder.AppendLine("│ " + (" " * ($width - 4)) + " │")

            # Card Footer
            $footerRaw = "└" + ("─" * ($width - 2)) + "┘"
            [void]$builder.AppendLine((New-AsciiGradient -Type fg -Steps $borderSteps -String $footerRaw))

            # Controls Help Line
            [void]$builder.AppendLine("  " + (New-AsciiGradient -Type fg -Steps @(214, 39) -String "<Up/Down/Tab> Field  |  <Type> Input  |  <Backspace> Delete  |  <Enter> Submit  |  <Esc> Cancel"))

            [Console]::Write($builder.ToString())

            # Handle Key Input
            $key = [Console]::ReadKey($true)

            switch ($key.Key) {
                UpArrow {
                    $fieldIndex = if ($fieldIndex -gt 0) { $fieldIndex - 1 } else { $fieldCount - 1 }
                }
                DownArrow {
                    $fieldIndex = ($fieldIndex + 1) % $fieldCount
                }
                Tab {
                    $fieldIndex = ($fieldIndex + 1) % $fieldCount
                }
                Backspace {
                    $fn = $Fields[$fieldIndex].name
                    if ($values[$fn].Length -gt 0) {
                        $values[$fn] = $values[$fn].Substring(0, $values[$fn].Length - 1)
                    }
                }
                Enter {
                    # Return hashtable result on Enter
                    [Console]::Write($leaveAlt + $showCursor)
                    return $values
                }
                Escape {
                    # Cancel on Escape
                    [Console]::Write($leaveAlt + $showCursor)
                    return $null
                }
                default {
                    if ($key.KeyChar -and -not [char]::IsControl($key.KeyChar)) {
                        $fn = $Fields[$fieldIndex].name
                        $values[$fn] += $key.KeyChar
                    }
                }
            }
        }
    }
    finally {
        [Console]::Write($reset + $showCursor + $leaveAlt)
    }
}
