function Show-UHTheme {
    <#
    .SYNOPSIS
      Displays a visual preview of one or all UHWriter themes.
    .DESCRIPTION
      Renders mock cmdlet help text and banner logos using the specified theme
      and layout, providing developers with a direct terminal preview of the themes.
      Supports showcasing custom RGB / true-color palettes, optional outer borders
      with gradient support, header gradient rendering, and compact layout mode.
    .PARAMETER Name
      Name of the theme to preview (e.g. 'default', 'cyberpunk', 'aurora').
      Set to 'all' or use the -All switch to preview all themes.
      Set to 'custom-rgb' to preview a dynamically generated RGB true-color theme.
      Default is 'default'.
    .PARAMETER Layout
      The ASCII banner layout style: 'Box', 'Classic', 'Minimal', 'Man', 'Terminal', 'Typewriter'.
      Default is 'Box'.
    .PARAMETER All
      Switch to display previews for all predefined themes.
    .PARAMETER Minimal
      Switch to render only the ASCII banner logo and version header rather than full cmdlet help.
    .PARAMETER Compact
      Switch to suppress blank lines between parameter rows, producing a tight, single-line-per-param
      output. Equivalent to passing -LineSpacing 0 to New-UHWriter. Useful when previewing many
      themes back-to-back or in narrow terminal environments.
    .PARAMETER Gradient
      Enable gradient color rendering for elements selected by GradientTarget.
    .PARAMETER CustomGradient
      An ordered array of two or more xterm-256 color indices overriding theme gradient stops.
    .PARAMETER GradientTarget
      Help elements receiving gradient color. Default is Title; use All for every supported element.
    .PARAMETER GradientMode
      Gradient direction for multi-line title art: Horizontal, Vertical, or PerToken.
    .PARAMETER OuterBorder
      Wrap the entire preview output in a single-line border box. The border style and color are
      sourced from the active theme. Use -BorderGradient or -BorderCustomGradient to apply gradient
      coloring to the border itself.
    .PARAMETER BorderGradient
      Apply a gradient to the outer border lines. Gradient stops are sourced from the theme's
      GradientSteps key, or from -BorderCustomGradient if supplied.
    .PARAMETER BorderCustomGradient
      An ordered array of two or more xterm-256 color indices defining the border gradient stops.
      Only used when -BorderGradient is also specified or -OuterBorder is specified with this param.
    .PARAMETER SourceType
      Header label identifying the documentation target type: 'module', 'script', 'tool', 'plugin', 'cli', 'function', or 'workflow'.
      Passed through to New-UHWriter. Default is 'module'.
    .PARAMETER TextSpacing
      Enable character spacing in the banner header title (e.g. 'P H W R I T E R' instead of 'UHWRITER').
      Passed through to Write-UHAsciiLogo via New-UHWriter.
    .PARAMETER Help
      Display help output for Show-UHTheme itself.
    .EXAMPLE
      Show-UHTheme -Name 'cyberpunk'
      Previews the 'cyberpunk' theme with the default 'Box' layout.
    .EXAMPLE
      Show-UHTheme -All -Layout 'Terminal' -Minimal
      Previews all 50 themes using the 'Terminal' layout in minimal mode.
    .EXAMPLE
      Show-UHTheme -Name 'custom-rgb' -Layout 'Classic'
      Previews a custom RGB/TrueColor theme using the 'Classic' banner layout.
    .EXAMPLE
      Show-UHTheme -Name 'aurora' -Gradient -OuterBorder -BorderGradient
      Previews the 'aurora' theme with a gradient header and gradient outer border.
    .EXAMPLE
      Show-UHTheme -Name 'matrix' -Compact
      Previews the 'matrix' theme with compact (no blank lines between params) output.
    .EXAMPLE
      Show-UHTheme -All -Compact -Layout 'Minimal'
      Previews all themes in compact minimal mode — useful for rapid visual comparison.
    #>
    [CmdletBinding()]
    [Alias('shldc')]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [ValidateSet(
                'default', 'matrix', 'cyberpunk', 'dracula', 'nord', 'monokai', 'solarized',
                'sunset', 'forest', 'classic', 'aurora', 'neon-noir', 'lava', 'ocean', 'toxic',
                'midnight', 'gold', 'rose', 'steel', 'uhwriter', 'glitch', 'cosmic',
                'forest-mist', 'blood-moon', 'retro-arcade', 'abyss', 'zen', 'blaze', 'rust',
                'matrix-neon', 'quantum', 'radioactive', 'vaporwave', 'nebula', 'crystal',
                'copper', 'royal', 'desert-heat', 'sheriff', 'frost',
                'drift-blue-orange', 'steel-plate', 'cyber-grid', 'retro-blocks', 'gothic-crypt',
                'acid-shards', 'aurora-borealis', 'solar-flare', 'subspace', 'neon-horizon',
                'custom-rgb', 'all'
        )]
        [string]$Name = 'uhwriter',

        [Parameter()]
        [ValidateSet('Box', 'Classic', 'Minimal', 'Man', 'Terminal', 'Typewriter')]
        [string]$Layout = 'Box',

        [Parameter()]
        [switch]$All,

        [Parameter()]
        [switch]$Minimal,

        # ── Compact layout ───────────────────────────────────────────────────────
        [Parameter(HelpMessage = "Suppress blank lines between parameter rows (LineSpacing 0).")]
        [switch]$Compact,

        # ── Header gradient ──────────────────────────────────────────────────────
        [Parameter(HelpMessage = "Enable gradient color for the banner header.")]
        [switch]$Gradient,

        [Parameter(HelpMessage = "xterm-256 color-index stops for the header gradient.")]
        [Alias('CustomGradnet')]
        [int[]]$CustomGradient,

        [Parameter(HelpMessage = "Help elements that receive the theme or custom gradient.")]
        [ValidateSet('Title', 'Header', 'Section', 'Syntax', 'Description', 'ParameterName', 'ParameterType', 'ParameterDescription', 'Example', 'Docs', 'All')]
        [string[]]$GradientTarget = @('Title'),

        [Parameter(HelpMessage = "The gradient mode: Horizontal, Vertical, or PerToken.")]
        [ValidateSet('Horizontal', 'Vertical', 'PerToken')]
        [string]$GradientMode = 'Horizontal',

        # ── Outer border ─────────────────────────────────────────────────────────
        [Parameter(HelpMessage = "Wrap the entire preview output in a border box.")]
        [switch]$OuterBorder,

        [Parameter(HelpMessage = "Apply a gradient to the outer border.")]
        [switch]$BorderGradient,

        [Parameter(HelpMessage = "xterm-256 color-index stops for the border gradient.")]
        [Alias('BorderCustomGradnet')]
        [int[]]$BorderCustomGradient,

        # ── Source type / header label ────────────────────────────────────────────
        [Parameter(HelpMessage = "Header label type: module, script, tool, plugin, cli, function, workflow.")]
        [ValidateSet('module', 'script', 'tool', 'plugin', 'cli', 'function', 'workflow', 'router')]
        [string]$SourceType = 'module',

        # ── Banner text spacing ───────────────────────────────────────────────────
        [Parameter(HelpMessage = "Enable character spacing in the banner header title.")]
        [switch]$TextSpacing,

        # ── Outer border style ────────────────────────────────────────────
        [Parameter(HelpMessage = "Outer border corner and side style. Requires -OuterBorder.")]
        [ValidateSet('Rounded', 'Square', 'Double', 'Block', 'Simple')]
        [string]$OuterBorderStyle = 'Rounded',

        [Parameter(HelpMessage = "Filter the PARAMETERS section to entries matching this string (partial, case-insensitive).")]
        [string]$HelpParam,

        [Parameter(HelpMessage = "Render only the selected help sections.")]
        [Alias('HelpTitle', 'FilterTitle')]
        [ValidateSet('Syntax', 'Description', 'Subcommands', 'Parameters', 'Examples', 'Docs')]
        [string[]]$HelpSection,

        [Parameter(HelpMessage = "Display-label overrides for help sections.")]
        [hashtable]$SectionLabel = @{},

        [Parameter(HelpMessage = "Display Help for Show-UHTheme.")]
        [switch]$Help
    )

    begin {}

    process {
        # Rebuild per-call mock and layout values so pipeline input refreshes them for every theme
        $mockCommandInfo = @{
            cmdlet      = "Get-SampleCmdlet"
            synopsis    = "Get-SampleCmdlet [-Path <String>] [-Force] [-Verbose]"
            description = "This sample cmdlet retrieves configuration data and performs basic validation checks. It is formatted to show the colors and layouts of the theme."
            source      = "https://gitlab.com/phellams/uhwriter"
        }
        $mockParams = @(
            @{
                name        = "Path"
                param       = "p|Path"
                type        = "String"
                description = "Specifies the filesystem path to the target config file."
                required    = $true
                inline      = $false
            },
            @{
                name        = "Force"
                param       = "f|Force"
                type        = "Switch"
                description = "Force the operation to complete without prompting."
                required    = $false
                inline      = $true
            }
        )
        $mockExamples = @(
            "Get-SampleCmdlet -Path 'config.json' -Force",
            "Get-SampleCmdlet -Path '/etc/app/config.json' -Verbose"
        )
        $resolvedLineSpacing = if ($Compact) { 0 } else { 1 }

        if ($Help) {
            $showtheme_ParamTable = @(
                @{
                    name        = "Name"
                    param       = "n|Name"
                    type        = "String"
                    description = "Name of the theme to preview, or 'all', or 'custom-rgb'."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "Layout"
                    param       = "l|Layout"
                    type        = "String"
                    description = "The ASCII banner layout style: 'Box', 'Classic', 'Minimal', 'Man', 'Terminal', 'Typewriter'."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "All"
                    param       = "a|All"
                    type        = "Switch"
                    description = "Preview all 50 built-in themes sequentially."
                    required    = $false
                    inline      = $true
                },
                @{
                    name        = "Minimal"
                    param       = "m|Minimal"
                    type        = "Switch"
                    description = "Render only the ASCII banner logo and version header."
                    required    = $false
                    inline      = $true
                },
                @{
                    name        = "Compact"
                    param       = "c|Compact"
                    type        = "Switch"
                    description = "Suppress blank lines between parameter rows. Equivalent to -LineSpacing 0 on New-UHWriter."
                    required    = $false
                    inline      = $true
                },
                @{
                    name        = "Gradient"
                    param       = "g|Gradient"
                    type        = "Switch"
                    description = "Enable gradient color rendering for the banner header."
                    required    = $false
                    inline      = $true
                },
                @{
                    name        = "CustomGradient"
                    param       = "cg|CustomGradient"
                    type        = "Int[]"
                    description = "xterm-256 color-index stops defining the header gradient. Requires -Gradient."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "OuterBorder"
                    param       = "ob|OuterBorder"
                    type        = "Switch"
                    description = "Wrap the entire preview output in a single-line border box."
                    required    = $false
                    inline      = $true
                },
                @{
                    name        = "BorderGradient"
                    param       = "bg|BorderGradient"
                    type        = "Switch"
                    description = "Apply a gradient to the outer border lines. Requires -OuterBorder."
                    required    = $false
                    inline      = $true
                },
                @{
                    name        = "BorderCustomGradient"
                    param       = "bcg|BorderCustomGradient"
                    type        = "Int[]"
                    description = "xterm-256 color-index stops defining the border gradient stops."
                    required    = $false
                    inline      = $false
                }
            )
            $showtheme_commandinfo = @{
                cmdlet      = "Show-UHTheme"
                synopsis    = "Show-UHTheme [-Name <String>] [-Layout <String>] [-All] [-Minimal] [-Compact] [-Gradient] [-OuterBorder] [-BorderGradient]"
                description = "Displays a visual preview of one or all UHWriter themes. Supports compact layout, header gradients, and optional outer borders with gradient rendering."
                source      = "https://gitlab.com/phellams/uhwriter"
            }
            $showtheme_examples = @(
                "Show-UHTheme -Name 'cyberpunk'",
                "Show-UHTheme -All -Layout 'Terminal' -Minimal",
                "Show-UHTheme -Name 'aurora' -Gradient -OuterBorder -BorderGradient",
                "Show-UHTheme -All -Compact -Layout 'Minimal'"
            )
            New-UHWriter -Name 'UHWRITER' -CommandInfo $showtheme_commandinfo -ParamTable $showtheme_ParamTable -Padding 4 -Indent 2 -Theme 'default' -Version '1.0.0' -Examples $showtheme_examples
            return
        }

        # Determine which themes to show
        $themesToShow = @()
        $isCustomRgb = $false

        if ($All -or $Name -eq 'all') {
            # List of all unique predefined themes
            $themesToShow = @(
                'default', 'matrix', 'cyberpunk', 'dracula', 'nord', 'monokai', 'solarized',
                'sunset', 'forest', 'classic', 'aurora', 'neon-noir', 'lava', 'ocean', 'toxic',
                'midnight', 'gold', 'rose', 'steel', 'uhwriter', 'glitch', 'cosmic',
                'forest-mist', 'blood-moon', 'retro-arcade', 'abyss', 'zen', 'blaze', 'rust',
                'matrix-neon', 'quantum', 'radioactive', 'vaporwave', 'nebula', 'crystal',
                'copper', 'royal', 'desert-heat', 'sheriff', 'frost',
                'drift-blue-orange', 'steel-plate', 'cyber-grid', 'retro-blocks', 'gothic-crypt',
                'acid-shards', 'aurora-borealis', 'solar-flare', 'subspace', 'neon-horizon'
            )
        } elseif ($Name -eq 'custom-rgb') {
            $isCustomRgb = $true
            $themesToShow = @('custom-rgb')
        } else {
            $themesToShow = @($Name)
        }

        foreach ($themeName in $themesToShow) {
            $esc = [char]27
            $reset = "$esc[0m"
            [console]::WriteLine("`n$esc[1;4mTheme Preview: $themeName$reset`n")

            $themeObj = $null
            if ($isCustomRgb) {
                # Showcase dynamic RGB / TrueColor palette
                $themeObj = @{
                    AccentColor      = '255;128;0'       # Orange RGB (r;g;b)
                    AccentFormat     = 'bold'
                    BorderColor      = '0;255;128'       # Spring Green RGB
                    BorderFormat     = 'bold'
                    HeaderBg         = '38;2;16;16;32'   # Very dark blue background
                    HeaderFg         = '0;255;255'       # Cyan RGB
                    ModuleBg         = '38;2;16;16;32'
                    ModuleFg         = '255;0;255'       # Magenta RGB
                    VersionBg        = '38;2;16;16;32'
                    VersionFg        = '255;255;0'       # Yellow RGB
                    SyntaxFg         = '255;255;255'     # White RGB
                    SyntaxFormat     = 'none'
                    DescriptionFg    = '200;200;200'     # Light Grey RGB
                    ParamNameFg      = '0;128;255'       # Sky Blue RGB
                    ParamNameFormat  = 'bold'
                    ParamTypeFg      = '0;255;255'       # Cyan RGB
                    ParamTypeFormat  = 'italic'
                    ParamReqFg       = '255;0;0'         # Red RGB
                    ParamReqFormat   = 'bold,reverse'
                    ParamDescFg      = '150;150;150'     # Grey RGB
                    ExampleFg        = '255;255;0'       # Yellow RGB
                    DocsFg           = '0;255;128'       # Spring Green RGB
                    DocsFormat       = 'underline'
                    SectionChar      = '⚡'
                    HeaderChar       = '»'
                    BorderTop        = '⚡════════════════════════════════════════════════════════════⚡'
                    BorderBottom     = '⚡════════════════════════════════════════════════════════════⚡'
                    BorderMiddle     = '░'
                }
            } else {
                $themeObj = Get-UHTheme -Name $themeName
            }

            if ($Minimal) {
                # Render only the logo and the version header
                Write-UHAsciiLogo -Name 'SAMPLE' -Version '1.0.0' -Theme $themeObj -Layout $Layout

                # Render metadata line
                $sectionChar = if ($themeObj.ContainsKey('SectionChar')) { $themeObj['SectionChar'] } else { '◉' }
                $headerChar = if ($themeObj.ContainsKey('HeaderChar')) { $themeObj['HeaderChar'] } else { '▶' }
                $styledHeadChar = if ($headerChar) { Format-ThemeText -String " $headerChar " -Theme $themeObj -Element 'Accent' } else { " " }

                $typeStr = if ($SourceType -eq 'router') { 'CLI' } else { $SourceType.ToUpper() }
                $cmdletLabel = if ($SourceType -eq 'router') { 'FUNCTION' } else { 'CMDLET' }

                $headerParts = @()
                $headerParts += "$(Format-ThemeText -String " $typeStr " -Theme $themeObj -Element 'Accent') $(Format-ThemeText -String " SAMPLE " -Theme $themeObj -Element 'Header')"
                $headerParts += "$(Format-ThemeText -String " $cmdletLabel " -Theme $themeObj -Element 'Accent') $(Format-ThemeText -String " Get-SampleCmdlet " -Theme $themeObj -Element 'Header')"
                $headerParts += "$(Format-ThemeText -String ' VERSION ' -Theme $themeObj -Element 'Accent') $(Format-ThemeText -String ' v1.0.0 ' -Theme $themeObj -Element 'Version')"

                [console]::WriteLine(" " + ($headerParts -join $styledHeadChar))
                [console]::WriteLine("─" * 70)
            } else {
                # Build splatted params for New-UHWriter — only include gradient/border params when
                # the caller has explicitly enabled them so that themes without GradientSteps do not
                # attempt gradient rendering by default.
                $writerParams = @{
                    Name        = 'SAMPLE'
                    Version     = '1.0.0'
                    CommandInfo = $mockCommandInfo
                    ParamTable  = $mockParams
                    Examples    = $mockExamples
                    Theme       = $themeObj
                    Layout      = $Layout
                    LineSpacing = $resolvedLineSpacing
                    SourceType  = $SourceType
                }

                if ($Gradient)        { $writerParams['Gradient']         = $true }
                if ($CustomGradient)  { $writerParams['CustomGradient']   = $CustomGradient }
                $writerParams['GradientTarget'] = $GradientTarget
                if ($PSBoundParameters.ContainsKey('GradientMode')) { $writerParams['GradientMode'] = $GradientMode }
                if ($OuterBorder)     { $writerParams['OuterBorder']      = $true }
                if ($BorderGradient)  { $writerParams['BorderGradient']   = $true }
                if ($BorderCustomGradient) { $writerParams['BorderCustomGradient'] = $BorderCustomGradient }
                if ($OuterBorderStyle -ne 'Rounded') { $writerParams['OuterBorderStyle'] = $OuterBorderStyle }
                if (-not [string]::IsNullOrWhiteSpace($HelpParam)) { $writerParams['HelpParam'] = $HelpParam }
                if ($HelpSection -and $HelpSection.Count -gt 0) { $writerParams['HelpSection'] = $HelpSection }
                if ($SectionLabel.Count -gt 0) { $writerParams['SectionLabel'] = $SectionLabel }

                New-UHWriter @writerParams
            }
            [console]::WriteLine()
        }
    }
}
