function New-UHRouter {
    <#
    .SYNOPSIS
      Scaffolds and dispatches a standardized subcommand router for PowerShell CLI modules.
    .DESCRIPTION
      New-UHRouter provides a zero-boilerplate router framework. Pass a route map dictionary
      (subcommand name → scriptblock or function name), the raw argument array, and optional
      UHWriter metadata for auto-registration of argument completers.

      Features:
        • Tab-completion auto-registration via Register-ArgumentCompleter
        • Unknown subcommand detection with "Did you mean?" fuzzy matching
        • Automatic '--help' / '-h' flag passthrough to the routed function
        • Optional 'default' route (called when no subcommand is given)
        • Zero external dependencies — pure .NET + PowerShell

    .PARAMETER Routes
      A dictionary, ordered dictionary, or configuration object mapping subcommand names to either:
        - A [scriptblock] to invoke directly
        - A [string] naming a function that exists in scope
      A special key 'default' is called when no subcommand is matched.

    .PARAMETER ArgumentList
      The raw argument array to dispatch. Typically $args or $PSBoundParameters values.
      The first element is the subcommand key.

    .PARAMETER ModuleName
      The name of the module/router. Used in error/help output. Default: 'UHRouter'.

    .PARAMETER RegisterCompleter
      When specified, auto-registers a tab-completion ArgumentCompleter for the ModuleName
      so that subcommand keys are offered as completions.

    .PARAMETER Metadata
      Optional UHWriter metadata hashtable (from Export-UHWriterMetadata or New-UHWriter's
      input format). If provided, the route map is validated against metadata and discrepancies
      are reported as warnings.

    .EXAMPLE
      # Basic router in a CLI entrypoint function
      function Invoke-MyCLI {
          param([Parameter(ValueFromRemainingArguments)][string[]]$args)
          $routes = @{
              'build'   = { param($rest) Invoke-Build @rest }
              'test'    = 'Invoke-Tests'
              'version' = { Write-Host "v1.0.0" }
              'default' = { Write-Host "Run: mycli <build|test|version>" }
          }
          New-UHRouter -Routes $routes -ArgumentList $args -ModuleName 'mycli' -RegisterCompleter
      }

    .EXAMPLE
      # With UHWriter metadata auto-validation
      $meta = Export-UHWriterMetadata -Path './Public/Invoke-MyCLI.ps1'
      New-UHRouter -Routes $routes -ArgumentList $args -ModuleName 'mycli' -Metadata $meta

    .NOTES
      Alias: uhroute
    #>
    [CmdletBinding()]
    [Alias('uhroute')]
    param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Subcommand route map.")]
        [object]$Routes,

        [Parameter(Mandatory = $false, Position = 1, ValueFromRemainingArguments = $false, HelpMessage = "Raw argument array.")]
        [string[]]$ArgumentList = @(),

        [Parameter(Mandatory = $false, HelpMessage = "Module/CLI name for messaging.")]
        [string]$ModuleName = 'UHRouter',

        [Parameter(Mandatory = $false, HelpMessage = "Auto-register tab-completion for subcommand keys.")]
        [switch]$RegisterCompleter,

        [Parameter(Mandatory = $false, HelpMessage = "UHWriter metadata for validation.")]
        [object]$Metadata,

        [Parameter(Mandatory = $false, HelpMessage = "Theme name or custom theme object.")]
        [object]$Theme = 'uhwriter',

        [Parameter(HelpMessage = "Display Help for New-UHRouter.")]
        [switch]$Help
    )

    # ── Help support ──────────────────────────────────────────────────────────
    if ($Help) {
        $uhrouter_ParamTable = @(
            @{
                name        = "Routes"
                param       = "r|Routes"
                type        = "Object"
                description = "Subcommand route map (dictionary/config object -> scriptblock/string)."
                required    = $true
                inline      = $false
            },
            @{
                name        = "ArgumentList"
                param       = "args|ArgumentList"
                type        = "String[]"
                description = "Raw argument array to dispatch."
                required    = $false
                inline      = $false
            },
            @{
                name        = "ModuleName"
                param       = "m|ModuleName"
                type        = "String"
                description = "Module/CLI name for messaging. Default: 'UHRouter'."
                required    = $false
                inline      = $false
            },
            @{
                name        = "RegisterCompleter"
                param       = "rc|RegisterCompleter"
                type        = "Switch"
                description = "Auto-register tab-completion for subcommand keys."
                required    = $false
                inline      = $true
            },
            @{
                name        = "Metadata"
                param       = "meta|Metadata"
                type        = "Object"
                description = "UHWriter metadata for route validation."
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
            }
        )
        $uhrouter_commandinfo = @{
            cmdlet      = "New-UHRouter"
            synopsis    = "New-UHRouter -Routes <Object> [-ArgumentList <String[]>] [-ModuleName <String>] [-RegisterCompleter] [-Metadata <Object>] [-Theme <Object>]"
            description = "Scaffolds and dispatches a standardized subcommand router for PowerShell CLI modules."
            source      = "https://gitlab.com/phellams/uhwriter"
        }
        $uhrouter_examples = @(
            "New-UHRouter -Routes \$routes -ArgumentList \$args -ModuleName 'mycli' -RegisterCompleter",
            "New-UHRouter -Routes \$routes -ArgumentList \$args -Theme 'steel-plate'"
        )
        New-UHWriter -Name 'UHWRITER' -CommandInfo $uhrouter_commandinfo -ParamTable $uhrouter_ParamTable -Padding 4 -Indent 2 -Theme $Theme -Version '1.0.0' -Examples $uhrouter_examples
        return
    }

    # ── Populate default routes for built-in cmdlets ─────────────────────────
    $defaultRoutes = @{
        'show-uhtheme'            = 'Show-UHTheme'
        'shldc'                   = 'Show-UHTheme'
        'theme'                   = 'Show-UHTheme'
        'themes'                  = 'Show-UHTheme'
        'new-uhwriter'            = 'New-UHWriter'
        'uhwriter'                = 'New-UHWriter'
        'write-uhasciilogo'       = 'Write-UHAsciiLogo'
        'logo'                    = 'Write-UHAsciiLogo'
        'export-uhwritermetadata' = 'Export-UHWriterMetadata'
        'uhextract'               = 'Export-UHWriterMetadata'
        'invoke-uhpager'          = 'Invoke-UHPager'
        'uhpager'                 = 'Invoke-UHPager'
        'new-uhrouter'            = 'New-UHRouter'
        'uhroute'                 = 'New-UHRouter'
        'get-terminalpalette'     = 'Get-TerminalPalette'
        'terpal'                  = 'Get-TerminalPalette'
        'new-asciitokengradient'  = 'New-AsciiTokenGradient'
    }

    # Normalize hashtables, ordered dictionaries, and objects loaded from JSON/config.
    # A private copy prevents built-in routes from being added to the caller's object.
    $routeMap = [System.Collections.Generic.Dictionary[string, object]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    if ($Routes -is [System.Collections.IDictionary]) {
        foreach ($key in $Routes.Keys) {
            $routeKey = [string]$key
            if ([string]::IsNullOrWhiteSpace($routeKey)) {
                throw [System.ArgumentException]::new('Route names cannot be empty.')
            }
            $routeMap[$routeKey] = $Routes[$key]
        }
    } elseif ($Routes -is [System.Management.Automation.PSCustomObject]) {
        foreach ($property in $Routes.PSObject.Properties) {
            $routeMap[$property.Name] = $property.Value
        }
    } elseif ($null -ne $Routes) {
        $actualType = $Routes.GetType().FullName
        throw [System.ArgumentException]::new(
            "Routes must be a dictionary or configuration object; received '$actualType'."
        )
    }
    $Routes = $routeMap

    foreach ($entry in $defaultRoutes.GetEnumerator()) {
        if (-not $Routes.ContainsKey($entry.Key)) {
            $Routes[$entry.Key] = $entry.Value
        }
    }

    # ── Auto-register tab completer ───────────────────────────────────────────
    if ($RegisterCompleter) {
        $routeKeys = @($Routes.Keys | Where-Object { $_ -ne 'default' } | Sort-Object)
        $scriptBlock = [scriptblock]::Create(
            'param($wordToComplete, $commandAst, $cursorPosition);' +
            '$keys = @(' + (($routeKeys | ForEach-Object { "'$_'" }) -join ',') + ');' +
            '$keys | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {' +
            '[System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_) }'
        )
        Register-ArgumentCompleter -Native -ScriptBlock $scriptBlock -CommandName $ModuleName -ErrorAction SilentlyContinue
    }

    # ── Validate routes against metadata (if provided) ────────────────────────
    if ($Metadata) {
        $metaSubcmds = @()
        if ($Metadata.subcommands) {
            $metaSubcmds = $Metadata.subcommands | ForEach-Object { $_.name }
        }
        foreach ($key in $Routes.Keys) {
            if ($key -eq 'default') { continue }
            if ($metaSubcmds -and $key -notin $metaSubcmds) {
                Write-Warning "[UHRouter] Route '$key' not found in metadata subcommands for '$ModuleName'."
            }
        }
    }

    # ── Resolve subcommand ────────────────────────────────────────────────────
    $subcommand = $null
    $restArgsList = [System.Collections.Generic.List[string]]::new()

    $i = 0
    while ($i -lt $ArgumentList.Count) {
        $arg = $ArgumentList[$i]
        if ($arg -ieq '-mode' -or $arg -ieq '-m') {
            if ($i + 1 -lt $ArgumentList.Count) {
                $subcommand = $ArgumentList[$i + 1]
                $i += 2
                continue
            }
        }
        if ($arg -ieq '-submod' -or $arg -ieq '-submode' -or $arg -ieq '-s') {
            if ($i + 1 -lt $ArgumentList.Count) {
                $submodVal = $ArgumentList[$i + 1]
                [void]$restArgsList.Add($submodVal)
                $i += 2
                continue
            }
        }
        # Regular positional arguments
        if ($null -eq $subcommand -and -not $arg.StartsWith('-')) {
            $subcommand = $arg
        } else {
            [void]$restArgsList.Add($arg)
        }
        $i++
    }
    $restArgs = $restArgsList.ToArray()

    $helpKeywords = @('help', '-help', '--help', '-h', 'h')

    # If subcommand is a help request (e.g. mycli help build)
    if ($subcommand -and $subcommand.ToLower() -in $helpKeywords) {
        if ($restArgs.Count -gt 0) {
            $potentialSub = $restArgs[0]
            $matchedPotential = $null
            foreach ($key in $Routes.Keys) {
                if ($key.ToLower() -eq $potentialSub.ToLower()) {
                    $matchedPotential = $key
                    break
                }
            }
            if ($matchedPotential) {
                $subcommand = $matchedPotential
                $restArgs = @('-help')
            }
        } else {
            # Just 'help' -> execute default route
            if ($Routes.ContainsKey('default')) {
                $target = $Routes['default']
                _UHRouter_Invoke $target $restArgs
                return
            }
        }
    }

    # Handle empty / no subcommand
    if (-not $subcommand -or $subcommand -eq '') {
        if ($Routes.ContainsKey('default')) {
            $target = $Routes['default']
            _UHRouter_Invoke $target $restArgs
        } else {
            _UHRouter_NoRoute $ModuleName $Routes $null $Theme
        }
        return
    }

    # Normalize subcommand (lower-case matching)
    $subLower = $subcommand.ToLower()

    # Exact match
    $matchedKey = $null
    foreach ($key in $Routes.Keys) {
        if ($key.ToLower() -eq $subLower) { $matchedKey = $key; break }
    }

    if ($matchedKey) {
        $target = $Routes[$matchedKey]
        _UHRouter_Invoke $target $restArgs
        return
    }

    # ── Fuzzy "Did you mean?" fallback ────────────────────────────────────────
    _UHRouter_NoRoute $ModuleName $Routes $subcommand $Theme
}

# ── Private: Invoke a route (scriptblock or function name string) ─────────────
function _UHRouter_Invoke {
    param(
        [Parameter(Mandatory = $true)][object]$Target,
        [Parameter(Mandatory = $false)][string[]]$RestArgs = @()
    )
    if ($Target -is [scriptblock]) {
        & $Target $RestArgs
    } elseif ($Target -is [string]) {
        if (Get-Command $Target -ErrorAction SilentlyContinue) {
            & $Target @RestArgs
        } else {
            Write-Warning "[UHRouter] Function '$Target' not found in session scope."
        }
    } else {
        Write-Warning "[UHRouter] Unsupported route type: $($Target.GetType().Name)"
    }
}

# ── Private: Fuzzy distance (Levenshtein) and no-route error message ──────────
function _UHRouter_NoRoute {
    param(
        [string]$ModuleName,
        [System.Collections.Generic.IDictionary[string, object]]$Routes,
        [string]$Subcommand,
        [object]$Theme = 'uhwriter'
    )

    $themeObj = $null
    if ($Theme -is [hashtable]) {
        $themeObj = $Theme
    } else {
        $themeObj = Get-UHTheme -Name $Theme
    }

    $routeKeys = @($Routes.Keys | Where-Object { $_ -ne 'default' } | Sort-Object)

    if ($Subcommand) {
        $unknownText = Format-ThemeText -String "Unknown subcommand:" -Theme $themeObj -Element 'ParamReq'
        $subtext = Format-ThemeText -String "'$Subcommand'" -Theme $themeObj -Element 'ParamName'
        Write-Host "${unknownText} ${subtext}"

        # Levenshtein distance for fuzzy suggest
        $suggestions = foreach ($key in $routeKeys) {
            [pscustomobject]@{ key = $key; dist = (_UHRouter_Levenshtein $Subcommand $key) }
        }
        $best = $suggestions | Sort-Object dist | Select-Object -First 3 | Where-Object { $_.dist -le 4 }
        if ($best) {
            Write-Host ""
            $didYouMeanText = Format-ThemeText -String "Did you mean?" -Theme $themeObj -Element 'ParamDesc'
            Write-Host $didYouMeanText
            foreach ($b in $best) {
                $bkeyText = Format-ThemeText -String "  $($b.key)" -Theme $themeObj -Element 'ParamName'
                Write-Host $bkeyText
            }
        }
    }

    $availStart = Format-ThemeText -String "Available subcommands for " -Theme $themeObj -Element 'ParamDesc'
    $modNameText = Format-ThemeText -String $ModuleName -Theme $themeObj -Element 'Header'
    $availEnd = Format-ThemeText -String ":" -Theme $themeObj -Element 'ParamDesc'
    Write-Host ""
    Write-Host "${availStart}${modNameText}${availEnd}"
    foreach ($key in $routeKeys) {
        $keyText = Format-ThemeText -String "  $key" -Theme $themeObj -Element 'ParamName'
        Write-Host $keyText
    }
    Write-Host ""
}

# ── Private: Iterative Levenshtein distance ───────────────────────────────────
function _UHRouter_Levenshtein {
    param([string]$a, [string]$b)
    $a = $a.ToLower()
    $b = $b.ToLower()
    $lenA = $a.Length
    $lenB = $b.Length
    if ($lenA -eq 0) { return $lenB }
    if ($lenB -eq 0) { return $lenA }

    $prev = 0..$lenB
    $curr = [int[]]::new($lenB + 1)

    for ($i = 1; $i -le $lenA; $i++) {
        $curr[0] = $i
        for ($j = 1; $j -le $lenB; $j++) {
            $cost = if ($a[$i-1] -eq $b[$j-1]) { 0 } else { 1 }
            $curr[$j] = [Math]::Min(
                [Math]::Min($curr[$j-1] + 1, $prev[$j] + 1),
                $prev[$j-1] + $cost
            )
        }
        $prev = $curr.Clone()
    }
    return $prev[$lenB]
}
