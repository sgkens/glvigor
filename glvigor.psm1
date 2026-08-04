# ==============================================================================
# File: glvigor.psm1
# ==============================================================================
<#
  .88888.  dP                 oo
 d8'   `88 88
 88        88        dP   .dP dP .d8888b. .d8888b. 88d888b.
 88   YP88 88        88   d8' 88 88'  `88 88'  `88 88'  `88
 Y8.   .88 88        88'  88  88..88   88..88   88
  `88888'  88888888P 8888P'   dP `8888P88 `88888P' dP
                                      .88
 ______________--------------------d8888P----------------------------------

 GLVigor offers a comprehensive set of cmdlets for managing key resources
 on a GitLab instance with full CLI and interactive TUI support.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$moduleRoot = $PSScriptRoot

# Global theme properties for centralized visual styling
$global:GLVTheme = @{
    PrimaryHex   = "#00FFAA"
    SecondaryHex = "#0088FF"
    BorderColor  = 240
    TitleColor   = 39
    SuccessColor = 82
    ErrorColor   = 196
    WarningColor = 214
    BorderStyle  = "Rounded"
}

# Compatibility palette used by the existing public cmdlets.
$global:__glvigor = @{
    colorpallet = @{
        white      = 15
        black      = 0
        red        = 1
        green      = 2
        yellow     = 3
        blue       = 4
        magenta    = 5
        cyan       = 6
        gray       = 8
        darkyellow = 130
        darkcyan   = 30
        darkblue   = 19
        darkred    = 88
        orange     = 208
        purple     = 93
    }
}

# Initialize global state container
$global:_glvigor = @{
    rootpath = $moduleRoot
    auth     = $null
    theme    = $global:GLVTheme
}

# 1. Dot-source embedded `flowgraph` internal engine and functions directly
$flowgraphEngine = Join-Path $moduleRoot 'helpers/flowgraph/private/Engine.ps1'
if (Test-Path $flowgraphEngine) { . $flowgraphEngine }

Get-ChildItem -Path (Join-Path $moduleRoot 'helpers/flowgraph/public') -Filter '*.ps1' -File | ForEach-Object {
    . $_.FullName
}

# 2. Import embedded `uhwriter` module helper
$uhwriterPath = Join-Path $moduleRoot 'helpers/uhwriter/uhwriter.psm1'
if (Test-Path -Path $uhwriterPath) {
    Import-Module $uhwriterPath -Force
}

# 3. Dot-source Helpers (excluding nested module subdirectories uhwriter & flowgraph)
Get-ChildItem -Path (Join-Path $moduleRoot 'helpers') -Filter '*.ps1' -File | ForEach-Object {
    . $_.FullName
}

Get-ChildItem -Path (Join-Path $moduleRoot 'helpers/ui') -Filter '*.ps1' -File | ForEach-Object {
    . $_.FullName
}

# Existing cmdlets consume these shared logging properties under strict mode.
$cp = $global:__glvigor.colorpallet
$logTitle = "GLVigor"
$logSub = "  | "
$logSubRun = "  |--- "
$logSubLast = "  `--- "
$separator = "=>"

$global:_glvigor.log = $logTitle
$global:_glvigor.logSub = $logSub
$global:_glvigor.logSubReturn = $logSub
$global:_glvigor.logSubRun = $logSubRun
$global:_glvigor.logsubni = '  '
$global:_glvigor.logsublast = $logSubLast
$global:_glvigor.sep = $separator
$global:_glvigor.pg = '~'
$global:_glvigor.error = 'error'
$global:_glvigor.logcmds = @{
    api_get        = 'gitlab-api::get'
    api_post       = 'gitlab-api::post'
    api_put        = 'gitlab-api::put'
    api_update     = 'gitlab-api::update'
    api_delete     = 'gitlab-api::delete'
    api_sub        = $logSub
    git_command    = "git::command $separator"
    git_config     = "git::config $separator"
    git_github_api = "git::github-api $separator"
    run            = "action::run $separator"
    gitea_api_post = "gitea-api::post $separator"
    gitea_api_get  = "gitea-api::get $separator"
}

# 4. Dot-source Private Functions (Internal encapsulate helpers)
Get-ChildItem -Path (Join-Path $moduleRoot 'private') -Filter '*.ps1' -Recurse -File | ForEach-Object {
    . $_.FullName
}

# 5. Dot-source Public Cmdlets
Get-ChildItem -Path (Join-Path $moduleRoot 'public') -Filter '*.ps1' -Recurse -File | ForEach-Object {
    . $_.FullName
}

# Export Public Functions and Aliases explicitly
$publicFunctions = Get-ChildItem -Path (Join-Path $moduleRoot 'public') -Filter '*.ps1' | Select-Object -ExpandProperty BaseName

Set-Alias -Name 'glv' -Value 'Invoke-GLVigor' -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name 'glvrp' -Value 'Request-Project' -Scope Global -ErrorAction SilentlyContinue

Export-ModuleMember -Function $publicFunctions -Alias 'glv', 'glvrp'
