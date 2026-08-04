function New-UHWriter {

    <#
    .SYNOPSIS
      Generates formatted, ANSI-colored help text for PowerShell cmdlets and router functions.
    .DESCRIPTION
      Outputs man-page style documentation with customizable layout, alignment, and 50 built-in themes.
      Supports documenting both parameters and router subcommands. All output is ANSI/VT100 formatted
      and rendered via [System.Console]::WriteLine for cross-platform compatibility and raw performance.

      Layout spacing is controlled by -LineSpacing (0=compact, 1=default, 2=spacious) or the
      convenience -Compact switch which is equivalent to -LineSpacing 0. When -Compact and -LineSpacing
      are both supplied, -Compact takes precedence.

      Outer borders with optional gradient rendering are supported via -OuterBorder, -BorderGradient,
      and -BorderCustomGradient. Header gradient rendering is supported via -Gradient and -CustomGradient.
    .PARAMETER JsonFile
      JSON file containing help configuration parameters to load.
    .PARAMETER Name
      The name of the module/tool. Default is 'UHW'.
    .PARAMETER CommandInfo
      A hashtable or custom object containing command metadata: cmdlet, synopsis, description, source.
    .PARAMETER ParamTable
      An array of hashtables defining parameters: name, param, type, required, description, inline.
    .PARAMETER Subcommands
      An array of hashtables defining router subcommands: name, syntax, description.
    .PARAMETER Examples
      An array of usage example strings.
    .PARAMETER Version
      The module version to display. Default is '1.0.0'.
    .PARAMETER Padding
      Spaces of padding between columns. Default is 3. Increase for a more airy look, decrease for compact output.
    .PARAMETER Indent
      Spaces of left indentation for each line. Default is 1.
    .PARAMETER LineSpacing
      Number of blank lines between each parameter row. Default is 1. Set 0 for compact mode.
    .PARAMETER Compact
      Convenience switch that sets LineSpacing to 0. Produces a tight, single-line-per-param output.
      Takes precedence over -LineSpacing when both are specified.
    .PARAMETER SourceType
      Header label identifying the documentation target type: 'module', 'script', 'tool', or 'plugin'. Default is 'module'.
    .PARAMETER Theme
      The name of a default theme ('default', 'matrix', 'cyberpunk', etc.) or a custom theme hashtable.
    .PARAMETER Layout
      The ASCII banner layout: 'Box', 'Classic', 'Minimal', 'Man', 'Terminal', 'Typewriter'. Default is 'Box'.
    .PARAMETER CustomLogo
      An optional custom ASCII logo string.
    .PARAMETER Gradient
      Enable gradient color for the elements selected by GradientTarget.
    .PARAMETER CustomGradient
      An ordered array of two or more xterm-256 color indices overriding the theme gradient stops.
    .PARAMETER GradientTarget
      Help elements receiving gradient color. Supports Title, Header, Section, Syntax, Description,
      ParameterName, ParameterType, ParameterDescription, Example, Docs, and All. Default is Title.
    .PARAMETER GradientMode
      Gradient direction for multi-line title art: Horizontal, Vertical, or PerToken.
    .PARAMETER OuterBorder
      Wrap the entire help output in a single-line border box. Border style and color are sourced from
      the active theme. Use -BorderGradient or -BorderCustomGradient for gradient border coloring.
    .PARAMETER BorderGradient
      Apply a gradient to the outer border lines. Gradient stops sourced from the theme's GradientSteps
      key, or from -BorderCustomGradient when supplied.
    .PARAMETER BorderCustomGradient
      An ordered array of two or more xterm-256 color indices defining the border gradient stops.
    .PARAMETER OuterBorderStyle
      Selects the corner and side glyph style for the outer border. One of: 'Rounded' (default, ╭╮╰╯│),
      'Square' (┌┐└┘│), 'Double' (╔╗╚╝║║═), 'Block' (██▓▓), 'Simple' (++--).
      Only takes effect when -OuterBorder is specified.
    .PARAMETER InputObject
      A metadata hashtable or PSCustomObject produced by Export-UHWriterMetadata. When piped,
      all recognised fields (name, commandinfo, paramtable, sourcetype, examples, version) are
      mapped into the corresponding New-UHWriter parameters. Any explicitly provided parameters
      take precedence over the piped values.
    .PARAMETER HelpParam
      When specified, restricts the rendered PARAMETERS section to the single entry whose name
      or alias contains this string (case-insensitive, partial match). The header, syntax, and
      description sections are still rendered. Useful for quick targeted lookups.
    .PARAMETER HelpSection
      Restricts output to one or more named content sections. Valid values are Syntax, Description,
      Subcommands, Parameters, Examples, and Docs. The banner and metadata header remain visible.
      Omit this parameter to render every available section.
    .PARAMETER SectionLabel
      Display-label overrides keyed by Syntax, Description, Subcommands, Parameters, Examples, or
      Docs. Filtering continues to use the canonical section names.
    .PARAMETER Renderer
      Selects the rendering backend. Auto uses the portable .NET core when available and otherwise
      falls back to the PowerShell renderer. DotNet requires the core. PowerShell forces the legacy
      renderer for compatibility comparison and troubleshooting.
    .PARAMETER Help
      Switch to display help information for New-UHWriter itself.
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType('void')]
    param(
        # ── Pipeline input from Export-UHWriterMetadata ───────────────────────
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, HelpMessage = "Metadata object from Export-UHWriterMetadata.")]
        [object]$InputObject,

        [Parameter(Mandatory = $false, HelpMessage = "Json File to import help data from.")]
        [string]$JsonFile,

        [Parameter(HelpMessage = "Sets the Name of the module to display.")]
        [string]$Name,

        [Parameter(Mandatory = $false, HelpMessage = "Command details: cmdlet, synopsis, description, source.")]
        [object]$CommandInfo,

        [Parameter(Mandatory = $false, HelpMessage = "An array of hashtables defining parameters.")]
        [array]$ParamTable,

        [Parameter(Mandatory = $false, HelpMessage = "An array of hashtables defining router subcommands.")]
        [array]$Subcommands,

        [Parameter(Mandatory = $false, HelpMessage = "Example command calls.")]
        [string[]]$Examples,

        [Parameter(Mandatory = $false, HelpMessage = "Version of the command to display.")]
        [string]$Version,

        [Parameter(HelpMessage = "Number of spaces for padding between columns. Default: 3.")]
        [int]$Padding = 3,

        [Parameter(HelpMessage = "Number of spaces for left indentation of each line. Default: 1.")]
        [int]$Indent = 1,

        [Parameter(HelpMessage = "Blank lines between parameter rows. 0=compact, 1=default, 2=spacious.")]
        [ValidateRange(0, 4)]
        [int]$LineSpacing = 1,

        [Parameter(HelpMessage = "Convenience switch — sets LineSpacing to 0. Takes precedence over -LineSpacing.")]
        [switch]$Compact,

        [Parameter(HelpMessage = "Header label type: module, script, tool, or plugin.")]
        [ValidateSet('module', 'script', 'tool', 'plugin', 'cli', 'function', 'workflow', 'router')]
        [string]$SourceType = 'module',

        [Parameter(HelpMessage = "Theme name or custom theme hashtable.")]
        [ValidateScript({
            # Accept a hashtable (custom theme object) or a valid built-in name string
            if ($_ -is [hashtable]) { return $true }
            $validNames = @(
                'default', 'matrix', 'cyberpunk', 'dracula', 'nord', 'monokai', 'solarized',
                'sunset', 'forest', 'classic', 'aurora', 'neon-noir', 'lava', 'ocean', 'toxic',
                'midnight', 'gold', 'rose', 'steel', 'uhwriter', 'glitch', 'cosmic',
                'forest-mist', 'blood-moon', 'retro-arcade', 'abyss', 'zen', 'blaze', 'rust',
                'matrix-neon', 'quantum', 'radioactive', 'vaporwave', 'nebula', 'crystal',
                'copper', 'royal', 'desert-heat', 'sheriff', 'frost',
                'drift-blue-orange', 'steel-plate', 'cyber-grid', 'retro-blocks', 'gothic-crypt',
                'acid-shards', 'aurora-borealis', 'solar-flare', 'subspace', 'neon-horizon'
            )
            if ($_ -is [string] -and $validNames -contains $_) { return $true }
            throw "Invalid -Theme value '$_'. Provide a valid built-in theme name or a custom theme hashtable."
        })]
        $Theme = 'uhwriter',

        [Parameter(HelpMessage = "The ASCII banner layout style.")]
        [ValidateSet('Box', 'Classic', 'Minimal', 'Man', 'Terminal', 'Typewriter')]
        [string]$Layout = 'Box',

        [Parameter(HelpMessage = "Custom logo banner string.")]
        [string]$CustomLogo = $null,

        [Parameter(HelpMessage = "Enable gradient color for the header.")]
        [switch]$Gradient,

        [Parameter(HelpMessage = "Custom gradient color steps.")]
        [Alias('CustomGradnet')]
        [int[]]$CustomGradient,

        [Parameter(HelpMessage = "Help elements that receive the theme or custom gradient.")]
        [ValidateSet('Title', 'Header', 'Section', 'Syntax', 'Description', 'ParameterName', 'ParameterType', 'ParameterDescription', 'Example', 'Docs', 'All')]
        [string[]]$GradientTarget = @('Title'),

        [Parameter(HelpMessage = "The gradient mode: Horizontal, Vertical, or PerToken. Sourced from the active theme's GradientMode or defaults to Horizontal.")]
        [ValidateSet('Horizontal', 'Vertical', 'PerToken')]
        [string]$GradientMode = 'Horizontal',

        [Parameter(HelpMessage = "Wrap the entire help output in a border.")]
        [switch]$OuterBorder,

        [Parameter(HelpMessage = "Enable gradient color for the outer border.")]
        [switch]$BorderGradient,

        [Parameter(HelpMessage = "Custom gradient color steps for the outer border.")]
        [Alias('BorderCustomGradnet')]
        [int[]]$BorderCustomGradient,

        [Parameter(HelpMessage = "Outer border corner and side style. One of: Rounded, Square, Double, Block, Simple.")]
        [ValidateSet('Rounded', 'Square', 'Double', 'Block', 'Simple')]
        [string]$OuterBorderStyle = 'Rounded',

        [Parameter(HelpMessage = "The target width of the help output. Can be 'man' (80 cols), 'full' (console width), or a custom integer.")]
        [object]$Width = 'full',

        [Parameter(HelpMessage = "The output mode: 'Standard' (direct dump to standard console), 'Alt' (page dump in alternate screen buffer), 'String' (return output as string), or 'Auto' (page if fits, else alt).")]
        [ValidateSet('Standard', 'Alt', 'String', 'Auto')]
        [string]$OutMode = 'Auto',

        [Parameter(HelpMessage = "Keep help output on stdout when leaving alternate screen buffer pager.")]
        [switch]$KeepOutput = $true,

        [Parameter(HelpMessage = "Rendering backend: Auto, DotNet, or PowerShell.")]
        [ValidateSet('Auto', 'DotNet', 'PowerShell')]
        [string]$Renderer = 'Auto',

        [Parameter(HelpMessage = "Filter PARAMETERS output to entries matching this string (partial, case-insensitive).")]
        [string]$HelpParam,

        [Parameter(HelpMessage = "Render only the selected help sections. Accepts one or more section names.")]
        [Alias('HelpTitle', 'FilterTitle')]
        [ValidateSet('Syntax', 'Description', 'Subcommands', 'Parameters', 'Examples', 'Docs')]
        [string[]]$HelpSection,

        [Parameter(HelpMessage = "Display-label overrides for help sections.")]
        [hashtable]$SectionLabel = @{},

        [Parameter(HelpMessage = "Display Help for New-UHWriter.")]
        [switch]$Help
    )

    process {
        # Internal Help parameters for New-UHWriter itself
        if ($Help) {
            $uhwriter_ParamTable = @(
                @{
                    name        = "JsonFile"
                    param       = "j|JsonFile"
                    type        = "String"
                    description = "JSON file containing help configuration parameters to load."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "Name"
                    param       = "n|Name"
                    type        = "String"
                    description = "The name of the module, script, or tool to display."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "CommandInfo"
                    param       = "c|CommandInfo"
                    type        = "Hashtable"
                    description = "Command details: cmdlet, synopsis, description, source."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "ParamTable"
                    param       = "p|ParamTable"
                    type        = "Hashtable[]"
                    description = "Array of parameter hashtables: name, param, type, required, description, inline."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "Subcommands"
                    param       = "sub|Subcommands"
                    type        = "Hashtable[]"
                    description = "Array of router subcommand hashtables: name, syntax, description."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "Version"
                    param       = "v|Version"
                    type        = "String"
                    description = "Version string to display in the header. Default: '1.0.0'."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "Padding"
                    param       = "pad|Padding"
                    type        = "Int"
                    description = "Column padding in spaces. Default: 3. Lower for compact, higher for airy layout."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "Indent"
                    param       = "i|Indent"
                    type        = "Int"
                    description = "Left indentation in spaces. Default: 1."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "LineSpacing"
                    param       = "ls|LineSpacing"
                    type        = "Int"
                    description = "Blank lines between parameter rows. 0=compact, 1=default, 2=spacious."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "Compact"
                    param       = "co|Compact"
                    type        = "Switch"
                    description = "Convenience switch that forces LineSpacing to 0. Overrides -LineSpacing when both are supplied."
                    required    = $false
                    inline      = $true
                },
                @{
                    name        = "SourceType"
                    param       = "st|SourceType"
                    type        = "String"
                    description = "Label type for the header line: 'module', 'script', 'tool', or 'plugin'. Default: 'module'."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "Theme"
                    param       = "t|Theme"
                    type        = "String|Hashtable"
                    description = "Theme name (20 built-in) or a custom theme hashtable."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "Layout"
                    param       = "l|Layout"
                    type        = "String"
                    description = "Banner layout: 'Box', 'Classic', 'Minimal', 'Man', 'Terminal', 'Typewriter'."
                    required    = $false
                    inline      = $false
                },
                @{
                    name        = "OuterBorderStyle"
                    param       = "obs|OuterBorderStyle"
                    type        = "String"
                    description = "Outer border style: 'Rounded' (default), 'Square', 'Double', 'Block', 'Simple'. Requires -OuterBorder."
                    required    = $false
                    inline      = $false
                }
            )
            $uhwriter_commandinfo = @{
                cmdlet      = "New-UHWriter"
                synopsis    = "New-UHWriter [-Name <String>] [-CommandInfo <Hashtable>] [-ParamTable <Hashtable[]>] [-Theme <String>] [-Layout <String>] [-LineSpacing <Int>] [-SourceType <String>]"
                description = "Generates beautifully formatted, colorized help text for cmdlets and router functions. Supports 50 built-in themes, 6 layouts, compact/spacious line spacing, and dynamic source-type header labeling."
                source      = "https://gitlab.com/phellams/uhwriter/blob/main/README.md"
            }
            $uhwriter_examples = @(
                'New-UHWriter -Help',
                'New-UHWriter -Name "UHWriter" -Theme "matrix" -Layout "Terminal" -CommandInfo $info -ParamTable $params',
                'New-UHWriter -Name "git" -Subcommands $gitSubcommands -Theme "cyberpunk"'
            )

            New-UHWriter -Name 'UHWRITER' -CommandInfo $uhwriter_commandinfo -ParamTable $uhwriter_ParamTable -Padding 4 -Indent 2 -Theme $Theme -Layout $Layout -Version '1.0.0' -Examples $uhwriter_examples
            return
        }

        # ── Pipeline / InputObject mapping ───────────────────────────────────
        # Accept metadata produced by Export-UHWriterMetadata. Explicit params take precedence.
        if ($null -ne $InputObject) {
            # Normalise: support both hashtable and PSCustomObject
            $meta = if ($InputObject -is [System.Collections.IDictionary]) {
                $ht = @{}
                foreach ($key in $InputObject.Keys) { $ht[[string]$key] = $InputObject[$key] }
                $ht
            } else {
                $ht = @{}
                foreach ($p in $InputObject.PSObject.Properties) { $ht[$p.Name.ToLower()] = $p.Value }
                $ht
            }

            # Map both the PowerShell contract and the portable/native JSON contract. Explicit
            # parameters always take precedence over extracted metadata.
            if (-not $PSBoundParameters.ContainsKey('Name')         -and $meta.ContainsKey('name'))        { $Name        = [string]$meta['name'] }
            if (-not $PSBoundParameters.ContainsKey('CommandInfo')) {
                if ($meta.ContainsKey('commandinfo')) { $CommandInfo = $meta['commandinfo'] }
                elseif ($meta.ContainsKey('command')) { $CommandInfo = $meta['command'] }
            }
            if (-not $PSBoundParameters.ContainsKey('ParamTable')) {
                if ($meta.ContainsKey('paramtable')) { $ParamTable = @($meta['paramtable']) }
                elseif ($meta.ContainsKey('parameters')) { $ParamTable = @($meta['parameters']) }
            }
            if (-not $PSBoundParameters.ContainsKey('Subcommands') -and $meta.ContainsKey('subcommands')) { $Subcommands = @($meta['subcommands']) }
            if (-not $PSBoundParameters.ContainsKey('Examples')     -and $meta.ContainsKey('examples'))    { $Examples     = @($meta['examples']) }
            if (-not $PSBoundParameters.ContainsKey('Version')      -and $meta.ContainsKey('version'))     { $Version      = [string]$meta['version'] }
            if (-not $PSBoundParameters.ContainsKey('SourceType') -and ($meta.ContainsKey('sourcetype') -or $meta.ContainsKey('sourceType'))) {
                $st = if ($meta.ContainsKey('sourcetype')) { [string]$meta['sourcetype'] } else { [string]$meta['sourceType'] }
                $validST = @('module','script','tool','plugin','cli','function','workflow','router')
                if ($st -in $validST) { $SourceType = $st }
            }
            # Theme from metadata only when neither explicit param nor global config supplies one
            if (-not $PSBoundParameters.ContainsKey('Theme') -and $meta.ContainsKey('theme')) {
                $Theme = $meta['theme']
            }
        }

        # ── Global config resolution: $global:__uhwriter.theme_config ─────────
        # Priority: explicit -Theme param > global config > built-in default 'uhwriter'
        $globalCfg = $null
        try {
            $gv = $ExecutionContext.SessionState.PSVariable.Get('__uhwriter')
            if ($null -ne $gv -and $gv.Value -is [hashtable] -and $gv.Value.ContainsKey('theme_config')) {
                $globalCfg = $gv.Value['theme_config']
            }
        } catch {}

        if (-not $PSBoundParameters.ContainsKey('Theme') -and $null -ne $globalCfg) {
            # Apply global theme name if not already set by InputObject or explicit param
            if ($globalCfg -is [hashtable] -and $globalCfg.ContainsKey('theme')) {
                $Theme = $globalCfg['theme']
            } elseif ($globalCfg -is [string]) {
                $Theme = $globalCfg
            }
            # Apply other global rendering preferences (only when caller has not set them)
            if ($globalCfg -is [hashtable]) {
                if (-not $PSBoundParameters.ContainsKey('Gradient')    -and $globalCfg.ContainsKey('gradient'))    { $Gradient    = [bool]$globalCfg['gradient'] }
                if (-not $PSBoundParameters.ContainsKey('GradientTarget') -and $globalCfg.ContainsKey('gradienttarget')) { $GradientTarget = [string[]]$globalCfg['gradienttarget'] }
                if (-not $PSBoundParameters.ContainsKey('CustomGradient') -and $globalCfg.ContainsKey('customgradient')) { $CustomGradient = [int[]]$globalCfg['customgradient'] }
                if (-not $PSBoundParameters.ContainsKey('SectionLabel') -and $globalCfg.ContainsKey('sectionlabel')) { $SectionLabel = [hashtable]$globalCfg['sectionlabel'] }
                if (-not $PSBoundParameters.ContainsKey('OuterBorder') -and $globalCfg.ContainsKey('outerborder')) { $OuterBorder = [bool]$globalCfg['outerborder'] }
                if (-not $PSBoundParameters.ContainsKey('Layout')      -and $globalCfg.ContainsKey('layout'))      { $Layout      = [string]$globalCfg['layout'] }
                if (-not $PSBoundParameters.ContainsKey('Compact')     -and $globalCfg.ContainsKey('compact'))     { $Compact     = [bool]$globalCfg['compact'] }
            }
        }

        # ── Resolve Theme object ──────────────────────────────────────────────
        $themeObj = $null
        if ($Theme -is [hashtable]) {
            $themeObj = $Theme
        } else {
            $themeObj = Get-UHTheme -Name $Theme
        }

        # Allow global config to partially override individual theme keys (deep-merge)
        if ($null -ne $globalCfg -and $globalCfg -is [hashtable]) {
            $themeOverrideKeys = @('AccentColor','AccentFormat','BorderColor','BorderFormat',
                'HeaderBg','HeaderFg','ModuleBg','ModuleFg','VersionBg','VersionFg',
                'SyntaxFg','SyntaxFormat','DescriptionFg','ParamNameFg','ParamNameFormat',
                'ParamTypeFg','ParamTypeFormat','ParamReqFg','ParamReqFormat','ParamDescFg',
                'ExampleFg','DocsFg','DocsFormat','SectionChar','HeaderChar')
            foreach ($k in $themeOverrideKeys) {
                if ($globalCfg.ContainsKey($k)) {
                    $themeObj[$k] = $globalCfg[$k]
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('GradientMode')) {
            # User specified, keep it
        } elseif ($themeObj.ContainsKey('GradientMode')) {
            $GradientMode = $themeObj['GradientMode']
        }

        # Load JSON data if a JsonFile is provided
        if ($JsonFile) {
            $jsonFile_FullPath = Get-ChildItem -Path $JsonFile | Select-Object -First 1
            if ($null -ne $jsonFile_FullPath) {
                try {
                    $jsonData = ConvertFrom-Json $([System.IO.File]::ReadAllText($jsonFile_FullPath.FullName)) -AsHashtable
                    # Override variables if they exist in JSON
                    if ($jsonData.name) { $Name = $jsonData.name }
                    if ($jsonData.commandinfo) { $CommandInfo = $jsonData.commandinfo }
                    elseif ($jsonData.command) { $CommandInfo = $jsonData.command }
                    if ($jsonData.paramtable) { $ParamTable = $jsonData.paramtable }
                    elseif ($jsonData.parameters) { $ParamTable = $jsonData.parameters }
                    if ($jsonData.subcommands) { $Subcommands = $jsonData.subcommands }
                    if ($jsonData.examples) { $Examples = $jsonData.examples }
                    if ($jsonData.version) { $Version = $jsonData.version }
                    if ($jsonData.sourcetype) { $SourceType = $jsonData.sourcetype }
                    if ($jsonData.padding) { $Padding = $jsonData.padding }
                    if ($jsonData.indent) { $Indent = $jsonData.indent }
                    if ($jsonData.theme) { $Theme = $jsonData.theme }
                    if ($jsonData.layout) { $Layout = $jsonData.layout }
                    if ($jsonData.customlogo) { $CustomLogo = $jsonData.customlogo }
                    if ($jsonData.ContainsKey('gradient')) { $Gradient = [bool]$jsonData.gradient }
                    if ($jsonData.ContainsKey('customgradient')) { $CustomGradient = [int[]]$jsonData.customgradient }
                    elseif ($jsonData.ContainsKey('customgradnet')) { $CustomGradient = [int[]]$jsonData.customgradnet }
                    if ($jsonData.ContainsKey('gradienttarget')) { $GradientTarget = [string[]]$jsonData.gradienttarget }
                    if ($jsonData.ContainsKey('sectionlabel')) { $SectionLabel = [hashtable]$jsonData.sectionlabel }
                    elseif ($jsonData.ContainsKey('sectionlabels')) { $SectionLabel = [hashtable]$jsonData.sectionlabels }
                    if ($jsonData.ContainsKey('outerborder')) { $OuterBorder = [bool]$jsonData.outerborder }
                    if ($jsonData.ContainsKey('bordergradient')) { $BorderGradient = [bool]$jsonData.bordergradient }
                    if ($jsonData.ContainsKey('bordercustomgradient')) { $BorderCustomGradient = [int[]]$jsonData.bordercustomgradient }
                    elseif ($jsonData.ContainsKey('bordercustomgradnet')) { $BorderCustomGradient = [int[]]$jsonData.bordercustomgradnet }
                    if ($jsonData.ContainsKey('gradientmode')) { $GradientMode = [string]$jsonData.gradientmode }
                    if ($jsonData.ContainsKey('compact')) { $Compact = [bool]$jsonData.compact }
                } catch {
                    Write-Warning "Failed to parse JSON file: $_"
                    return
                }
            } else {
                Write-Warning "JSON file not found: $JsonFile"
                return
            }
        }

        # Fallbacks
        if (!$Name) { $Name = 'UHW' }
        if (!$Version) { $Version = '1.0.0' }

        $selectedSections = $null
        if ($HelpSection -and $HelpSection.Count -gt 0) {
            $selectedSections = [System.Collections.Generic.HashSet[string]]::new(
                [System.StringComparer]::OrdinalIgnoreCase
            )
            foreach ($section in $HelpSection) { [void]$selectedSections.Add($section) }
        }

        # Sanitize CommandInfo to prevent strict-mode exceptions on missing properties
        if ($null -eq $CommandInfo) {
            $CommandInfo = [ordered]@{
                cmdlet      = $null
                synopsis    = $null
                description = $null
                source      = $null
            }
        } elseif ($CommandInfo -is [hashtable]) {
            $safeCommandInfo = [ordered]@{
                cmdlet      = $(if ($CommandInfo.ContainsKey('cmdlet')) { $CommandInfo['cmdlet'] } else { $null })
                synopsis    = $(if ($CommandInfo.ContainsKey('synopsis')) { $CommandInfo['synopsis'] } else { $null })
                description = $(if ($CommandInfo.ContainsKey('description')) { $CommandInfo['description'] } else { $null })
                source      = $(if ($CommandInfo.ContainsKey('source')) { $CommandInfo['source'] } else { $null })
            }
            $CommandInfo = $safeCommandInfo
        } else {
            $safeCommandInfo = [ordered]@{
                cmdlet      = $(try { $CommandInfo.cmdlet } catch { $null })
                synopsis    = $(try { $CommandInfo.synopsis } catch { $null })
                description = $(try { $CommandInfo.description } catch { $null })
                source      = $(try { $CommandInfo.source } catch { $null })
            }
            $CommandInfo = $safeCommandInfo
        }

        # -Compact takes precedence over -LineSpacing
        if ($Compact) { $LineSpacing = 0 }

        $indentString  = " " * $Indent
        $blankLine     = "`n" * $LineSpacing  # blank lines between param rows

        # ── Resolve Width ─────────────────────────────────────────────────────
        $resolvedWidth = 80
        $consoleWidth = 80
        try {
            $consoleWidth = [Console]::WindowWidth
        } catch {}

        if ($null -eq $Width -or $Width -eq 'full') {
            $resolvedWidth = $consoleWidth
        } elseif ($Width -eq 'man') {
            $resolvedWidth = [Math]::Min(80, $consoleWidth)
        } else {
            if ($Width -match '^\d+$') {
                $resolvedWidth = [int]$Width
            } else {
                $resolvedWidth = $consoleWidth
            }
        }

        # Safeguard: Minimum width constraint
        $minWidth = 45
        if ($resolvedWidth -lt $minWidth) {
            $errMsg = "[UHWriter] Console width ($resolvedWidth) is below the minimum required width ($minWidth)."
            if ($OutMode -eq 'String') {
                return @($errMsg)
            } else {
                [System.Console]::WriteLine($errMsg)
                return
            }
        }

        # Adjust content width based on whether we wrap inside an outer border
        $contentWidth = if ($OuterBorder) { $resolvedWidth - 4 } else { $resolvedWidth }
        if ($contentWidth -lt 20) { $contentWidth = 20 }

        # ── Portable .NET rendering backend ──────────────────────────────────
        $useDotNetRenderer = $Renderer -ne 'PowerShell' -and -not $env:UHWRITER_LEGACY_RENDERER
        if ($useDotNetRenderer) {
            $coreAvailable = Initialize-UHWriterCore
            if (-not $coreAvailable -and $Renderer -eq 'DotNet') {
                throw 'The UHWriter .NET rendering core could not be loaded. Run scripts/build/Build-DotNet.ps1 or use -Renderer PowerShell.'
            }
            if ($coreAvailable) {
                # Re-resolve after JSON/global configuration has been applied.
                $portableTheme = if ($Theme -is [hashtable]) { $Theme } else { Get-UHTheme -Name ([string]$Theme) }
                $portableParameters = [System.Collections.Generic.List[object]]::new()
                foreach ($item in @($ParamTable)) { if ($null -ne $item) { $portableParameters.Add($item) } }
                $portableSubcommands = [System.Collections.Generic.List[object]]::new()
                foreach ($item in @($Subcommands)) { if ($null -ne $item) { $portableSubcommands.Add($item) } }
                $portableExamples = [System.Collections.Generic.List[string]]::new()
                foreach ($item in @($Examples)) { if ($null -ne $item) { $portableExamples.Add([string]$item) } }
                $portableCustomGradient = [System.Collections.Generic.List[int]]::new()
                foreach ($item in @($CustomGradient)) { if ($null -ne $item) { $portableCustomGradient.Add([int]$item) } }
                $portableGradientTargets = [System.Collections.Generic.List[string]]::new()
                foreach ($item in @($GradientTarget)) { if ($null -ne $item) { $portableGradientTargets.Add([string]$item) } }
                $portableBorderGradient = [System.Collections.Generic.List[int]]::new()
                foreach ($item in @($BorderCustomGradient)) { if ($null -ne $item) { $portableBorderGradient.Add([int]$item) } }
                $portableHelpSections = [System.Collections.Generic.List[string]]::new()
                foreach ($item in @($HelpSection)) { if ($null -ne $item) { $portableHelpSections.Add([string]$item) } }
                $portableSectionLabels = [System.Collections.Generic.Dictionary[string, string]]::new(
                    [System.StringComparer]::OrdinalIgnoreCase
                )
                foreach ($item in $SectionLabel.GetEnumerator()) {
                    if (-not [string]::IsNullOrWhiteSpace([string]$item.Value)) {
                        $portableSectionLabels[[string]$item.Key] = [string]$item.Value
                    }
                }
                $portableDocument = [ordered]@{
                    name        = $Name
                    version     = $Version
                    sourceType  = $SourceType
                    command     = $CommandInfo
                    parameters  = $portableParameters
                    subcommands = $portableSubcommands
                    examples    = $portableExamples
                    options     = [ordered]@{
                        width                = $resolvedWidth
                        indent               = $Indent
                        padding              = $Padding
                        lineSpacing          = $LineSpacing
                        color                = -not ($env:NO_COLOR -or $env:UHWRITER_NO_COLOR)
                        outerBorder          = [bool]$OuterBorder
                        outerBorderStyle     = $OuterBorderStyle
                        layout               = $Layout
                        customLogo           = $CustomLogo
                        gradient             = [bool]$Gradient
                        customGradient       = $portableCustomGradient
                        gradientTarget       = $portableGradientTargets
                        gradientMode         = $GradientMode
                        borderGradient       = [bool]$BorderGradient
                        borderCustomGradient = $portableBorderGradient
                        helpParam            = $HelpParam
                        helpSection          = $portableHelpSections
                        sectionLabels        = $portableSectionLabels
                        themeName            = if ($Theme -is [string]) { $Theme } else { 'uhwriter' }
                        theme                = $portableTheme
                    }
                }
                $portableJson = $portableDocument | ConvertTo-Json -Depth 20 -Compress
                $finalString = [Uhwriter.HelpRenderer]::RenderJson($portableJson)

                $doPager = $false
                if ($OutMode -eq 'Alt') {
                    $doPager = $true
                } elseif ($OutMode -eq 'Auto') {
                    $consoleHeight = 24
                    try { $consoleHeight = [Console]::WindowHeight } catch {}
                    $doPager = ($finalString -split '\r?\n').Count -gt ($consoleHeight - 2)
                }

                if ($OutMode -eq 'String') {
                    return $finalString -split '\r?\n'
                } elseif ($doPager) {
                    Invoke-UHPager -Content $finalString -Title $Name -Theme $portableTheme -KeepOutput:$KeepOutput
                } else {
                    [System.Console]::Write($finalString)
                }
                return
            }
        }

        # ── Define local formatting & wrapping helpers ────────────────────────
        $HighlightDescription = {
            param([string]$Text, $Theme)
            if ([string]::IsNullOrEmpty($Text)) { return "" }
            $descParts = $Text -split "'"
            $resultParts = [System.Collections.Generic.List[string]]::new()
            for ($i = 0; $i -lt $descParts.Count; $i++) {
                if ($i % 2 -eq 1) {
                    $quotedText = "'$($descParts[$i])'"
                    $colorValue = if ($Theme.ContainsKey('AccentColor')) { $Theme['AccentColor'] } else { 'cyan' }
                    $styledQuoted = New-AsciiColor -String $quotedText -Color $colorValue -Format @('bold', 'italic')
                    $resultParts.Add($styledQuoted)
                } else {
                    if ($descParts[$i].Length -gt 0) {
                        $styledOutside = Format-ThemeText -String $descParts[$i] -Theme $Theme -Element 'ParamDesc'
                        $resultParts.Add($styledOutside)
                    }
                }
            }
            return $resultParts -join ""
        }

        $WrapPlainParagraph = {
            param([string]$String, [int]$Position, [int]$Indent)
            if ([string]::IsNullOrEmpty($String)) { return @() }
            $words = $String.Split(' ')
            $lines = [System.Collections.Generic.List[string]]::new()
            $currentLine = [System.Text.StringBuilder]::new()

            foreach ($word in $words) {
                $wordVisualLen = Get-ClapVisibleLength -Text $word
                if ($currentLine.Length + $wordVisualLen -gt $Position) {
                    if ($currentLine.Length -gt 0) {
                        [void]$lines.Add((" " * $Indent) + $currentLine.ToString().TrimEnd())
                        [void]$currentLine.Clear()
                    }
                }
                [void]$currentLine.Append($word).Append(' ')
            }
            if ($currentLine.Length -gt 0) {
                [void]$lines.Add((" " * $Indent) + $currentLine.ToString().TrimEnd())
            }
            return $lines.ToArray()
        }

        # ── Setup Dynamic Resize Callback ─────────────────────────────────────
        $outerBoundParams = [hashtable]::new($PSBoundParameters)
        $onResizeCallback = {
            param([int]$newWidth, [int]$newHeight)
            $params = $outerBoundParams.Clone()
            $params['OutMode'] = 'String'
            # Width will be re-resolved to the new console dimensions internally
            New-UHWriter @params
        }

        # Redirect Console output to capture the entire formatted document
        $originalOut = [System.Console]::Out
        $stringWriter = [System.IO.StringWriter]::new()
        [System.Console]::SetOut($stringWriter)

        try {
            $gradientSteps = if ($CustomGradient -and $CustomGradient.Count -ge 2) {
                $CustomGradient
            } elseif ($themeObj.ContainsKey('GradientSteps')) {
                [int[]]$themeObj['GradientSteps']
            } else {
                [int[]]@(51, 201)
            }
            $gradientEnabledFor = {
                param([string]$Target)
                return ($Gradient -or ($CustomGradient -and $CustomGradient.Count -ge 2)) -and
                    ($GradientTarget -contains 'All' -or $GradientTarget -contains $Target)
            }
            $formatGradientText = {
                param([string]$Text, [string]$Target, [string]$Element)
                if (& $gradientEnabledFor $Target) {
                    return New-AsciiGradient -Type 'fg' -Steps $gradientSteps -String $Text
                }
                return Format-ThemeText -String $Text -Theme $themeObj -Element $Element
            }
            $getSectionLabel = {
                param([string]$Canonical)
                foreach ($item in $SectionLabel.GetEnumerator()) {
                    if ([string]$item.Key -ieq $Canonical -and -not [string]::IsNullOrWhiteSpace([string]$item.Value)) {
                        return ([string]$item.Value).ToUpperInvariant()
                    }
                }
                return $Canonical.ToUpperInvariant()
            }

            # Output Logo
            $gradientTitle = & $gradientEnabledFor 'Title'
            Write-UHAsciiLogo -Name $Name -Version $Version -Theme $themeObj -Layout $Layout -CustomLogo $CustomLogo -Gradient:$gradientTitle -CustomGradient $CustomGradient -GradientMode $GradientMode

            # Sections config
            $sectionChar = if ($themeObj.ContainsKey('SectionChar')) { $themeObj['SectionChar'] } else { '◉' }
            $headerChar = if ($themeObj.ContainsKey('HeaderChar')) { $themeObj['HeaderChar'] } else { '▶' }

            $styledSecChar = if ($sectionChar) { & $formatGradientText "$sectionChar " 'Section' 'SectionChar' } else { "" }
            $styledHeadChar = if ($headerChar) { & $formatGradientText " $headerChar " 'Header' 'Accent' } else { " " }

            # Display Version / Metadata Header
            # Format: <SourceType> <Name> ▶ CMDLET <Cmdlet> ▶ VERSION <Version>
            # For router, displays CLI <Name> ▶ FUNCTION <Cmdlet> ▶ VERSION <Version>
            # Pad labels with 1 space on left/right for tag appearance.
            $typeStr = if ($SourceType -eq 'router') { 'CLI' } else { $SourceType.ToUpper() }
            $cmdletLabel = if ($SourceType -eq 'router') { 'FUNCTION' } else { 'CMDLET' }

            $headerParts = @()
            $headerParts += "$(& $formatGradientText " $typeStr " 'Header' 'Accent') $(& $formatGradientText " $Name " 'Header' 'Header')"
            if ($CommandInfo.cmdlet) {
                $headerParts += "$(& $formatGradientText " $cmdletLabel " 'Header' 'Accent') $(& $formatGradientText " $($CommandInfo.cmdlet) " 'Header' 'Header')"
            }
            $headerParts += "$(& $formatGradientText ' VERSION ' 'Header' 'Accent') $(& $formatGradientText " v$Version " 'Header' 'Version')"

            [console]::WriteLine($indentString + " " + ($headerParts -join $styledHeadChar) + " ")
            [console]::WriteLine()

            # 1. SYNTAX Section
            if ($CommandInfo.synopsis -and ($null -eq $selectedSections -or $selectedSections.Contains('Syntax'))) {
                $syntaxTitle = & $formatGradientText (& $getSectionLabel 'Syntax') 'Section' 'Accent'
                [console]::WriteLine("${indentString}${styledSecChar}${syntaxTitle}")
                $syntaxWrapCol = $contentWidth - ($Indent + 2) - 4
                if ($syntaxWrapCol -lt 20) { $syntaxWrapCol = 20 }
                $wrappedSyntaxLines = & $WrapPlainParagraph ($CommandInfo.synopsis) $syntaxWrapCol ($Indent + 2)
                foreach ($line in $wrappedSyntaxLines) {
                    $indentPart = $line.Substring(0, $Indent + 2)
                    $textPart = $line.Substring($Indent + 2)
                    $styledText = & $formatGradientText $textPart 'Syntax' 'Syntax'
                    [console]::WriteLine($indentPart + $styledText)
                }
                [console]::WriteLine()
            }

            # 2. DESCRIPTION Section
            if ($CommandInfo.description -and ($null -eq $selectedSections -or $selectedSections.Contains('Description'))) {
                $descTitle = & $formatGradientText (& $getSectionLabel 'Description') 'Section' 'Accent'
                [console]::WriteLine("${indentString}${styledSecChar}${descTitle}")
                $descWrapCol = $contentWidth - ($Indent + 2) - 4
                if ($descWrapCol -lt 20) { $descWrapCol = 20 }
                $wrappedDescLines = & $WrapPlainParagraph ($CommandInfo.description) $descWrapCol ($Indent + 2)
                foreach ($line in $wrappedDescLines) {
                    $indentPart = $line.Substring(0, $Indent + 2)
                    $textPart = $line.Substring($Indent + 2)
                    $styledText = if (& $gradientEnabledFor 'Description') { & $formatGradientText $textPart 'Description' 'ParamDesc' } else { & $HighlightDescription $textPart $themeObj }
                    [console]::WriteLine($indentPart + $styledText)
                }
                [console]::WriteLine()
            }

            # 3. SUBCOMMANDS Section (For Router functions)
            if ($Subcommands -and $Subcommands.Count -gt 0 -and ($null -eq $selectedSections -or $selectedSections.Contains('Subcommands'))) {
                $subTitle = & $formatGradientText (& $getSectionLabel 'Subcommands') 'Section' 'Accent'
                [console]::WriteLine("${indentString}${styledSecChar}${subTitle}")

                $maxSubLength = 0
                foreach ($sub in $Subcommands) {
                    if ($sub.name.Length -gt $maxSubLength) {
                        $maxSubLength = $sub.name.Length
                    }
                }

                foreach ($sub in $Subcommands) {
                    $subNameFormatted = $sub.name.PadRight($maxSubLength + $Padding)
                    $styledSubName = & $formatGradientText $subNameFormatted 'ParameterName' 'ParamName'
                    $styledSubSyntax = & $formatGradientText $sub.syntax 'ParameterType' 'ParamType'
                    $styledSubDesc = & $formatGradientText $sub.description 'ParameterDescription' 'ParamDesc'

                    [console]::WriteLine("${indentString}   ${styledSubName}${styledSubSyntax}")
                    $descIndent = $indentString + (" " * ($maxSubLength + $Padding + 4))
                    $subDescWrapCol = $contentWidth - $descIndent.Length - 4
                    if ($subDescWrapCol -lt 20) { $subDescWrapCol = 20 }
                    [console]::WriteLine($(New-Paragraph -position $subDescWrapCol -indent $descIndent.Length -string $styledSubDesc))
                    [console]::WriteLine()
                }
            }

            # 4. PARAMETERS Section
            if ($ParamTable -and $ParamTable.Count -gt 0 -and ($null -eq $selectedSections -or $selectedSections.Contains('Parameters'))) {
                # ── -HelpParam filter: restrict to matching entries ────────────
                $activeParamTable = $ParamTable
                if (-not [string]::IsNullOrWhiteSpace($HelpParam)) {
                    $needle = $HelpParam.ToLower()
                    $filtered = @($ParamTable | Where-Object {
                        $filterAliases = if ($_ -is [System.Collections.IDictionary] -and $_.Contains('aliases')) {
                            @($_['aliases'])
                        } elseif ($null -ne $_.PSObject.Properties['aliases']) {
                            @($_.PSObject.Properties['aliases'].Value)
                        } else { @() }
                        $filterParam = if ($_ -is [System.Collections.IDictionary] -and $_.Contains('param')) {
                            [string]$_['param']
                        } elseif ($null -ne $_.PSObject.Properties['param']) {
                            [string]$_.PSObject.Properties['param'].Value
                        } else { '' }
                        ($_.name  -and $_.name.ToLower()  -like "*${needle}*") -or
                        ($filterParam -and $filterParam.ToLower() -like "*${needle}*") -or
                        @($filterAliases | Where-Object { $_ -and $_.ToString().ToLower() -like "*${needle}*" }).Count -gt 0
                    })
                    if ($filtered.Count -gt 0) {
                        $activeParamTable = $filtered
                    } else {
                        # No match — emit a themed warning row instead of silently showing nothing
                        $noMatchMsg = Format-ThemeText -String "  No parameter matching '$HelpParam' found." -Theme $themeObj -Element 'ParamDesc'
                        [console]::WriteLine($noMatchMsg)
                        $activeParamTable = @()
                    }
                }

                $paramTitle = & $formatGradientText (& $getSectionLabel 'Parameters') 'Section' 'Accent'
                [console]::WriteLine("${indentString}${styledSecChar}${paramTitle}")

                $maxParamLength = 0
                $maxTypeLength = 0

                # Resolve a single display label from explicit cross-language aliases, the
                # legacy pipe-delimited param field, and the canonical parameter name.
                $displayLabels = @{}

                foreach ($paramInfo in $activeParamTable) {
                    if (-not ($paramInfo.name -and $paramInfo.type -and $paramInfo.description)) {
                        continue
                    }
                    $labelParts = [System.Collections.Generic.List[string]]::new()
                    $configuredAliases = if ($paramInfo -is [System.Collections.IDictionary] -and $paramInfo.Contains('aliases')) {
                        @($paramInfo['aliases'])
                    } elseif ($null -ne $paramInfo.PSObject.Properties['aliases']) {
                        @($paramInfo.PSObject.Properties['aliases'].Value)
                    } else { @() }
                    foreach ($aliasName in $configuredAliases) {
                        if (-not [string]::IsNullOrWhiteSpace([string]$aliasName) -and $aliasName -notin $labelParts) {
                            $labelParts.Add([string]$aliasName)
                        }
                    }
                    $legacyParam = if ($paramInfo -is [System.Collections.IDictionary] -and $paramInfo.Contains('param')) {
                        [string]$paramInfo['param']
                    } elseif ($null -ne $paramInfo.PSObject.Properties['param']) {
                        [string]$paramInfo.PSObject.Properties['param'].Value
                    } else { '' }
                    foreach ($legacyName in @($legacyParam -split '\|')) {
                        if (-not [string]::IsNullOrWhiteSpace($legacyName) -and
                            $legacyName -ine [string]$paramInfo.name -and $legacyName -notin $labelParts) {
                            $labelParts.Add($legacyName)
                        }
                    }
                    $labelParts.Add([string]$paramInfo.name)
                    $displayLabel = $labelParts -join '|'
                    $displayLabels[[string]$paramInfo.name] = $displayLabel
                    $paramField = "-$displayLabel"
                    if ($paramField.Length -gt $maxParamLength) {
                        $maxParamLength = $paramField.Length
                    }
                    $typeField = "[$($paramInfo.type)]"
                    if ($typeField.Length -gt $maxTypeLength) {
                        $maxTypeLength = $typeField.Length
                    }
                }

                foreach ($paramInfo in $activeParamTable) {
                    if (-not ($paramInfo.name -and $paramInfo.type -and $paramInfo.description)) {
                        continue
                    }

                    $paramType = "[$($paramInfo.type)]"
                    $displayLabel = $displayLabels[[string]$paramInfo.name]
                    $paramDesc = $paramInfo.description
                    $required = $paramInfo.required -or $false
                    $inline = [bool]$paramInfo.inline

                    $reqText = if ($required) { " " + (Format-ThemeText -String "(Req)" -Theme $themeObj -Element 'ParamReq') } else { "" }

                    if ($displayLabel -like '*|*') {
                        $labelParts = $displayLabel -split '\|'
                        $styledLabel = [System.Text.StringBuilder]::new()
                        for ($labelIndex = 0; $labelIndex -lt $labelParts.Count; $labelIndex++) {
                            if ($labelIndex -eq 0) {
                                [void]$styledLabel.Append((Format-ThemeText -String "-$($labelParts[$labelIndex])" -Theme $themeObj -Element 'ParamName'))
                            } else {
                                [void]$styledLabel.Append((Format-ThemeText -String '|' -Theme $themeObj -Element 'Border'))
                                [void]$styledLabel.Append((Format-ThemeText -String $labelParts[$labelIndex] -Theme $themeObj -Element 'ParamName'))
                            }
                        }
                        $visibleLabelLength = $displayLabel.Length + 1
                        [void]$styledLabel.Append(' ' * [Math]::Max(0, ($maxParamLength + $Padding) - $visibleLabelLength))
                        $styledAlias = $styledLabel.ToString()
                    } else {
                        $paramAlias = "-$displayLabel"
                        $formattedAlias = $paramAlias.PadRight($maxParamLength + $Padding)
                        $styledAlias = & $formatGradientText $formattedAlias 'ParameterName' 'ParamName'
                    }

                    $formattedType = $paramType.PadRight($maxTypeLength + $Padding)
                    $styledType = & $formatGradientText $formattedType 'ParameterType' 'ParamType'
                    [console]::Write("${indentString}   ${styledAlias}${styledType}${reqText}")

                    # Layout description with width constraint
                    $descIndent = $Indent + 6
                    $wrapCol = $contentWidth - $descIndent - 2
                    if ($wrapCol -lt 20) { $wrapCol = 20 }

                    $reqLen = if ($required) { 6 } else { 0 }
                    $prefixPlainLen = $Indent + 3 + ($maxParamLength + $Padding) + ($maxTypeLength + $Padding) + $reqLen
                    $remSpace = $contentWidth - $prefixPlainLen - 2

                    $isInline = $false
                    if ($inline -and $remSpace -ge 20 -and $paramDesc.Length -le $remSpace) {
                        $isInline = $true
                    }

                    if ($isInline) {
                        $styledDescText = if (& $gradientEnabledFor 'ParameterDescription') { & $formatGradientText $paramDesc 'ParameterDescription' 'ParamDesc' } else { & $HighlightDescription $paramDesc $themeObj }
                        [console]::WriteLine("  " + $styledDescText)
                    } else {
                        [console]::WriteLine()
                        $wrappedLines = & $WrapPlainParagraph $paramDesc $wrapCol $descIndent
                        foreach ($line in $wrappedLines) {
                            $indentPart = $line.Substring(0, $descIndent)
                            $textPart = $line.Substring($descIndent)
                            $styledText = if (& $gradientEnabledFor 'ParameterDescription') { & $formatGradientText $textPart 'ParameterDescription' 'ParamDesc' } else { & $HighlightDescription $textPart $themeObj }
                            [console]::WriteLine($indentPart + $styledText)
                        }
                    }

                    for ($ls = 0; $ls -lt $LineSpacing; $ls++) { [console]::WriteLine() }
                }
            }

            # 5. EXAMPLES Section
            if ($Examples -and $Examples.Count -gt 0 -and ($null -eq $selectedSections -or $selectedSections.Contains('Examples'))) {
                $exTitle = & $formatGradientText (& $getSectionLabel 'Examples') 'Section' 'Accent'
                [console]::WriteLine("${indentString}${styledSecChar}${exTitle}")

                $getHighlightedExample = {
                    param(
                        [string]$ExText,
                        $Theme
                    )
                    [string[]]$cmdletFormat = if ($Theme.AccentFormat) { @($Theme.AccentFormat -split ',') | Where-Object { $_ -and $_ -ne 'none' } } else { @() }
                    $cParams = @{ String = "X"; Color = $Theme.AccentColor }
                    $cFormatList = [System.Collections.Generic.List[string]]::new()
                    foreach ($f in $cmdletFormat) { [void]$cFormatList.Add($f) }
                    if (-not $cFormatList.Contains('bold')) { [void]$cFormatList.Add('bold') }
                    $cParams['Format'] = $cFormatList.ToArray()
                    $cmdletColor = New-AsciiColor @cParams
                    $cmdletSeq = if ($cmdletColor.EndsWith("[0m")) { $cmdletColor.Substring(0, $cmdletColor.Length - 5) } else { "" }

                    [string[]]$pFormat = if ($Theme.ParamNameFormat) { @($Theme.ParamNameFormat -split ',') | Where-Object { $_ -and $_ -ne 'none' } } else { @() }
                    $pParams = @{ String = "X"; Color = $Theme.ParamNameFg }
                    if ($pFormat -and $pFormat.Count -gt 0) { $pParams['Format'] = $pFormat }
                    $pEsc = New-AsciiColor @pParams
                    $paramSeq = if ($pEsc.EndsWith("[0m")) { $pEsc.Substring(0, $pEsc.Length - 5) } else { "" }

                    [string[]]$sFormat = if ($Theme.ParamTypeFormat) { @($Theme.ParamTypeFormat -split ',') | Where-Object { $_ -and $_ -ne 'none' } } else { @() }
                    $sParams = @{ String = "X"; Color = $Theme.ParamTypeFg }
                    if ($sFormat -and $sFormat.Count -gt 0) { $sParams['Format'] = $sFormat }
                    $sEsc = New-AsciiColor @sParams
                    $stringSeq = if ($sEsc.EndsWith("[0m")) { $sEsc.Substring(0, $sEsc.Length - 5) } else { "" }

                    $reset = [char]27 + "[0m"

                    $pattern = '(?<string>\''[^\'']*\''|"[^"]*")|(?<param>-\w+(\|\w+)?)|(?<cmdlet>\b[A-Za-z]+-[A-Za-z]+\w*\b)|(?<word>\S+)|(?<space>\s+)'
                    $matches = [System.Text.RegularExpressions.Regex]::Matches($ExText, $pattern)
                    $sb = [System.Text.StringBuilder]::new()
                    $seenFirstWord = $false

                    foreach ($m in $matches) {
                        if ($m.Groups['string'].Success) {
                            [void]$sb.Append("${stringSeq}$($m.Value)${reset}")
                        } elseif ($m.Groups['param'].Success) {
                            if ($m.Value -like '*|*') {
                                $parts = $m.Value -split '\|', 2
                                $pipeEsc = New-AsciiColor -String "|" -Color $Theme.BorderColor
                                [void]$sb.Append("${paramSeq}$($parts[0])${reset}${pipeEsc}${paramSeq}$($parts[1])${reset}")
                            } else {
                                [void]$sb.Append("${paramSeq}$($m.Value)${reset}")
                            }
                        } elseif ($m.Groups['cmdlet'].Success) {
                            $seenFirstWord = $true
                            [void]$sb.Append("${cmdletSeq}$($m.Value)${reset}")
                        } elseif ($m.Groups['word'].Success) {
                            if (-not $seenFirstWord) {
                                $seenFirstWord = $true
                                [void]$sb.Append("${cmdletSeq}$($m.Value)${reset}")
                            } else {
                                [void]$sb.Append($m.Value)
                            }
                        } else {
                            [void]$sb.Append($m.Value)
                        }
                    }
                    return $sb.ToString()
                }

                foreach ($example in $Examples) {
                    $cleanedExample = $example.Replace("//", "/")
                    $styledEx = if (& $gradientEnabledFor 'Example') { & $formatGradientText $cleanedExample 'Example' 'Example' } else { & $getHighlightedExample $cleanedExample $themeObj }
                    [console]::WriteLine("${indentString}    ${styledEx}`n")
                }
            }

            # 8. Docs / Source Link
            if ($CommandInfo.source -and ($null -eq $selectedSections -or $selectedSections.Contains('Docs'))) {
                $docsTitle = & $formatGradientText "★ $(& $getSectionLabel 'Docs'):" 'Docs' 'Accent'
                $docsLink = & $formatGradientText ([string]$CommandInfo.source) 'Docs' 'Docs'
                [console]::WriteLine("${indentString} ${docsTitle} ${docsLink} for more info")
                [console]::WriteLine()
            }
        } finally {
            [System.Console]::SetOut($originalOut)
        }

        $capturedText = $stringWriter.ToString()
        $finalString = $capturedText

        # Apply Outer Border wrapping if requested
        if ($OuterBorder) {
            $lines = $capturedText -split '\r?\n'
            if ($lines.Count -gt 0 -and [string]::IsNullOrEmpty($lines[-1])) {
                $lines = $lines[0..($lines.Count - 2)]
            }

            $maxW = $resolvedWidth - 4
            if ($maxW -lt 20) { $maxW = 20 }

            # Resolve border characters based on OuterBorderStyle
            switch ($OuterBorderStyle) {
                'Square'  {
                    $borderLeft   = '│'
                    $borderRight  = '│'
                    $topBorder    = '┌' + ('─' * ($maxW + 2)) + '┐'
                    $bottomBorder = '└' + ('─' * ($maxW + 2)) + '┘'
                }
                'Double'  {
                    $borderLeft   = '║'
                    $borderRight  = '║'
                    $topBorder    = '╔' + ('═' * ($maxW + 2)) + '╗'
                    $bottomBorder = '╚' + ('═' * ($maxW + 2)) + '╝'
                }
                'Block'   {
                    $borderLeft   = '█'
                    $borderRight  = '█'
                    $topBorder    = '█' + ('█' * ($maxW + 2)) + '█'
                    $bottomBorder = '▓' + ('▓' * ($maxW + 2)) + '▓'
                }
                'Simple'  {
                    $borderLeft   = '|'
                    $borderRight  = '|'
                    $topBorder    = '+' + ('-' * ($maxW + 2)) + '+'
                    $bottomBorder = '+' + ('-' * ($maxW + 2)) + '+'
                }
                default   {
                    # Rounded (default)
                    $borderLeft   = '│'
                    $borderRight  = '│'
                    $topBorder    = '╭' + ('─' * ($maxW + 2)) + '╮'
                    $bottomBorder = '╰' + ('─' * ($maxW + 2)) + '╯'
                }
            }

            # Color borders
            $useBorderGrad = $BorderGradient -or ($null -ne $BorderCustomGradient)
            if ($useBorderGrad) {
                $bSteps = if ($null -ne $BorderCustomGradient) {
                    $BorderCustomGradient
                } elseif ($themeObj.ContainsKey('GradientSteps')) {
                    $themeObj['GradientSteps']
                } else {
                    [int[]]@(51, 93, 129, 201)
                }
                $styledTop    = New-AsciiGradient -Type 'fg' -Steps $bSteps -String $topBorder
                $styledBottom = New-AsciiGradient -Type 'fg' -Steps $bSteps -String $bottomBorder
                $styledLeft   = New-AsciiGradient -Type 'fg' -Steps $bSteps -String $borderLeft
                $lastStep     = $bSteps[-1]
                $styledRight  = New-AsciiGradient -Type 'fg' -Steps @($lastStep, $lastStep) -String $borderRight
            } else {
                $styledTop    = Format-ThemeText -String $topBorder    -Theme $themeObj -Element 'Border'
                $styledBottom = Format-ThemeText -String $bottomBorder -Theme $themeObj -Element 'Border'
                $styledLeft   = Format-ThemeText -String $borderLeft   -Theme $themeObj -Element 'Border'
                $styledRight  = Format-ThemeText -String $borderRight  -Theme $themeObj -Element 'Border'
            }

            # Build bordered string using high-performance StringBuilder
            $sbBordered = [System.Text.StringBuilder]::new()
            [void]$sbBordered.AppendLine($styledTop)
            foreach ($line in $lines) {
                $padded = Pad-AnsiString -Text $line -Width $maxW -Align 'Left' -PadChar ' '
                [void]$sbBordered.AppendLine("${styledLeft} ${padded} ${styledRight}")
            }
            [void]$sbBordered.AppendLine($styledBottom)
            $finalString = $sbBordered.ToString()
        }

        # ── Output Mode Dispatch ──────────────────────────────────────────────
        $doPager = $false
        if ($OutMode -eq 'Alt') {
            $doPager = $true
        } elseif ($OutMode -eq 'Auto') {
            $consoleHeight = 24
            try { $consoleHeight = [Console]::WindowHeight } catch {}
            $lineCount = ($finalString -split '\r?\n').Count
            if ($lineCount -gt ($consoleHeight - 2)) {
                $doPager = $true
            }
        }

        if ($OutMode -eq 'String') {
            return $finalString -split '\r?\n'
        } elseif ($doPager) {
            Invoke-UHPager -Content $finalString -Title $Name -Theme $themeObj -OnResize $onResizeCallback -KeepOutput:$KeepOutput
        } else {
            [System.Console]::Write($finalString)
        }
    }
}
