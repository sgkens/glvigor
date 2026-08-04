@{
    ModuleVersion     = '0.19.0'
    GUID              = '083f04e0-3fe0-42ec-a918-f799e1f1df39'
    Author            = 'Garvey K. Snow'
    CompanyName       = 'Phallems'
    Copyright         = '(c) 2025 Phallems. All rights reserved.'
    Description       = 'UHWriter: cross-platform themed CLI help rendering with PowerShell AST extraction, a .NET API, and a Native AOT executable.'
    RootModule        = 'uhwriter.psm1'
    FunctionsToExport = @(
        'New-UHWriter',
        'Invoke-UHWriterNative',
        'Write-UHAsciiLogo',
        'Export-UHWriterMetadata',
        'Invoke-UHPager',
        'New-UHRouter',
        'Show-UHTheme',
        'Get-UHModuleCommand',
        'Show-UHCommandCatalog',
        'Get-UHModuleAbout',
        'Get-TerminalPalette',
        'New-AsciiTokenGradient'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @('uhextract', 'uhpager', 'uhroute', 'terpal', 'Get-TerminalPallete', 'shldc')
    PrivateData       = @{
        PSData = @{
            Tags         = @('Help', 'Formatting', 'CLI', 'PowerShell', 'DotNet', 'NativeAOT', 'Documentation', 'AST', 'TUI', 'Router', 'Themes', 'Pager', 'man')
            ReleaseNotes = @()
            RequireLicenseAcceptance = $false
            IconUri                  = 'https://raw.githubusercontent.com/phellams/phellams-general-resources/main/logos/uhwriter/dist/png/uhwriter-logo-128x128.png'
            LicenseUrl               = 'https://choosealicense.com/licenses/mit'
            ProjectUrl               = 'https://gitlab.com/phellams/uhwriter'
            LicenseUri               = 'https://choosealicense.com/licenses/mit'
            ProjectUri               = 'https://gitlab.com/phellams/uhwriter.git'
            IconUrl                  = 'https://raw.githubusercontent.com/phellams/phellams-general-resources/main/logos/uhwriter/dist/png/uhwriter-logo-128x128.png'
            Docsurl                  = 'https://phellams.gitlab.io/uhwriter'
            MailingListUrl           = 'https://gitlab.com/phellams/uhwriter/-/issues'
            projectSourceUrl         = 'https://gitlab.com/phellams/uhwriter.git'
            bugTrackerUrl            = 'https://gitlab.com/phellams/uhwriter/-/issues'
            Summary                  = 'A PowerShell module for generating custom, colored help text with a man-page-like layout.'
            Prerelease               = ''
        }
    }
}
