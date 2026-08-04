# ==============================================================================
# File: Private/Write-GLVTuiRender.ps1
# ==============================================================================
<#
.SYNOPSIS
    TUI Output Engine for GLVigor rendering panels, tables, trees, and status tags.
.DESCRIPTION
    Provides modern 2026 TUI layout rendering adhering to phellams-aa padding rules,
    fluent-ui-v1 design aesthetics, subtle Orange->Blue gradient borders, offset title gradients,
    and automatic 24-bit/256/16-color ANSI fallbacks.
#>

function ConvertTo-GLVStatusTag {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Value
    )

    if (-not $Value) { return "[PND] " }

    switch -Regex ($Value.ToLower()) {
        '^(opened|active|merged|success|ok|true|enabled|passed)$' { return "[OK]   " }
        '^(failed|error|err|false|disabled)$'                    { return "[ERR]  " }
        '^(running|run|in_progress)$'                             { return "[RUN]  " }
        '^(pending|created|pnd|opened_new)$'                      { return "[PND]  " }
        '^(canceled|cancelled|cxl|closed)$'                       { return "[CXL]  " }
        '^(skipped|skp)$'                                         { return "[SKP]  " }
        '^(warning|warn|degraded|needs_attention)$'               { return "[WARN] " }
        '^(protected|locked|lock)$'                               { return "[LOCK] " }
        default                                                   { return "[$($Value.ToUpper().PadRight(4).Substring(0,4))] " }
    }
}

function Get-GLVCharset {
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$Override)

    if ($Override) { return $Override }
    $redirected = [Console]::IsOutputRedirected
    $vt = $Host.UI.SupportsVirtualTerminal
    $encodingOk = ([Console]::OutputEncoding.CodePage -eq 65001)

    if (-not $redirected -and $vt -and $encodingOk) { 'Unicode' } else { 'Ascii' }
}

function Write-GLVPanel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [hashtable]$Data,

        [Parameter(Mandatory = $false)]
        [string]$Charset
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $mode = Get-GLVCharset -Override $Charset
    $esc = [char]27

    # Glyph sets
    $glyphs = if ($mode -eq 'Unicode') {
        @{ TL = "┌"; TR = "┐"; BL = "└"; BR = "┘"; H = "─"; V = "│" }
    } else {
        @{ TL = "+"; TR = "+"; BL = "+"; BR = "+"; H = "-"; V = "|" }
    }

    $termWidth = if ([Console]::IsOutputRedirected) { 66 } else { [Math]::Max(50, [Math]::Min(100, [Console]::WindowWidth)) }
    $contentWidth = $termWidth - 4

    # Calculate padding before SGR encoding
    $longestLabel = 12
    foreach ($key in $Data.Keys) {
        if ($key.ToString().Length -gt $longestLabel) {
            $longestLabel = $key.ToString().Length
        }
    }
    $labelColWidth = $longestLabel + 2

    # Subtle Orange (208) -> Blue (33) border stops
    $borderSteps = @(208, 166, 130, 74, 39, 33)

    # Top border with gradient title
    $titleStr = " $Title "
    $titleLen = $titleStr.Length
    $leftPadLen = 2
    $rightPadLen = [Math]::Max(2, $termWidth - $leftPadLen - $titleLen - 2)

    $topBorderRaw = "$($glyphs.TL)" + ($glyphs.H * $leftPadLen) + $titleStr + ($glyphs.H * $rightPadLen) + "$($glyphs.TR)"
    $topBorderColored = New-AsciiGradient -Type fg -Steps $borderSteps -String $topBorderRaw

    [Console]::WriteLine($topBorderColored)

    # Content Rows
    foreach ($key in ($Data.Keys | Sort-Object)) {
        $val = $Data[$key]
        if ($null -eq $val) { $val = "" }
        
        $keyFormatted = $key.ToString().PadRight($labelColWidth)
        $valFormatted = $val.ToString()
        if ($valFormatted.Length -gt ($contentWidth - $labelColWidth)) {
            $valFormatted = $valFormatted.Substring(0, [Math]::Max(1, $contentWidth - $labelColWidth - 3)) + "..."
        }

        $rowStr = "$($keyFormatted)$($valFormatted)".PadRight($contentWidth)
        $vLeft = New-AsciiGradient -Type fg -Steps @(208, 208) -String $glyphs.V
        $vRight = New-AsciiGradient -Type fg -Steps @(33, 33) -String $glyphs.V

        [Console]::WriteLine("${vLeft} ${rowStr} ${vRight}")
    }

    # Bottom border
    $bottomBorderRaw = "$($glyphs.BL)" + ($glyphs.H * ($termWidth - 2)) + "$($glyphs.BR)"
    $bottomBorderColored = New-AsciiGradient -Type fg -Steps $borderSteps -String $bottomBorderRaw
    [Console]::WriteLine($bottomBorderColored)
}

function Write-GLVTable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [array]$Rows,

        [Parameter(Mandatory = $false)]
        [string[]]$Columns,

        [Parameter(Mandatory = $false)]
        [string]$Charset
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if (-not $Rows -or $Rows.Count -eq 0) {
        Write-GLVLog -Message "No records found for '$Title'." -Level Warning
        return
    }

    $mode = Get-GLVCharset -Override $Charset

    # Auto-discover columns if omitted
    if (-not $Columns -or $Columns.Count -eq 0) {
        $firstRow = $Rows[0]
        if ($firstRow -is [PSCustomObject] -or $firstRow -is [hashtable]) {
            $Columns = @($firstRow.PSObject.Properties | Select-Object -ExpandProperty Name | Select-Object -First 5)
        } else {
            $Columns = @('ID', 'Name', 'Status')
        }
    }

    $termWidth = if ([Console]::IsOutputRedirected) { 80 } else { [Math]::Max(60, [Console]::WindowWidth - 2) }

    # Calculate max column widths
    $colWidths = @{}
    foreach ($col in $Columns) {
        $maxLen = $col.Length
        foreach ($r in $Rows) {
            $cellVal = if ($r.PSObject.Properties[$col]) { $r.$col } elseif ($r[$col]) { $r[$col] } else { "" }
            if ($cellVal -is [switch] -or $cellVal -is [bool]) { $cellVal = $cellVal.ToString() }
            if ($null -ne $cellVal -and $cellVal.ToString().Length -gt $maxLen) {
                $maxLen = $cellVal.ToString().Length
            }
        }
        $colWidths[$col] = [Math]::Min(35, [Math]::Max($col.Length, $maxLen))
    }

    # Render Header Banner
    $borderSteps = @(208, 166, 130, 74, 39, 33)
    $bannerText = "── $Title ($($Rows.Count) items) ──"
    $bannerColored = New-AsciiGradient -Type fg -Steps $borderSteps -String $bannerText
    [Console]::WriteLine()
    [Console]::WriteLine($bannerColored)

    # Column Headers
    $headerRowParts = [System.Collections.Generic.List[string]]::new()
    foreach ($col in $Columns) {
        $headerRowParts.Add($col.ToUpper().PadRight($colWidths[$col]))
    }
    $headerLine = ($headerRowParts -join "  ")
    [Console]::WriteLine("  " + (New-AsciiGradient -Type fg -Steps @(214, 39) -Format bold -String $headerLine))
    [Console]::WriteLine("  " + (New-AsciiGradient -Type fg -Steps @(240, 240) -String ("─" * [Math]::Min($termWidth, $headerLine.Length + 4))))

    # Rows
    foreach ($r in $Rows) {
        $rowCells = [System.Collections.Generic.List[string]]::new()
        foreach ($col in $Columns) {
            $cellVal = if ($r.PSObject.Properties[$col]) { $r.$col } elseif ($r[$col]) { $r[$col] } else { "" }
            
            # Format status columns with status tag
            if ($col -match 'state|status|visibility') {
                $tag = ConvertTo-GLVStatusTag -Value $cellVal.ToString()
                $rowCells.Add($tag.PadRight($colWidths[$col]))
            } else {
                $valStr = if ($null -ne $cellVal) { $cellVal.ToString() } else { "" }
                if ($valStr.Length -gt $colWidths[$col]) {
                    $valStr = $valStr.Substring(0, [Math]::Max(1, $colWidths[$col] - 3)) + "..."
                }
                $rowCells.Add($valStr.PadRight($colWidths[$col]))
            }
        }
        [Console]::WriteLine("  " + ($rowCells -join "  "))
    }
    [Console]::WriteLine()
}
