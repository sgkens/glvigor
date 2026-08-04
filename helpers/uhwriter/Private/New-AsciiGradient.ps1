function New-AsciiGradient {
    <#
    .SYNOPSIS
        Renders a string with a 256-color ANSI gradient applied to the foreground or background.
    .DESCRIPTION
        New-AsciiGradient interpolates across a list of 256-color palette indices (steps) and
        applies the resulting per-character color as either a foreground (fg) or background (bg)
        ANSI escape sequence.
    .PARAMETER Type
        'fg'  – gradient is applied to the text foreground color.
        'bg'  – gradient is applied to the text background color.
    .PARAMETER Steps
        An array of two or more integers (0–255) representing the 256-color palette indices that
        define the gradient stops.
    .PARAMETER String
        The text to colorize.
    .PARAMETER Format
        One or more text-decoration attributes to apply.
    .PARAMETER Reset
        If supplied, a reset escape sequence is appended after the last character.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    [Alias('ascgrd')]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('fg', 'bg')]
        [string] $Type,

        [Parameter(Mandatory)]
        [int[]] $Steps,

        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string] $String,

        [Parameter()]
        [ValidateSet('bold','dim','italic','underline','blink','rapidblink','inverse','hidden','strikethrough')]
        [string[]] $Format = @(),

        [bool] $Reset = $true
    )

    begin {
        $ColorSupported = $true
        $noColorPreference = Get-Variable -Name UHWriterNoColor -Scope Global -ValueOnly -ErrorAction Ignore
        if ($env:NO_COLOR -or $env:UHWRITER_NO_COLOR -or $noColorPreference) {
            $ColorSupported = $false
        }
        $TrueColorSupported = $false
        if ($ColorSupported) {
            if ($env:COLORTERM -in @('truecolor', '24bit') -or $env:WT_SESSION -or $env:TERM_PROGRAM -eq 'vscode') {
                $TrueColorSupported = $true
            }
        }

        # ── Build the full xterm-256 palette as RGB triples ──────────────────
        $script:_palette = New-Object 'object[]' 256

        # 0–15: system / named colours
        $sys = @(
            @(0,0,0),     @(128,0,0),   @(0,128,0),   @(128,128,0),
            @(0,0,128),   @(128,0,128), @(0,128,128), @(192,192,192),
            @(128,128,128),@(255,0,0),  @(0,255,0),   @(255,255,0),
            @(0,0,255),   @(255,0,255), @(0,255,255), @(255,255,255)
        )
        for ($n = 0; $n -lt 16; $n++) { $script:_palette[$n] = [int[]]$sys[$n] }

        # 16–231: 6×6×6 colour cube
        for ($n = 16; $n -lt 232; $n++) {
            $idx = $n - 16
            $b   = [int]($idx % 6)
            $g   = [int](($idx / 6) % 6)
            $r   = [int]($idx / 36)
            $toV = [scriptblock]{ param($v) if ($v -eq 0) { 0 } else { 55 + $v * 40 } }
            $script:_palette[$n] = [int[]]@((&$toV $r), (&$toV $g), (&$toV $b))
        }

        # 232–255: greyscale ramp
        for ($n = 232; $n -lt 256; $n++) {
            $grey = 8 + ($n - 232) * 10
            $script:_palette[$n] = [int[]]@($grey, $grey, $grey)
        }

        # ── Helper: find nearest palette index to an RGB triple ───────────────
        function Find-NearestPaletteIndex ([int]$tr, [int]$tg, [int]$tb) {
            $bestIdx  = 16
            $bestDist = [int]::MaxValue
            for ($i = 16; $i -lt 256; $i++) {
                $dr = $script:_palette[$i][0] - $tr
                $dg = $script:_palette[$i][1] - $tg
                $db = $script:_palette[$i][2] - $tb
                $d  = $dr*$dr + $dg*$dg + $db*$db
                if ($d -lt $bestDist) {
                    $bestDist = $d
                    $bestIdx  = $i
                    if ($d -eq 0) { break }
                }
            }
            return $bestIdx
        }

        # ── Helper: get the stable RGB for a stop index ───────────────────────
        function Resolve-StopRGB ([int]$idx) {
            if ($idx -ge 16) { return [int[]]$script:_palette[$idx] }
            $sr = $script:_palette[$idx][0]
            $sg = $script:_palette[$idx][1]
            $sb = $script:_palette[$idx][2]
            $nearIdx = Find-NearestPaletteIndex $sr $sg $sb
            return [int[]]$script:_palette[$nearIdx]
        }
    }

    process {
        if ($Steps.Count -lt 2) {
            throw [System.ArgumentException]::new('Steps must contain at least two color indices.')
        }
        foreach ($c in $Steps) {
            if ($c -lt 0 -or $c -gt 255) {
                throw [System.ArgumentOutOfRangeException]::new('Steps', "Color index $c is out of range (0-255).")
            }
        }

        if (-not $ColorSupported -or [string]::IsNullOrEmpty($String)) { return $String }

        $stopRGB = [System.Collections.ArrayList]::new()
        foreach ($s in $Steps) { [void]$stopRGB.Add((Resolve-StopRGB $s)) }

        $chars     = $String.ToCharArray()
        $len       = $chars.Length
        $segCount  = $Steps.Count - 1
        $result    = [System.Text.StringBuilder]::new($len * 20)

        $escPrefix = if ($TrueColorSupported) {
            if ($Type -eq 'fg') { "`e[38;2;" } else { "`e[48;2;" }
        } else {
            if ($Type -eq 'fg') { "`e[38;5;" } else { "`e[48;5;" }
        }

        $formatMap = @{
            bold=1; dim=2; italic=3; underline=4; blink=5
            rapidblink=6; inverse=7; hidden=8; strikethrough=9
        }
        $formatPrefix = if ($Format.Count -gt 0) {
            $codes = ($Format | ForEach-Object { $formatMap[$_] }) -join ';'
            "`e[${codes}m"
        } else { '' }

        for ($i = 0; $i -lt $len; $i++) {
            $t = if ($len -gt 1) { $i / ($len - 1) * $segCount } else { 0.0 }

            $segRaw = [Math]::Floor($t)
            if ($segRaw -ge $segCount) {
                $seg  = $segCount - 1
                $frac = 1.0
            } else {
                $seg  = [int]$segRaw
                $frac = $t - $segRaw
            }

            $rgbA = [int[]]$stopRGB[$seg]
            $rgbB = [int[]]$stopRGB[$seg + 1]

            $tr = [int][Math]::Round($rgbA[0] + ($rgbB[0] - $rgbA[0]) * $frac)
            $tg = [int][Math]::Round($rgbA[1] + ($rgbB[1] - $rgbA[1]) * $frac)
            $tb = [int][Math]::Round($rgbA[2] + ($rgbB[2] - $rgbA[2]) * $frac)

            if ($TrueColorSupported) {
                [void]$result.Append("${formatPrefix}${escPrefix}${tr};${tg};${tb}m$($chars[$i])")
            } else {
                $color = Find-NearestPaletteIndex $tr $tg $tb
                [void]$result.Append("${formatPrefix}${escPrefix}${color}m$($chars[$i])")
            }
        }

        if ($Reset) { [void]$result.Append("`e[0m") }

        return $result.ToString()
    }
}
