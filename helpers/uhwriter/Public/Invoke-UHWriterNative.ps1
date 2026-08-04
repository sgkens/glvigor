function Invoke-UHWriterNative {
    <#
    .SYNOPSIS
      Renders UHWriter JSON through the cross-platform UHWriter executable.
    .DESCRIPTION
      Provides a PowerShell pipeline adapter for the language-neutral UHWriter CLI. PowerShell AST
      extraction remains available through Export-UHWriterMetadata; its output can be piped directly
      to this command after the portable CLI has been built or installed.
    .PARAMETER InputObject
      A UHWriter metadata object, hashtable, JSON string, or path to a JSON document.
    .PARAMETER CliPath
      Optional explicit path to the UHWriter executable. When omitted, the command searches PATH and
      then the repository's dist/dotnet/aot directory.
    .PARAMETER HelpSection
      One or more sections to render.
    .PARAMETER HelpParam
      Restricts parameter output to matching names or aliases.
    .PARAMETER NoColor
      Disables ANSI colors.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [string]$CliPath,

        [ValidateSet('Syntax', 'Description', 'Subcommands', 'Parameters', 'Examples', 'Docs')]
        [string[]]$HelpSection,

        [string]$HelpParam,

        [switch]$NoColor
    )

    begin {
        $readField = {
            param([object]$Value, [string]$Name)
            if ($Value -is [System.Collections.IDictionary]) {
                foreach ($key in $Value.Keys) {
                    if ([string]$key -ieq $Name) { return $Value[$key] }
                }
                return $null
            }
            $property = $Value.PSObject.Properties | Where-Object { $_.Name -ieq $Name } | Select-Object -First 1
            if ($property) { return $property.Value }
            return $null
        }

        if ([string]::IsNullOrWhiteSpace($CliPath)) {
            $nativeCommand = Get-Command -Name uhwriter -CommandType Application -ErrorAction Ignore | Select-Object -First 1
            if ($nativeCommand) {
                $CliPath = $nativeCommand.Source
            } else {
                $executableName = if ($IsWindows) { 'uhwriter.exe' } else { 'uhwriter' }
                $candidateRoot = [System.IO.Path]::Combine($script:__uhwriter.rootpath, 'dist', 'dotnet', 'aot')
                if ([System.IO.Directory]::Exists($candidateRoot)) {
                    $candidate = [System.IO.Directory]::GetFiles($candidateRoot, $executableName, [System.IO.SearchOption]::AllDirectories) | Select-Object -First 1
                    if ($candidate) { $CliPath = $candidate }
                }
            }
        }
        if ([string]::IsNullOrWhiteSpace($CliPath) -or -not [System.IO.File]::Exists($CliPath)) {
            throw "UHWriter native executable not found. Add 'uhwriter' to PATH or provide -CliPath."
        }
    }

    process {
        $json = if ($InputObject -is [string] -and [System.IO.File]::Exists($InputObject)) {
            [System.IO.File]::ReadAllText([System.IO.Path]::GetFullPath($InputObject))
        } elseif ($InputObject -is [string] -and $InputObject.TrimStart().StartsWith('{')) {
            $InputObject
        } else {
            $command = & $readField $InputObject 'command'
            $commandInfo = & $readField $InputObject 'commandinfo'
            if ($null -eq $command -and $null -ne $commandInfo) {
                $portableParameters = [System.Collections.Generic.List[object]]::new()
                foreach ($item in @(& $readField $InputObject 'paramtable')) { if ($null -ne $item) { $portableParameters.Add($item) } }
                $portableSubcommands = [System.Collections.Generic.List[object]]::new()
                foreach ($item in @(& $readField $InputObject 'subcommands')) { if ($null -ne $item) { $portableSubcommands.Add($item) } }
                $portableExamples = [System.Collections.Generic.List[string]]::new()
                foreach ($item in @(& $readField $InputObject 'examples')) { if ($null -ne $item) { $portableExamples.Add([string]$item) } }
                $portableDocument = [ordered]@{
                    name        = (& $readField $InputObject 'name')
                    version     = (& $readField $InputObject 'version')
                    sourceType  = (& $readField $InputObject 'sourcetype')
                    command     = $commandInfo
                    parameters  = $portableParameters
                    subcommands = $portableSubcommands
                    examples    = $portableExamples
                    options     = [ordered]@{}
                }
                $portableDocument | ConvertTo-Json -Depth 20 -Compress
            } else {
                $InputObject | ConvertTo-Json -Depth 20 -Compress
            }
        }

        $arguments = [System.Collections.Generic.List[string]]::new()
        $arguments.Add('render')
        if ($HelpSection) { $arguments.Add('--section'); $arguments.Add(($HelpSection -join ',')) }
        if (-not [string]::IsNullOrWhiteSpace($HelpParam)) { $arguments.Add('--param'); $arguments.Add($HelpParam) }
        if ($NoColor) { $arguments.Add('--no-color') }

        $json | & $CliPath @arguments
        if ($LASTEXITCODE -ne 0) { throw "UHWriter native renderer exited with code $LASTEXITCODE." }
    }
}
