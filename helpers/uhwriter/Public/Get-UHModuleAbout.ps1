function Get-UHModuleAbout {
    <#
    .SYNOPSIS
      Reports a PowerShell module manifest and its declared components.
    .DESCRIPTION
      Reads a .psd1 with Import-PowerShellDataFile and resolves its root module, nested modules,
      required assemblies, required modules, scripts, type data, and format data without importing
      the target module.
    .PARAMETER Module
      Module name. Defaults to UHWriter.
    .PARAMETER Path
      Path to a module manifest.
    .EXAMPLE
      Get-UHModuleAbout -Module UHWriter
    .EXAMPLE
      Get-UHModuleAbout -Path ./uhwriter.psd1
    .OUTPUTS
      UHWriter.ModuleAbout
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByModule')]
    [OutputType('UHWriter.ModuleAbout')]
    param(
        [Parameter(ParameterSetName = 'ByModule', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Module = 'UHWriter',
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPath', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('ManifestPath', 'FullName')]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    process {
        $manifestPath = if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
            [System.IO.Path]::GetFullPath($Path)
        } else {
            $moduleInfo = Get-Module -Name $Module -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
            if ($null -eq $moduleInfo) {
                throw [System.Management.Automation.ItemNotFoundException]::new(
                    "PowerShell module '$Module' was not found on PSModulePath."
                )
            }
            if ([System.IO.Path]::GetExtension($moduleInfo.Path) -eq '.psd1') {
                $moduleInfo.Path
            } else {
                [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($moduleInfo.Path), "$($moduleInfo.Name).psd1")
            }
        }
        if (-not [System.IO.File]::Exists($manifestPath)) {
            throw [System.IO.FileNotFoundException]::new('PowerShell module manifest was not found.', $manifestPath)
        }

        $manifest = Import-PowerShellDataFile -Path $manifestPath
        $moduleRoot = [System.IO.Path]::GetDirectoryName($manifestPath)
        $components = [System.Collections.Generic.List[object]]::new()

        function Get-UHManifestValue {
            param([string]$Key)
            if ($manifest.ContainsKey($Key)) { return $manifest[$Key] }
            return $null
        }

        function Add-UHManifestComponent {
            param([string]$Kind, [object[]]$Entries)
            foreach ($entry in @($Entries)) {
                if ($null -eq $entry -or [string]::IsNullOrWhiteSpace([string]$entry)) { continue }
                $displayName = if ($entry -is [string]) {
                    $entry
                } elseif ($entry -is [hashtable] -and $entry.ContainsKey('ModuleName')) {
                    [string]$entry.ModuleName
                } elseif ($entry.PSObject.Properties['ModuleName']) {
                    [string]$entry.ModuleName
                } else { [string]$entry }
                $resolvedPath = $null
                $exists = $null
                if ($Kind -ne 'RequiredModule') {
                    $resolvedPath = if ([System.IO.Path]::IsPathRooted($displayName)) {
                        $displayName
                    } else {
                        [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($moduleRoot, $displayName))
                    }
                    $exists = [System.IO.File]::Exists($resolvedPath) -or [System.IO.Directory]::Exists($resolvedPath)
                }
                $components.Add([pscustomobject]@{
                    Kind = $Kind; Name = $displayName; ResolvedPath = $resolvedPath
                    Exists = $exists; Declaration = $entry
                })
            }
        }

        Add-UHManifestComponent RootModule @(Get-UHManifestValue RootModule)
        Add-UHManifestComponent NestedModule @(Get-UHManifestValue NestedModules)
        Add-UHManifestComponent RequiredAssembly @(Get-UHManifestValue RequiredAssemblies)
        Add-UHManifestComponent RequiredModule @(Get-UHManifestValue RequiredModules)
        Add-UHManifestComponent Script @(Get-UHManifestValue ScriptsToProcess)
        Add-UHManifestComponent TypeData @(Get-UHManifestValue TypesToProcess)
        Add-UHManifestComponent FormatData @(Get-UHManifestValue FormatsToProcess)

        [pscustomobject]@{
            PSTypeName = 'UHWriter.ModuleAbout'
            Name = [System.IO.Path]::GetFileNameWithoutExtension($manifestPath)
            Version = if (Get-UHManifestValue ModuleVersion) { [version](Get-UHManifestValue ModuleVersion) } else { $null }
            Guid = Get-UHManifestValue GUID
            Description = Get-UHManifestValue Description
            Author = Get-UHManifestValue Author
            CompanyName = Get-UHManifestValue CompanyName
            Copyright = Get-UHManifestValue Copyright
            PowerShellVersion = Get-UHManifestValue PowerShellVersion
            CompatiblePSEditions = @(Get-UHManifestValue CompatiblePSEditions)
            ManifestPath = $manifestPath
            ModuleRoot = $moduleRoot
            RootModule = Get-UHManifestValue RootModule
            FunctionsToExport = @(Get-UHManifestValue FunctionsToExport)
            CmdletsToExport = @(Get-UHManifestValue CmdletsToExport)
            AliasesToExport = @(Get-UHManifestValue AliasesToExport)
            Components = $components.ToArray()
            PrivateData = Get-UHManifestValue PrivateData
        }
    }
}
