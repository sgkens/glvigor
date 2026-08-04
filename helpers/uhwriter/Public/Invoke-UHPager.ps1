function Invoke-UHPager {
    <#
    .SYNOPSIS
      Presents long string output in an interactive TUI scroller/pager in the terminal.
    .DESCRIPTION
      Splits content into lines, then renders pages based on console window height.
      Navigation is arrow-key (Up/Down), Page Up/Down, Home/End, and Q or ESC to quit.
      Renders a status bar at the bottom of the screen with position info.

      This function is aware of ANSI escape sequences and strips them for line-width
      accounting so wrapping never breaks ANSI-colored output.

      When used inside a pipeline, it buffers all input before rendering.
    .PARAMETER Content
      A string or array of strings to display. Accepts pipeline input.
    .PARAMETER Title
      Optional title shown in the pager top bar. Default: 'UHWriter Pager'.
    .PARAMETER PageSize
      Optional override for page height in lines. Default: Console.WindowHeight - 3 (auto).
    .PARAMETER NoColor
      If set, strips all ANSI codes from output before display (plain text mode).
    .EXAMPLE
      Get-Help Get-Process -Full | Out-String | Invoke-UHPager
    .EXAMPLE
      New-UHWriter @params | Invoke-UHPager -Title 'My-Module Help'
    .NOTES
      Alias: uhpager
    #>
    [CmdletBinding()]
    [Alias('uhpager')]
    param(
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, HelpMessage = "Content string(s) to display.")]
        [object[]]$Content,

        [Parameter(Mandatory = $false, HelpMessage = "Title shown in the top header bar.")]
        [string]$Title = 'UHWriter Pager',

        [Parameter(Mandatory = $false, HelpMessage = "Override page height. Defaults to window height minus header/status rows.")]
        [int]$PageSize = 0,

        [Parameter(Mandatory = $false, HelpMessage = "Strip ANSI codes for plain text display.")]
        [switch]$NoColor,

        [Parameter(Mandatory = $false, HelpMessage = "Theme name or custom theme object.")]
        [object]$Theme = 'uhwriter',

        [Parameter(Mandatory = $false, HelpMessage = "ScriptBlock callback executed on console resize to regenerate content.")]
        [scriptblock]$OnResize,

        [Parameter(Mandatory = $false, HelpMessage = "Keep help output on stdout when leaving alternate screen buffer.")]
        [switch]$KeepOutput = $true,

        [Parameter(HelpMessage = "Display Help for Invoke-UHPager.")]
        [switch]$Help
    )

    begin {
        $buffer = [System.Collections.Generic.List[string]]::new()
    }

    process {
        if ($Help) {
            $uhpager_ParamTable = @(
                @{
                    name        = "Content"
                    param       = "c|Content"
                    type        = "Object[]"
                    description = "Content string(s) to display. Accepts pipeline input."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "Title"
                    param       = "t|Title"
                    type        = "String"
                    description = "Title shown in the top header bar. Default: 'UHWriter Pager'."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "PageSize"
                    param       = "ps|PageSize"
                    type        = "Int"
                    description = "Override page height. Defaults to window height minus header/status rows."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "NoColor"
                    param       = "nc|NoColor"
                    type        = "Switch"
                    description = "Strip ANSI codes for plain text display."
                    required    = $false
                    inline      = $true
                },
                @{
                    name        = "Theme"
                    param       = "th|Theme"
                    type        = "String|Hashtable"
                    description = "Theme name or custom theme object."
                    required    = $false
                    inline      = $false
                }
            )
            $uhpager_commandinfo = @{
                cmdlet      = "Invoke-UHPager"
                synopsis    = "Invoke-UHPager [-Content <Object[]>] [-Title <String>] [-PageSize <Int>] [-NoColor] [-Theme <Object>]"
                description = "Presents long string output in an interactive TUI scroller/pager in the terminal. Handles ANSI escape sequences and strips them for line-width accounting."
                source      = "https://gitlab.com/phellams/uhwriter"
            }
            $uhpager_examples = @(
                "Get-Help Get-Process -Full | Out-String | Invoke-UHPager",
                "New-UHWriter @params | Invoke-UHPager -Title 'My-Module Help' -Theme 'drift-blue-orange'"
            )
            New-UHWriter -Name 'UHWRITER' -CommandInfo $uhpager_commandinfo -ParamTable $uhpager_ParamTable -Padding 4 -Indent 2 -Theme $Theme -Version '1.0.0' -Examples $uhpager_examples
            return
        }

        foreach ($item in $Content) {
            if ($null -eq $item) { continue }
            $text = $item.ToString()
            # Split on newlines — handle both \r\n and \n
            $lines = $text -split '\r?\n'
            foreach ($line in $lines) { $buffer.Add($line) }
        }
    }

    end {
        if ($buffer.Count -eq 0) { return }

        # ── ANSI strip helper (regex-based, pre-compiled) ─────────────────────
        $ansiPattern = [System.Text.RegularExpressions.Regex]::new(
            '\x1b(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])',
            [System.Text.RegularExpressions.RegexOptions]::Compiled
        )

        if ($NoColor) {
            $displayLines = [System.Collections.Generic.List[string]]::new()
            foreach ($l in $buffer) {
                $displayLines.Add($ansiPattern.Replace($l, ''))
            }
        } else {
            $displayLines = $buffer
        }

        $totalLines = $displayLines.Count

        # ── Compute effective page size ───────────────────────────────────────
        # Reserve 2 rows: 1 for top bar, 1 for status bar
        $headerRows = 1
        $footerRows = 1
        $effectivePage = if ($PageSize -gt 0) {
            $PageSize
        } else {
            [Math]::Max(5, [Console]::WindowHeight - $headerRows - $footerRows - 1)
        }

        $esc     = [char]27
        $reset   = "${esc}[0m"
        $bold    = "${esc}[1m"
        $rev     = "${esc}[7m"     # reverse video for bars
        $hideCur = "${esc}[?25l"   # hide cursor
        $showCur = "${esc}[?25h"   # show cursor
        $clearSc = "${esc}[2J${esc}[H"  # full clear

        # ── Theme colors for chrome ───────────────────────────────────────────
        $themeObj = $null
        if ($Theme -is [hashtable]) {
            $themeObj = $Theme
        } else {
            $themeObj = Get-UHTheme -Name $Theme
        }

        $hFg = if ($themeObj.ContainsKey('HeaderFg')) { $themeObj['HeaderFg'] } else { 'white' }
        $hBg = if ($themeObj.ContainsKey('HeaderBg')) { $themeObj['HeaderBg'] } else { '' }
        $barStyleRaw = New-AsciiColor -String "X" -Color $hFg -BgColor $hBg
        $barStyle = if ($barStyleRaw.EndsWith("[0m")) { $barStyleRaw.Substring(0, $barStyleRaw.Length - 5) } else { "" }

        $accCol = if ($themeObj.ContainsKey('AccentColor')) { $themeObj['AccentColor'] } else { 'green' }
        $hiGreenRaw = New-AsciiColor -String "X" -Color $accCol -Format 'bold'
        $hiGreen = if ($hiGreenRaw.EndsWith("[0m")) { $hiGreenRaw.Substring(0, $hiGreenRaw.Length - 5) } else { "" }

        $borCol = if ($themeObj.ContainsKey('BorderColor')) { $themeObj['BorderColor'] } else { 'cyan' }
        $hiCyanRaw = New-AsciiColor -String "X" -Color $borCol
        $hiCyan = if ($hiCyanRaw.EndsWith("[0m")) { $hiCyanRaw.Substring(0, $hiCyanRaw.Length - 5) } else { "" }

        $descCol = if ($themeObj.ContainsKey('ParamDescFg')) { $themeObj['ParamDescFg'] } else { 'gray' }
        $dimGreyRaw = New-AsciiColor -String "X" -Color $descCol
        $dimGrey = if ($dimGreyRaw.EndsWith("[0m")) { $dimGreyRaw.Substring(0, $dimGreyRaw.Length - 5) } else { "" }

        # Pull additional theme keys for chrome chrome customization
        # SectionChar drives the separator glyphs in header/footer bars
        $themeSepChar = if ($themeObj.ContainsKey('SectionChar')) {
            $sc = $themeObj['SectionChar']
            $isWide = $false
            if ($sc.Length -gt 0) {
                if ([char]::IsHighSurrogate($sc[0])) {
                    $isWide = $true
                } else {
                    $cp = [int]$sc[0]
                    if (($cp -ge 0x1F300 -and $cp -le 0x1FAFF) -or
                        ($cp -ge 0x2600  -and $cp -le 0x27BF)  -or
                        ($cp -ge 0xFE30  -and $cp -le 0xFE4F)  -or
                        ($cp -ge 0x4E00  -and $cp -le 0x9FFF)) {
                        $isWide = $true
                    }
                }
            }
            # Only use single-column safe glyphs as separator; fall back to '|' for wide/emoji chars
            if ($sc.Length -gt 0 -and $sc.Length -le 2 -and -not $isWide) { $sc } else { '|' }
        } else { '|' }

        # HeaderChar used as title prefix indicator
        $themeTitleChar = if ($themeObj.ContainsKey('HeaderChar')) {
            $hc = $themeObj['HeaderChar']
            $isWide = $false
            if ($hc.Length -gt 0) {
                if ([char]::IsHighSurrogate($hc[0])) {
                    $isWide = $true
                } else {
                    $cp = [int]$hc[0]
                    if (($cp -ge 0x1F300 -and $cp -le 0x1FAFF) -or
                        ($cp -ge 0x2600  -and $cp -le 0x27BF)  -or
                        ($cp -ge 0xFE30  -and $cp -le 0xFE4F)  -or
                        ($cp -ge 0x4E00  -and $cp -le 0x9FFF)) {
                        $isWide = $true
                    }
                }
            }
            if ($hc.Length -gt 0 -and $hc.Length -le 2 -and -not $isWide) { $hc } else { '>' }
        } else { '>' }

        # SyntaxFg for key-hint text in footer
        $syntaxCol = if ($themeObj.ContainsKey('SyntaxFg')) { $themeObj['SyntaxFg'] } else { 'white' }
        $hiSyntaxRaw = New-AsciiColor -String "X" -Color $syntaxCol
        $hiSyntax = if ($hiSyntaxRaw.EndsWith("[0m")) { $hiSyntaxRaw.Substring(0, $hiSyntaxRaw.Length - 5) } else { "" }

        # ── Key code map ──────────────────────────────────────────────────────
        # ReadKey returns ConsoleKeyInfo; we match on .Key
        $keyUp      = [System.ConsoleKey]::UpArrow
        $keyDown    = [System.ConsoleKey]::DownArrow
        $keyLeft    = [System.ConsoleKey]::LeftArrow
        $keyRight   = [System.ConsoleKey]::RightArrow
        $keyPgUp    = [System.ConsoleKey]::PageUp
        $keyPgDown  = [System.ConsoleKey]::PageDown
        $keyHome    = [System.ConsoleKey]::Home
        $keyEnd     = [System.ConsoleKey]::End
        $keyQ       = [System.ConsoleKey]::Q
        $keyEsc     = [System.ConsoleKey]::Escape

        # ── Render helpers ────────────────────────────────────────────────────
        function _moveTo([int]$row, [int]$col) {
            # 1-indexed ANSI positioning
            [Console]::Write("${esc}[$($row + 1);$($col + 1)H")
        }

        function _clearLine([int]$row) {
            _moveTo $row 0
            [Console]::Write("${esc}[2K")
        }

        function _writeBar([string]$text, [int]$row) {
            _clearLine $row
            _moveTo $row 0
            $barWidth = [Console]::WindowWidth
            # Pad/truncate to window width accounting for ANSI
            $plain = $ansiPattern.Replace($text, '')
            $padded = $plain.PadRight($barWidth).Substring(0, [Math]::Min($plain.Length + ([Math]::Max(0, $barWidth - $plain.Length)), $barWidth))
            [Console]::Write("${barStyle}${bold} ${padded} ${reset}")
        }

        function _renderPage([int]$topLine) {
            # Clear and render visible lines
            $winH = [Console]::WindowHeight
            $winW = [Console]::WindowWidth
 
            for ($row = 0; $row -lt $effectivePage; $row++) {
                _clearLine ($row + $headerRows)
                $lineIdx = $topLine + $row
                if ($lineIdx -lt $totalLines) {
                    _moveTo ($row + $headerRows) 0
                    $line = $displayLines[$lineIdx]
                    # Render taking into account horizontal scrolling and console width
                    # Use Clap-SliceAnsi to scroll and prevent line tearing/wrapping
                    $renderedLine = if ([string]::IsNullOrEmpty($line)) {
                        ""
                    } elseif ($leftScroll -gt 0) {
                        Clap-SliceAnsi -Text $line -Start $leftScroll -Width $winW
                    } else {
                        Clap-TruncateAnsi -Text $line -MaxVisible $winW
                    }
                    [Console]::Write($renderedLine)
                }
            }
        }

        function _renderHeader([int]$topLine) {
            $totalPages = [Math]::Ceiling($totalLines / $effectivePage)
            $curPage    = [Math]::Floor($topLine / $effectivePage) + 1
            $pct        = if ($totalLines -gt 0) { [Math]::Round(($topLine + $effectivePage) / $totalLines * 100) } else { 100 }
            $pct        = [Math]::Min(100, $pct)
            $sep = "  ${themeSepChar}  "
            $headerText = " ${hiGreen}${bold}$themeTitleChar $Title${reset}${barStyle}${sep}${hiCyan}Page $curPage/$totalPages${reset}${barStyle}${sep}Lines $($topLine+1)-$([Math]::Min($topLine+$effectivePage,$totalLines))/$totalLines  $pct%%"
            _writeBar $headerText 0
        }

        function _renderFooter() {
            $sep = "  ${themeSepChar}  "
            $footerText = " ${hiGreen}${bold}u/d${reset}${barStyle} Scroll${sep}${hiGreen}${bold}PgUp/PgDn${reset}${barStyle} Page${sep}${hiGreen}${bold}Home/End${reset}${barStyle} Jump${sep}${hiSyntax}l/r${reset}${barStyle} H-Scroll${sep}${hiGreen}${bold}q/ESC${reset}${barStyle} Quit"
            $row = $headerRows + $effectivePage
            _writeBar $footerText $row
        }

        # ── Pre-render setup ──────────────────────────────────────────────────
        $origCursorVisible = $true
        try { $origCursorVisible = [Console]::CursorVisible } catch {}
        $origTreatCAsInput = $false
        try { $origTreatCAsInput = [Console]::TreatControlCAsInput } catch {}

        # Save screen state (xterm alternate buffer)
        [Console]::Write("${esc}[?1049h")  # enter alternate screen buffer
        [Console]::Write($hideCur)
        try { [Console]::TreatControlCAsInput = $true } catch {}
 
        $topLine = 0
        $leftScroll = 0

        try {
            # Initial render
            [Console]::Write($clearSc)
            _renderHeader $topLine
            _renderPage $topLine
            _renderFooter

            # ── Event loop ────────────────────────────────────────────────────
            if ($env:UHWRITER_TEST_MODE -eq 'true' -or -not [Environment]::UserInteractive) {
                # In test mode or non-interactive CI environments, bypass key reading
                break
            }

            $lastWidth = [Console]::WindowWidth
            $lastHeight = [Console]::WindowHeight

            while ($true) {
                # ── Check for Console Resize ──────────────────────────────────
                $curWidth = [Console]::WindowWidth
                $curHeight = [Console]::WindowHeight
                if ($curWidth -ne $lastWidth -or $curHeight -ne $lastHeight) {
                    $lastWidth = $curWidth
                    $lastHeight = $curHeight

                    if ($null -ne $OnResize) {
                        # Trigger regeneration callback with new dimensions
                        $newContent = & $OnResize $curWidth $curHeight
                        
                        $buffer.Clear()
                        foreach ($item in $newContent) {
                            if ($null -eq $item) { continue }
                            $text = $item.ToString()
                            $lines = $text -split '\r?\n'
                            foreach ($line in $lines) { $buffer.Add($line) }
                        }
                        
                        $displayLines = [System.Collections.Generic.List[string]]::new()
                        if ($NoColor) {
                            foreach ($l in $buffer) {
                                $displayLines.Add($ansiPattern.Replace($l, ''))
                            }
                        } else {
                            foreach ($l in $buffer) {
                                $displayLines.Add($l)
                            }
                        }
                        $totalLines = $displayLines.Count
                    }

                    # Recalculate effective page height
                    $effectivePage = if ($PageSize -gt 0) {
                        $PageSize
                    } else {
                        [Math]::Max(5, $curHeight - $headerRows - $footerRows - 1)
                    }

                    # Cap topLine to new bounds
                    $maxTop = [Math]::Max(0, $totalLines - $effectivePage)
                    if ($topLine -gt $maxTop) {
                        $topLine = $maxTop
                    }

                    [Console]::Write($clearSc)
                    _renderHeader $topLine
                    _renderPage $topLine
                    _renderFooter
                }

                if ([Console]::KeyAvailable) {
                    $keyInfo = [Console]::ReadKey($true)
                    $k       = $keyInfo.Key
                    $changed = $false

                    # Intercept Ctrl+C
                    if ($k -eq [System.ConsoleKey]::C -and ($keyInfo.Modifiers -band [System.ConsoleModifiers]::Control)) {
                        break
                    }

                    $maxTop = [Math]::Max(0, $totalLines - $effectivePage)

                    if ($k -eq $keyDown) {
                        if ($topLine -lt $maxTop) { $topLine++; $changed = $true }
                    } elseif ($k -eq $keyUp) {
                        if ($topLine -gt 0) { $topLine--; $changed = $true }
                    } elseif ($k -eq $keyRight) {
                        $leftScroll += 8; $changed = $true
                    } elseif ($k -eq $keyLeft) {
                        if ($leftScroll -gt 0) {
                            $leftScroll = [Math]::Max(0, $leftScroll - 8)
                            $changed = $true
                        }
                    } elseif ($k -eq $keyPgDown) {
                        $topLine = [Math]::Min($topLine + $effectivePage, $maxTop); $changed = $true
                    } elseif ($k -eq $keyPgUp) {
                        $topLine = [Math]::Max(0, $topLine - $effectivePage); $changed = $true
                    } elseif ($k -eq $keyHome) {
                        $topLine = 0; $leftScroll = 0; $changed = $true
                    } elseif ($k -eq $keyEnd) {
                        $topLine = $maxTop; $changed = $true
                    } elseif ($k -eq $keyQ -or $k -eq $keyEsc) {
                        break
                    }

                    if ($changed) {
                        _renderHeader $topLine
                        _renderPage $topLine
                        _renderFooter
                    }
                }

                [System.Threading.Thread]::Sleep(30)
            }
        } finally {
            # ── Restore terminal state ────────────────────────────────────────
            [Console]::Write($showCur)
            [Console]::Write("${esc}[?1049l")  # exit alternate screen buffer
            try { [Console]::CursorVisible = $origCursorVisible } catch {}
            try { [Console]::TreatControlCAsInput = $origTreatCAsInput } catch {}

            if ($KeepOutput) {
                $outputStr = $displayLines -join [Environment]::NewLine
                [System.Console]::WriteLine($outputStr)
            }
        }
    }
}
