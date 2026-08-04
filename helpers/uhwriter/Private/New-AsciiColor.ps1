function New-AsciiColor {
    <#
    .SYNOPSIS
      Colorize a string using ANSI escape sequences.
    .DESCRIPTION
      Unified helper for colorizing strings using standard color names, 256-color palette
      indices, or RGB color codes.

      Accepted Color / BgColor formats
      ─────────────────────────────────
      • Named color   : 'green', 'darkmagenta', etc.
      • 256-color     : '214'  (single integer 0-255)
      • 2-part code   : '38;5;214'  (already-formed 38;5;n or 48;5;n prefix stripped)
      • 3-part RGB    : '255;128;0'  (r;g;b → mapped to nearest xterm-256 index)
      • 4-part RGB    : '38;2;255;128;0' or '48;2;255;128;0'  (true-color SGR passthrough)

    .PARAMETER String
      The input string to be colorized.
    .PARAMETER Color
      The foreground color: name, 256-index, 3-part RGB, or 4-part true-color SGR.
    .PARAMETER BgColor
      The background color: same formats as Color.
    .PARAMETER Format
      Format styles: bold, dim, italic, underline, blink, reverse, hidden, strikethrough.
    #>
    [CmdletBinding()]
    [Alias('csole')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$String,

        [Parameter(Position = 1)]
        [string]$Color = 'white',

        [Parameter(Position = 2)]
        [string]$BgColor = '',

        [Parameter(Position = 3)]
        [ValidateSet('bold', 'dim', 'italic', 'underline', 'blink', 'reverse', 'hidden', 'strikethrough')]
        [string[]]$Format = @()
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

        $ColorMap = @{
            'black'       = 0
            'darkred'     = 1
            'darkgreen'   = 2
            'darkyellow'  = 3
            'darkblue'    = 4
            'darkmagenta' = 5
            'darkcyan'    = 6
            'gray'        = 7
            'grey'        = 7
            'darkgray'    = 8
            'darkgrey'    = 8
            'red'         = 9
            'green'       = 10
            'yellow'      = 11
            'blue'        = 12
            'magenta'     = 13
            'cyan'        = 14
            'white'       = 15
        }

        $StyleCodes = @{
            'bold'          = 1
            'dim'           = 2
            'italic'        = 3
            'underline'     = 4
            'blink'         = 5
            'reverse'       = 7
            'hidden'        = 8
            'strikethrough' = 9
        }

        $esc   = [char]27
        $reset = "${esc}[0m"

        # ── xterm-256 palette for 3-part RGB → nearest index mapping ──────────
        # Built once per invocation in begin{} for performance.
        $palette = New-Object 'int[][]' 256

        # 0–15: system / named colours
        $sys = @(
            [int[]]@(0,0,0),       [int[]]@(128,0,0),     [int[]]@(0,128,0),     [int[]]@(128,128,0),
            [int[]]@(0,0,128),     [int[]]@(128,0,128),   [int[]]@(0,128,128),   [int[]]@(192,192,192),
            [int[]]@(128,128,128), [int[]]@(255,0,0),     [int[]]@(0,255,0),     [int[]]@(255,255,0),
            [int[]]@(0,0,255),     [int[]]@(255,0,255),   [int[]]@(0,255,255),   [int[]]@(255,255,255)
        )
        for ($n = 0; $n -lt 16; $n++) { $palette[$n] = $sys[$n] }

        # 16–231: 6×6×6 colour cube
        for ($n = 16; $n -lt 232; $n++) {
            $idx = $n - 16
            $b   = [int]($idx % 6)
            $g   = [int](($idx / 6) % 6)
            $r   = [int]($idx / 36)
            $toV = [scriptblock]{ param($v) if ($v -eq 0) { 0 } else { 55 + $v * 40 } }
            $palette[$n] = [int[]]@((&$toV $r), (&$toV $g), (&$toV $b))
        }

        # 232–255: greyscale ramp
        for ($n = 232; $n -lt 256; $n++) {
            $grey = 8 + ($n - 232) * 10
            $palette[$n] = [int[]]@($grey, $grey, $grey)
        }

        # Nearest-palette-index helper (searches cube+greyscale, i.e. indices 16-255)
        function _Find-NearestIndex ([int]$r, [int]$g, [int]$b) {
            $bestIdx  = 16
            $bestDist = [int]::MaxValue
            for ($i = 16; $i -lt 256; $i++) {
                $dr = $palette[$i][0] - $r
                $dg = $palette[$i][1] - $g
                $db = $palette[$i][2] - $b
                $d  = $dr*$dr + $dg*$dg + $db*$db
                if ($d -lt $bestDist) {
                    $bestDist = $d
                    $bestIdx  = $i
                    if ($d -eq 0) { break }
                }
            }
            return $bestIdx
        }

        # ── Color resolver: returns a complete SGR parameter string ───────────
        # Returns one of:
        #   "38;5;<n>"   – 256-color fg
        #   "48;5;<n>"   – 256-color bg
        #   "38;2;r;g;b" – true-color fg  (4-part passthrough)
        #   "48;2;r;g;b" – true-color bg  (4-part passthrough)
        # The caller wraps it as  ESC[ + result + m
        function _Resolve-ColorSGR ([string]$raw, [bool]$isBg) {
            if ([string]::IsNullOrWhiteSpace($raw)) { return $null }

            $base   = if ($isBg) { 48 } else { 38 }
            $raw    = $raw.Trim()
            $lower  = $raw.ToLower()

            # ① Named color
            if ($ColorMap.ContainsKey($lower)) {
                return "${base};5;$($ColorMap[$lower])"
            }

            # Split on semicolons for multi-part codes
            $parts = $raw -split ';'

            # ② 4-part true-color: '38;2;r;g;b' or '48;2;r;g;b'
            #    Accept with or without the leading mode prefix
            if ($parts.Count -eq 5 -and $parts[1] -eq '2') {
                # Already fully-formed SGR data: just return as-is
                return ($parts -join ';')
            }
            if ($parts.Count -eq 4 -and $parts[0] -eq '2') {
                # '2;r;g;b' — caller omitted the 38/48 prefix
                return "${base};$($parts -join ';')"
            }
            if ($parts.Count -eq 3) {
                [int]$r = 0; [int]$g = 0; [int]$b = 0
                $allInt = [int]::TryParse($parts[0], [ref]$r) -and
                          [int]::TryParse($parts[1], [ref]$g) -and
                          [int]::TryParse($parts[2], [ref]$b)

                if ($allInt) {
                    # ③ 3-part RGB: 'r;g;b' → nearest 256-color index
                    if ($r -le 255 -and $g -le 255 -and $b -le 255 -and
                        $r -ge 0   -and $g -ge 0   -and $b -ge 0) {
                        if ($TrueColorSupported) {
                            return "${base};2;${r};${g};${b}"
                        } else {
                            $idx = _Find-NearestIndex $r $g $b
                            return "${base};5;${idx}"
                        }
                    }
                }

                # ④ 2-part code: '38;5;n' — already has mode prefix, return as-is
                if ($parts.Count -eq 3 -and ($parts[0] -eq '38' -or $parts[0] -eq '48') -and $parts[1] -eq '5') {
                    return ($parts -join ';')
                }
            }

            # ⑤ Single integer: 256-color index
            [int]$idx256 = 0
            if ([int]::TryParse($raw, [ref]$idx256) -and $idx256 -ge 0 -and $idx256 -le 255) {
                return "${base};5;${idx256}"
            }

            return $null
        }
    }

    process {
        if (-not $ColorSupported -or [string]::IsNullOrEmpty($String)) {
            return $String
        }

        # Build style prefix
        $stylePrefix = [System.Text.StringBuilder]::new()
        if ($Format) {
            foreach ($f in $Format) {
                $fLower = $f.ToLower()
                if ($StyleCodes.ContainsKey($fLower)) {
                    [void]$stylePrefix.Append("${esc}[$($StyleCodes[$fLower])m")
                }
            }
        }

        # Resolve fg / bg SGR strings
        $fgSGR = _Resolve-ColorSGR -raw $Color   -isBg $false
        $bgSGR = _Resolve-ColorSGR -raw $BgColor -isBg $true

        # Build final sequence
        $seq = $stylePrefix.ToString()
        if ($null -ne $fgSGR) { $seq += "${esc}[${fgSGR}m" }
        if ($null -ne $bgSGR) { $seq += "${esc}[${bgSGR}m" }

        # If nothing to apply, return string as-is
        if ($seq.Length -eq 0) {
            return $String
        }

        return "${seq}${String}${reset}"
    }
}
