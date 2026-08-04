function New-AsciiTokenGradient {
    <#
    .SYNOPSIS
        Applies TrueColor gradients to ASCII art based on tokenized 2D shapes.
    .DESCRIPTION
        New-AsciiTokenGradient tokenizes the input lines into connected glyph components
        and colorizes them with ANSI truecolor (or xterm-256 fallback) gradients.
    .PARAMETER Lines
        The input string array representing the ASCII art to colorize.
    .PARAMETER StartColor
        The starting color as an RGB array (e.g. 0,150,255) or a named color.
    .PARAMETER EndColor
        The ending color as an RGB array (e.g. 255,0,150) or a named color.
    .PARAMETER Mode
        The gradient mapping mode:
          - 'Horizontal': color varies by character's X position.
          - 'Vertical': color varies by character's Y position.
          - 'PerToken': each isolated contiguous token is assigned a single color.
    .PARAMETER Connectivity
        Connection connectivity (4 or 8) for shape detection.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Lines,

        [Parameter(Position = 0)]
        [object]$StartColor = @(0, 150, 255),

        [Parameter(Position = 1)]
        [object]$EndColor = @(255, 0, 150),

        [Parameter(Position = 2)]
        [ValidateSet('Horizontal', 'Vertical', 'PerToken')]
        [string]$Mode = 'Horizontal',

        [Parameter()]
        [ValidateSet(4, 8)]
        [int]$Connectivity = 8
    )

    begin {
        $inputLines = [System.Collections.Generic.List[string]]::new()
    }

    process {
        foreach ($line in $Lines) {
            if ($null -ne $line) {
                [void]$inputLines.Add($line)
            }
        }
    }

    end {
        if ($inputLines.Count -eq 0) { return @() }

        # Resolve start/end colors (accepting RGB arrays or named colors)
        function _Resolve-RGB ([object]$color) {
            if ($color -is [int[]] -and $color.Count -eq 3) {
                return $color
            }
            if ($color -is [string]) {
                if ($color -match '^\d+,\d+,\d+$') {
                    return [int[]]($color -split ',' | ForEach-Object { [int]$_ })
                }
                $named = @{
                    'black'   = @(0,0,0);       'red'     = @(255,0,0);     'green'   = @(0,255,0)
                    'yellow'  = @(255,255,0);   'blue'    = @(0,0,255);     'magenta' = @(255,0,255)
                    'cyan'    = @(0,255,255);   'white'   = @(255,255,255); 'gray'    = @(128,128,128)
                    'grey'    = @(128,128,128); 'orange'  = @(255,165,0);   'purple'  = @(128,0,128)
                }
                $lower = $color.ToLower()
                if ($named.ContainsKey($lower)) {
                    return $named[$lower]
                }
            }
            return @(255, 255, 255)
        }

        $rgbStart = _Resolve-RGB $StartColor
        $rgbEnd   = _Resolve-RGB $EndColor

        # BFS Flood Fill to find tokens
        $tokenObj = ConvertTo-AsciiTokens -Lines $inputLines.ToArray() -Connectivity $Connectivity
        if ($null -eq $tokenObj) { return $inputLines.ToArray() }

        # Check color support
        $colorEnabled = $true
        $noColorPreference = Get-Variable -Name UHWriterNoColor -Scope Global -ValueOnly -ErrorAction Ignore
        if ($env:NO_COLOR -or $env:UHWRITER_NO_COLOR -or $noColorPreference) {
            $colorEnabled = $false
        }

        if (-not $colorEnabled) {
            return $tokenObj.Lines
        }

        # Detect TrueColor/RGB support
        $useTrueColor = $false
        if ($env:COLORTERM -in @('truecolor', '24bit') -or $env:WT_SESSION -or $env:TERM_PROGRAM -eq 'vscode') {
            $useTrueColor = $true
        }

        $palette = New-Object 'int[][]' 256
        $sys = @(
            [int[]]@(0,0,0),       [int[]]@(128,0,0),     [int[]]@(0,128,0),     [int[]]@(128,128,0),
            [int[]]@(0,0,128),     [int[]]@(128,0,128),   [int[]]@(0,128,128),   [int[]]@(192,192,192),
            [int[]]@(128,128,128), [int[]]@(255,0,0),     [int[]]@(0,255,0),     [int[]]@(255,255,0),
            [int[]]@(0,0,255),     [int[]]@(255,0,255),   [int[]]@(0,255,255),   [int[]]@(255,255,255)
        )
        for ($n = 0; $n -lt 16; $n++) { $palette[$n] = $sys[$n] }
        for ($n = 16; $n -lt 232; $n++) {
            $idx = $n - 16
            $b   = [int]($idx % 6)
            $g   = [int](($idx / 6) % 6)
            $r   = [int]($idx / 36)
            $toV = [scriptblock]{ param($v) if ($v -eq 0) { 0 } else { 55 + $v * 40 } }
            $palette[$n] = [int[]]@((&$toV $r), (&$toV $g), (&$toV $b))
        }
        for ($n = 232; $n -lt 256; $n++) {
            $grey = 8 + ($n - 232) * 10
            $palette[$n] = [int[]]@($grey, $grey, $grey)
        }

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

        function Get-GradientColor {
            param([double]$T, [int[]]$Start, [int[]]$End)
            $r = [int]($Start[0] + ($End[0] - $Start[0]) * $T)
            $g = [int]($Start[1] + ($End[1] - $Start[1]) * $T)
            $b = [int]($Start[2] + ($End[2] - $Start[2]) * $T)
            if ($useTrueColor) {
                "38;2;$r;$g;$b"
            } else {
                $idx = _Find-NearestIndex $r $g $b
                "38;5;$idx"
            }
        }

        $esc = [char]27
        $colorMap = New-Object 'string[,]' $tokenObj.Height, $tokenObj.Width

        switch ($Mode) {
            'Horizontal' {
                foreach ($token in $tokenObj.Tokens) {
                    foreach ($cell in $token.Cells) {
                        $y, $x = $cell
                        $t = if ($tokenObj.Width -gt 1) { $x / ($tokenObj.Width - 1) } else { 0 }
                        $colorMap[$y, $x] = Get-GradientColor -T $t -Start $rgbStart -End $rgbEnd
                    }
                }
            }
            'Vertical' {
                foreach ($token in $tokenObj.Tokens) {
                    foreach ($cell in $token.Cells) {
                        $y, $x = $cell
                        $t = if ($tokenObj.Height -gt 1) { $y / ($tokenObj.Height - 1) } else { 0 }
                        $colorMap[$y, $x] = Get-GradientColor -T $t -Start $rgbStart -End $rgbEnd
                    }
                }
            }
            'PerToken' {
                $maxId = [Math]::Max(1, ($tokenObj.Tokens.Count - 1))
                foreach ($token in $tokenObj.Tokens) {
                    $tColor = Get-GradientColor -T ($token.Id / $maxId) -Start $rgbStart -End $rgbEnd
                    foreach ($cell in $token.Cells) {
                        $y, $x = $cell
                        $colorMap[$y, $x] = $tColor
                    }
                }
            }
        }

        $resultLines = [System.Collections.Generic.List[string]]::new()
        for ($y = 0; $y -lt $tokenObj.Height; $y++) {
            $sb = [System.Text.StringBuilder]::new()
            for ($x = 0; $x -lt $tokenObj.Width; $x++) {
                $c = $tokenObj.Lines[$y][$x]
                if ($colorMap[$y, $x]) {
                    [void]$sb.Append("${esc}[$($colorMap[$y,$x])m$c${esc}[0m")
                } else {
                    [void]$sb.Append($c)
                }
            }
            $resultLines.Add($sb.ToString())
        }

        return $resultLines.ToArray()
    }
}
