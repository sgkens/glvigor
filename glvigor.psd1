@{

    # Script module or binary module file associated with this manifest.
    RootModule        = 'glvigor.psm1'

    # Version number of this module.
    ModuleVersion     = '0.12.0.0'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID              = '7419527a-be12-42d4-910f-b26e8027a3c1'

    # Author of this module
    Author            = 'sgkens'

    # Company or vendor of this module
    CompanyName       = 'sgkens'

    # Copyright statement for this module
    Copyright         = '2024 sgkens. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'GLViger offers a comprehensive set of cmdlets for managing key resources on a GitLab instance. With this module, you can create, view, update, remove, and search for *issues*, *merge requests*, *projects*, *groups*, and *labels* through the GitLab API. Additionally, the module includes cmdlets for handling Git-related functions, such as *viewing*, *adding*, and removing *mirrors*, as well as updating the *origin*.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.4.5'

    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # ClrVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @('./helpers/uhwriter/uhwriter.psd1')

    FunctionsToExport = '*'

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = '*'

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = 'automation'

            # A URL to the license for this module.
            LicenseUri   = 'https://choosealicense.com/licenses/mit'

            # A URL to the main website for this project.
            ProjectUri   = 'https://gitlab.com/phellams/glvigor.git'

            # A URL to an icon representing this module.
            IconUri      = 'https://gitlab.com/phellams/glvigor/-/blob/main/logo.svg'

            # ReleaseNotes of this module
            ReleaseNotes = 'https://gitlab.com/phellams/glvigor/-/blob/main/Releases.md'

            # Prerelease string of this module
            Prerelease   = 'alpha1'

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}

