function _Measure-VisualWidth {
    <#
    .SYNOPSIS
      Returns the display-column-width of a plain or ANSI-escaped string.
    .DESCRIPTION
      Strips ANSI SGR sequences first, then iterates each char and adds 2 for wide
      Unicode codepoints (emoji block U+1F300-U+1FAFF, misc symbols U+2600-U+27BF,
      CJK compatibility U+FE30-U+FE4F, CJK unified U+4E00-U+9FFF) and 1 for all
      other characters.  Handles .NET surrogate pairs correctly.
    #>
    param([string]$Text)
    # Strip ANSI SGR sequences
    $plain = [System.Text.RegularExpressions.Regex]::Replace(
        $Text, '\x1b\[[0-?]*[ -/]*[@-~]', '')
    $width = 0
    $chars = $plain.ToCharArray()
    $i = 0
    while ($i -lt $chars.Length) {
        $ch = $chars[$i]
        # Detect surrogate pair — high surrogate followed by low surrogate
        if ([char]::IsHighSurrogate($ch) -and ($i + 1) -lt $chars.Length -and [char]::IsLowSurrogate($chars[$i + 1])) {
            $cp = [char]::ConvertToUtf32($ch, $chars[$i + 1])
            # Emoji + supplemental symbols: U+1F000–U+1FAFF
            if ($cp -ge 0x1F000 -and $cp -le 0x1FAFF) {
                $width += 2
            } else {
                $width += 2  # any other supplementary char defaults wide
            }
            $i += 2
            continue
        }
        $cp = [int]$ch
        if (($cp -ge 0x1F300 -and $cp -le 0x1FAFF) -or   # Emoji / supplemental symbols (BMP subset)
            ($cp -ge 0x2600  -and $cp -le 0x27BF)  -or   # Miscellaneous symbols
            ($cp -ge 0xFE30  -and $cp -le 0xFE4F)  -or   # CJK compatibility forms
            ($cp -ge 0x4E00  -and $cp -le 0x9FFF)) {      # CJK unified ideographs
            $width += 2
        } else {
            $width += 1
        }
        $i++
    }
    return $width
}

function Write-UHAsciiLogo {
    <#
    .SYNOPSIS
      Renders the ASCII logo banner for a module with dynamic theme and layout options.
    .DESCRIPTION
      Renders a stylized ASCII/ANSI header banner using selected theme colors and layout styles.
    .PARAMETER Name
      The name of the module to display.
    .PARAMETER Version
      Optional version string of the module.
    .PARAMETER Theme
      A theme name string ('default', 'matrix', 'cyberpunk', etc.) or a custom theme hashtable.
    .PARAMETER Layout
      The layout style to use: 'Box', 'Classic', 'Minimal', 'Man', 'Terminal', 'Typewriter'.
    .PARAMETER CustomLogo
      An optional custom ASCII art string that overrides the default layouts.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Name,

        [Parameter(Position = 1)]
        [string]$Version = '',

        [Parameter()]
        $Theme = 'uhwriter',

        [Parameter()]
        [ValidateSet('Box', 'Classic', 'Minimal', 'Man', 'Terminal', 'Typewriter')]
        [string]$Layout = 'Box',

        [Parameter()]
        [string]$CustomLogo = $null,

        [Parameter()]
        [switch]$Gradient,

        [Parameter()]
        [Alias('CustomGradnet')]
        [int[]]$CustomGradient,

        [Parameter(HelpMessage = "The gradient mode: Horizontal, Vertical, or PerToken.")]
        [ValidateSet('Horizontal', 'Vertical', 'PerToken')]
        [string]$GradientMode = 'Horizontal',

        [Parameter(HelpMessage = "Display Help for Write-UHAsciiLogo.")]
        [switch]$Help
    )

    process {
        if ($Help) {
            $asciilogo_ParamTable = @(
                @{
                    name        = "Name"
                    param       = "n|Name"
                    type        = "String"
                    description = "The name of the module/tool to display."
                    required    = $true
                    inline      = $false
                },
                @{
                    name        = "Version"
                    param       = "v|Version"
                    type        = "String"
                    description = "Optional version string of the module."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "Theme"
                    param       = "th|Theme"
                    type        = "String|Hashtable"
                    description = "Theme name or custom theme object."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "Layout"
                    param       = "l|Layout"
                    type        = "String"
                    description = "The layout style to use: 'Box', 'Classic', 'Minimal', etc."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "CustomLogo"
                    param       = "cl|CustomLogo"
                    type        = "String"
                    description = "An optional custom ASCII art string that overrides the default layouts."
                    required    = $false
                    inline      = $false
                }
            )
            $asciilogo_commandinfo = @{
                cmdlet      = "Write-UHAsciiLogo"
                synopsis    = "Write-UHAsciiLogo [-Name <String>] [-Version <String>] [-Theme <Object>] [-Layout <String>] [-CustomLogo <String>]"
                description = "Renders the ASCII logo banner for a module with dynamic theme and layout options."
                source      = "https://gitlab.com/phellams/uhwriter"
            }
            $asciilogo_examples = @(
                "Write-UHAsciiLogo -Name 'SAMPLE' -Version '1.2.3' -Theme 'drift-blue-orange'"
            )
            New-UHWriter -Name 'UHWRITER' -CommandInfo $asciilogo_commandinfo -ParamTable $asciilogo_ParamTable -Padding 4 -Indent 2 -Theme $Theme -Version '1.0.0' -Examples $asciilogo_examples
            return
        }

        if ([string]::IsNullOrEmpty($Name)) {
            throw [System.ArgumentException]::new("Name parameter is mandatory when -Help is not specified.")
        }

        # Resolve Theme
        $themeObj = $null
        if ($Theme -is [hashtable]) {
            $themeObj = $Theme
        } else {
            $themeObj = Get-UHTheme -Name $Theme
        }

        $useGradient = $Gradient -or ($null -ne $CustomGradient)
        if ($useGradient) {
            $steps = if ($null -ne $CustomGradient) {
                $CustomGradient
            } elseif ($themeObj.ContainsKey('GradientSteps')) {
                $themeObj['GradientSteps']
            } else {
                [int[]]@(51, 93, 129, 201)
            }
        }

        function Get-ColorIndexRGB ([int]$index) {
            if ($index -lt 0 -or $index -gt 255) { return @(255, 255, 255) }
            $sys = @(
                @(0,0,0),     @(128,0,0),   @(0,128,0),   @(128,128,0),
                @(0,0,128),   @(128,0,128), @(0,128,128), @(192,192,192),
                @(128,128,128),@(255,0,0),  @(0,255,0),   @(255,255,0),
                @(0,0,255),   @(255,0,255), @(0,255,255), @(255,255,255)
            )
            if ($index -lt 16) { return $sys[$index] }
            if ($index -lt 232) {
                $idx = $index - 16
                $b = $idx % 6
                $g = [int](($idx / 6) % 6)
                $r = [int]($idx / 36)
                $toV = { param($v) if ($v -eq 0) { 0 } else { 55 + $v * 40 } }
                return @((&$toV $r), (&$toV $g), (&$toV $b))
            }
            $grey = 8 + ($index - 232) * 10
            return @($grey, $grey, $grey)
        }

        # If custom logo is provided, print it directly (with border styling applied to each line if wanted)
        if ($CustomLogo) {
            $lines = $CustomLogo -split "`r?\n" | ForEach-Object { $_.TrimEnd() }
            if ($useGradient) {
                $rgbStart = Get-ColorIndexRGB $steps[0]
                $rgbEnd   = Get-ColorIndexRGB $steps[-1]
                $colorized = New-AsciiTokenGradient -Lines $lines -StartColor $rgbStart -EndColor $rgbEnd -Mode $GradientMode
                foreach ($line in $colorized) {
                    [console]::WriteLine($line)
                }
            } else {
                foreach ($line in $lines) {
                    [console]::WriteLine($(Format-ThemeText -String $line -Theme $themeObj -Element 'Border'))
                }
            }
            [console]::Write("`n")
            return
        }

        # Format spaced name (e.g. "P H W R I T E R")
        $spacedName = Format-StringWithCharSpacesAndHyphens -InputString $Name
        $versionStr = if ($Version) { "v$Version" } else { "" }

        switch ($Layout) {
            'Box' {
                $nameVisualWidth = _Measure-VisualWidth $spacedName
                $width  = [Math]::Max(60, $nameVisualWidth + 8)
                $top    = "╭" + ("─" * ($width - 2)) + "╮"
                $bottom = "╰" + ("─" * ($width - 2)) + "╯"
                $innerPadded = Pad-AnsiString -Text $spacedName -Width ($width - 2) -Align 'Center' -PadChar ' '
                $middle = "│" + $innerPadded + "│"

                if ($useGradient) {
                    $rgbStart = Get-ColorIndexRGB $steps[0]
                    $rgbEnd   = Get-ColorIndexRGB $steps[-1]
                    $colorized = New-AsciiTokenGradient -Lines @($top, $middle, $bottom) -StartColor $rgbStart -EndColor $rgbEnd -Mode $GradientMode
                    foreach ($line in $colorized) { [console]::WriteLine($line) }
                } else {
                    [console]::WriteLine($(Format-ThemeText -String $top    -Theme $themeObj -Element 'Border'))
                    [console]::WriteLine(($(Format-ThemeText -String "│" -Theme $themeObj -Element 'Border') + $(Format-ThemeText -String $innerPadded -Theme $themeObj -Element 'Header') + $(Format-ThemeText -String "│" -Theme $themeObj -Element 'Border')))
                    [console]::WriteLine($(Format-ThemeText -String $bottom -Theme $themeObj -Element 'Border'))
                }
            }
            'Classic' {
                $borderTop    = $themeObj['BorderTop']
                $borderBottom = $themeObj['BorderBottom']
                $borderMiddle = $themeObj['BorderMiddle']

                $totalWidth = if ($borderTop) { _Measure-VisualWidth $borderTop } else { 70 }
                $innerWidth = $totalWidth - 2

                $middleChar = if ($borderMiddle) { $borderMiddle } else { "░" }
                $innerPadded = Pad-AnsiString -Text $spacedName -Width $innerWidth -Align 'Center' -PadChar $middleChar

                if ($useGradient) {
                    $top = if ($borderTop) { $borderTop } else { "═══" }
                    $bottom = if ($borderBottom) { $borderBottom } else { "═══" }
                    $middle = "╟" + $innerPadded + "╢"
                    $rgbStart = Get-ColorIndexRGB $steps[0]
                    $rgbEnd   = Get-ColorIndexRGB $steps[-1]
                    $colorized = New-AsciiTokenGradient -Lines @($top, $middle, $bottom) -StartColor $rgbStart -EndColor $rgbEnd -Mode $GradientMode
                    foreach ($line in $colorized) { [console]::WriteLine($line) }
                } else {
                    $borderLeft  = Format-ThemeText -String "╟" -Theme $themeObj -Element 'Border'
                    $borderRight = Format-ThemeText -String "╢" -Theme $themeObj -Element 'Border'
                    $styledHeader = Format-ThemeText -String $innerPadded -Theme $themeObj -Element 'Header'
                    $middle = $borderLeft + $styledHeader + $borderRight

                    [console]::WriteLine($(Format-ThemeText -String $borderTop    -Theme $themeObj -Element 'Border'))
                    [console]::WriteLine($middle)
                    [console]::WriteLine($(Format-ThemeText -String $borderBottom -Theme $themeObj -Element 'Border'))
                }
            }
            'Minimal' {
                $nameVisualWidth = _Measure-VisualWidth $spacedName
                $width = [Math]::Max(60, $nameVisualWidth + 4)
                $line  = "─" * $width
                $headerStr = "  " + $spacedName

                if ($useGradient) {
                    $rgbStart = Get-ColorIndexRGB $steps[0]
                    $rgbEnd   = Get-ColorIndexRGB $steps[-1]
                    $colorized = New-AsciiTokenGradient -Lines @($headerStr, $line) -StartColor $rgbStart -EndColor $rgbEnd -Mode $GradientMode
                    foreach ($l in $colorized) { [console]::WriteLine($l) }
                } else {
                    $styledHeader = Format-ThemeText -String $headerStr -Theme $themeObj -Element 'Header'
                    [console]::WriteLine($styledHeader)
                    [console]::WriteLine($(Format-ThemeText -String $line -Theme $themeObj -Element 'Border'))
                }
            }
            'Man' {
                $width      = 70
                $leftText   = "$($Name.ToUpper())(1)"
                $centerText = "User Commands"
                $rightText  = "$($Name.ToUpper())(1)"

                $headerLine = Clap -Cells @(
                    @{ Text = $leftText;   Width = 25; Align = 'Left' }
                    @{ Text = $centerText; Width = 20; Align = 'Center' }
                    @{ Text = $rightText;  Width = 25; Align = 'Right' }
                )
                $line = "─" * $width

                if ($useGradient) {
                    $rgbStart = Get-ColorIndexRGB $steps[0]
                    $rgbEnd   = Get-ColorIndexRGB $steps[-1]
                    $colorized = New-AsciiTokenGradient -Lines @($headerLine, $line) -StartColor $rgbStart -EndColor $rgbEnd -Mode $GradientMode
                    foreach ($l in $colorized) { [console]::WriteLine($l) }
                } else {
                    $styledHeader = Format-ThemeText -String $headerLine -Theme $themeObj -Element 'Header'
                    [console]::WriteLine($styledHeader)
                    [console]::WriteLine($(Format-ThemeText -String $line -Theme $themeObj -Element 'Border'))
                }
            }
            'Terminal' {
                $terminalArt = @(
                    "   ┌───────────────┐",
                    "   │  >_           │      {Name}",
                    "   │               │",
                    "   │               │      {Version}",
                    "   └───────────────┘"
                )

                if ($useGradient) {
                    $rawLines = [System.Collections.Generic.List[string]]::new()
                    foreach ($line in $terminalArt) {
                        $rendered = $line
                        if ($rendered -match '\{Name\}') {
                            $rendered = $rendered -replace '\{Name\}', $spacedName
                        }
                        if ($rendered -match '\{Version\}') {
                            $rendered = $rendered -replace '\{Version\}', $versionStr
                        }
                        [void]$rawLines.Add($rendered)
                    }
                    $rgbStart = Get-ColorIndexRGB $steps[0]
                    $rgbEnd   = Get-ColorIndexRGB $steps[-1]
                    $colorized = New-AsciiTokenGradient -Lines $rawLines.ToArray() -StartColor $rgbStart -EndColor $rgbEnd -Mode $GradientMode
                    foreach ($l in $colorized) { [console]::WriteLine($l) }
                } else {
                    foreach ($line in $terminalArt) {
                        $rendered = $line
                        if ($rendered -match '\{Name\}') {
                            $styledName = Format-ThemeText -String $spacedName -Theme $themeObj -Element 'Header'
                            $rendered   = $rendered -replace '\{Name\}', $styledName
                        }
                        if ($rendered -match '\{Version\}') {
                            $styledVer = Format-ThemeText -String $versionStr -Theme $themeObj -Element 'Version'
                            $rendered  = $rendered -replace '\{Version\}', $styledVer
                        }

                        $boxPart  = $rendered.Substring(0, 20)
                        $textPart = if ($rendered.Length -gt 20) { $rendered.Substring(20) } else { "" }

                        $styledBox = Format-ThemeText -String $boxPart -Theme $themeObj -Element 'Border'
                        [console]::WriteLine($styledBox + $textPart)
                    }
                }
            }
            'Typewriter' {
                $typewriterArt = @(
                    "    .───────────────────.",
                    "   │  _________________  │      {Name}",
                    "   │ ░░░░░░░░░░░░░░░░░  │",
                    "   │ ░░░░░░░░░░░░░░░░░  │      {Version}",
                    "   │  ─────────────────  │",
                    "   │ [a][s][d][f][g][h]  │",
                    "   │ [z][x][c][v][b][n]  │",
                    "   '───────────────────'"
                )

                if ($useGradient) {
                    $rawLines = [System.Collections.Generic.List[string]]::new()
                    foreach ($line in $typewriterArt) {
                        $rendered = $line
                        if ($rendered -match '\{Name\}') {
                            $rendered = $rendered -replace '\{Name\}', $spacedName
                        }
                        if ($rendered -match '\{Version\}') {
                            $rendered = $rendered -replace '\{Version\}', $versionStr
                        }
                        [void]$rawLines.Add($rendered)
                    }
                    $rgbStart = Get-ColorIndexRGB $steps[0]
                    $rgbEnd   = Get-ColorIndexRGB $steps[-1]
                    $colorized = New-AsciiTokenGradient -Lines $rawLines.ToArray() -StartColor $rgbStart -EndColor $rgbEnd -Mode $GradientMode
                    foreach ($l in $colorized) { [console]::WriteLine($l) }
                } else {
                    foreach ($line in $typewriterArt) {
                        $rendered = $line
                        if ($rendered -match '\{Name\}') {
                            $styledName = Format-ThemeText -String $spacedName -Theme $themeObj -Element 'Header'
                            $rendered   = $rendered -replace '\{Name\}', $styledName
                        }
                        if ($rendered -match '\{Version\}') {
                            $styledVer = Format-ThemeText -String $versionStr -Theme $themeObj -Element 'Version'
                            $rendered  = $rendered -replace '\{Version\}', $styledVer
                        }

                        $boxPart  = $rendered.Substring(0, 24)
                        $textPart = if ($rendered.Length -gt 24) { $rendered.Substring(24) } else { "" }

                        $styledBox = Format-ThemeText -String $boxPart -Theme $themeObj -Element 'Border'
                        [console]::WriteLine($styledBox + $textPart)
                    }
                }
            }
        }
        [console]::Write("`n")
    }
}
