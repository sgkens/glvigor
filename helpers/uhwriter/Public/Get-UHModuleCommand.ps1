function Get-UHModuleCommand {
    <#
    .SYNOPSIS
      Lists commands publicly exported by PowerShell modules.
    .DESCRIPTION
      Returns exported functions and cmdlets from loaded or discoverable modules. Results support
      module, name, verb, noun, command-type, and PowerShell verb-group category filters.
    .PARAMETER Module
      Module names or wildcard patterns. Defaults to UHWriter.
    .PARAMETER Name
      Command name wildcard patterns.
    .PARAMETER Verb
      Command verb wildcard patterns.
    .PARAMETER Noun
      Command noun wildcard patterns.
    .PARAMETER CommandType
      Public command types to include.
    .PARAMETER Category
      PowerShell verb groups such as Common, Data, Diagnostic, Lifecycle, or Security.
    .PARAMETER AllAvailable
      Searches every module on PSModulePath. Module defaults to '*'.
    .EXAMPLE
      Get-UHModuleCommand
    .EXAMPLE
      Get-UHModuleCommand -Module Microsoft.PowerShell.* -Category Diagnostic
    .OUTPUTS
      UHWriter.ModuleCommand
    #>
    [CmdletBinding()]
    [OutputType('UHWriter.ModuleCommand')]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('ModuleName')]
        [SupportsWildcards()]
        [string[]]$Module = @('UHWriter'),
        [SupportsWildcards()]
        [string[]]$Name = @('*'),
        [SupportsWildcards()]
        [string[]]$Verb = @('*'),
        [SupportsWildcards()]
        [string[]]$Noun = @('*'),
        [ValidateSet('Function', 'Cmdlet')]
        [string[]]$CommandType = @('Function', 'Cmdlet'),
        [SupportsWildcards()]
        [string[]]$Category = @('*'),
        [switch]$AllAvailable
    )

    begin {
        $modulePatterns = [System.Collections.Generic.List[string]]::new()
        $verbGroups = @{}
        foreach ($verbInfo in Get-Verb) { $verbGroups[$verbInfo.Verb] = $verbInfo.Group }

        function Test-UHWildcard {
            param([string]$Value, [string[]]$Pattern)
            foreach ($item in $Pattern) {
                if ($Value -like $item) { return $true }
            }
            return $false
        }
    }

    process {
        foreach ($modulePattern in $Module) {
            if (-not [string]::IsNullOrWhiteSpace($modulePattern)) { $modulePatterns.Add($modulePattern) }
        }
    }

    end {
        if ($AllAvailable -and $modulePatterns.Count -eq 1 -and $modulePatterns[0] -eq 'UHWriter') {
            $modulePatterns[0] = '*'
        }

        $modulesByIdentity = [System.Collections.Generic.Dictionary[string, object]]::new(
            [System.StringComparer]::OrdinalIgnoreCase
        )
        foreach ($candidate in @(@(Get-Module) + @(Get-Module -ListAvailable))) {
            if ($null -eq $candidate -or [string]::IsNullOrWhiteSpace($candidate.Name)) { continue }
            if (-not (Test-UHWildcard -Value $candidate.Name -Pattern $modulePatterns.ToArray())) { continue }
            $identity = '{0}|{1}|{2}' -f $candidate.Name, $candidate.Version, $candidate.Path
            if (-not $modulesByIdentity.ContainsKey($identity)) { $modulesByIdentity.Add($identity, $candidate) }
        }

        foreach ($moduleInfo in $modulesByIdentity.Values) {
            foreach ($entry in $moduleInfo.ExportedCommands.GetEnumerator()) {
                $command = $entry.Value
                $typeName = $command.CommandType.ToString()
                if ($typeName -notin $CommandType) { continue }
                $commandVerb = if ($command.PSObject.Properties['Verb']) { [string]$command.Verb } else { '' }
                $commandNoun = if ($command.PSObject.Properties['Noun']) { [string]$command.Noun } else { '' }
                if ([string]::IsNullOrEmpty($commandVerb) -or [string]::IsNullOrEmpty($commandNoun)) {
                    $parts = $command.Name -split '-', 2
                    $commandVerb = $parts[0]
                    $commandNoun = if ($parts.Count -gt 1) { $parts[1] } else { '' }
                }
                $commandCategory = if ($verbGroups.ContainsKey($commandVerb)) {
                    [string]$verbGroups[$commandVerb]
                } else { 'Other' }

                if (-not (Test-UHWildcard -Value $command.Name -Pattern $Name)) { continue }
                if (-not (Test-UHWildcard -Value $commandVerb -Pattern $Verb)) { continue }
                if (-not (Test-UHWildcard -Value $commandNoun -Pattern $Noun)) { continue }
                if (-not (Test-UHWildcard -Value $commandCategory -Pattern $Category)) { continue }

                [pscustomobject]@{
                    PSTypeName  = 'UHWriter.ModuleCommand'
                    Name        = $command.Name
                    ModuleName  = $moduleInfo.Name
                    Version     = $moduleInfo.Version
                    CommandType = $typeName
                    Verb        = $commandVerb
                    Noun        = $commandNoun
                    Category    = $commandCategory
                    Synopsis    = if ($command.PSObject.Properties['Description']) { [string]$command.Description } else { '' }
                    CommandInfo = $command
                }
            }
        }
    }
}
