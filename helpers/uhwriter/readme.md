<div align="center">
    <img width="64" src="https://raw.githubusercontent.com/phellams/phellams-general-resources/main/logos/uhwriter/dist/png/uhwriter-logo-128x128.png" alt="uhwriter Logo" />
    <h1><b>UHWriter (Universal Help Writer)</b></h1>
    <a href='https://gitlab.com/phellams/uhwriter' target='_blank'><img src='https://img.shields.io/gitlab/license/phellams/uhwriter?style=flat-square' alt='license' /></a>
    <a href='https://gitlab.com/phellams/uhwriter/-/pipelines' target='_blank'><img src='https://img.shields.io/gitlab/pipeline-status/phellams/uhwriter?style=flat-square' alt='pipeline' /></a>
    <a href='https://www.powershellgallery.com/packages/uhwriter' target='_blank'><img src='https://img.shields.io/powershellgallery/v/uhwriter?style=flat-square' alt='PowerShell Gallery version' /></a>
    <a href='https://www.nuget.org/packages/uhwriter.Core' target='_blank'><img src='https://img.shields.io/nuget/v/uhwriter.Core?style=flat-square' alt='NuGet version' /></a>
    <br/>
    <span>
        <a href="https://phellams.gitlab.io/uhwriter"> <strong>Docs</strong></a>
        <a href="https://www.powershellgallery.com/packages/uhwriter">| <strong>PSGallery</strong></a>
        <a href="https://www.nuget.org/packages/uhwriter.Core">| <strong>NuGet</strong></a>
        <a href="https://gitlab.com/phellams/uhwriter">| <strong>GitLab</strong></a>
    </span>
    <br/><br/>
  <img src="https://vhs.charm.sh/vhs-5f88jXskJCPrFoUc8EkUL3.gif" alt="Made with VHS">
  <a href="https://vhs.charm.sh">
    <img src="https://stuff.charm.sh/vhs/badge.svg">
  </a>
</div>

UHWriter (_Universal Help Writer_) renders structured terminal help for PowerShell commands, native CLIs, scripts, and applications through a shared JSON contract.

The PowerShell module, managed library, native executable, schemas, build tooling, and documentation use the UHWriter name and identifiers.

## Capabilities

- Render ANSI terminal help from PowerShell objects or language-neutral JSON.
- Extract PowerShell function metadata, comment-based help, and `[Alias()]` declarations without importing the target script.
- Configure aliases explicitly for Bash, Python, native executables, and other non-PowerShell producers.
- Select from 50 themes, six banner layouts, gradients, and five outer-border styles.
- Filter help by section or parameter and display long output in the terminal pager.
- Use the managed .NET renderer, Native AOT CLI, or PowerShell renderer.

## Installation

The module can be loaded directly from a local checkout:

```powershell
# PowerShell, repository root
Import-Module ./uhwriter.psd1 -Force
```

Clone the current repository with:

```bash
# POSIX shell
git clone https://gitlab.com/phellams/uhwriter.git
cd uhwriter
```

See [installation and downloads](docs/downloads.md) for the current artifact matrix.

## PowerShell quick start

Extract metadata and render it:

```powershell
# PowerShell, repository root
$metadata = Export-UHWriterMetadata \
    -Path ./Public/New-UHWriter.ps1 \
    -FunctionName New-UHWriter

$metadata | New-UHWriter -Theme aurora -Compact -OutMode Standard
```

Render direct metadata:

```powershell
# PowerShell
$parameters = @(
    @{
        name        = 'Config'
        aliases     = @('c')
        param       = 'Config'
        type        = 'String'
        required    = $false
        description = 'Path to the configuration file.'
        inline      = $false
    }
)

$command = @{
    cmdlet      = 'mytool'
    synopsis    = 'mytool [-c|Config <String>]'
    description = 'Runs the configured task.'
    source      = 'https://gitlab.com/phellams/uhwriter'
}

New-UHWriter -Name mytool -SourceType cli -CommandInfo $command \
    -ParamTable $parameters -OutMode Standard
```

Parameter rows display the alias and canonical name once, for example `-c|Config [String]`, followed by the description. The former duplicate name column is no longer emitted.

## Universal JSON contract

Non-PowerShell callers configure aliases with the `aliases` array. `param` remains accepted for compatibility with existing UHWriter documents.

```json
{
    "name": "mytool",
    "version": "1.0.0",
    "sourceType": "cli",
    "command": {
        "cmdlet": "mytool",
        "synopsis": "mytool [-c|config <path>]",
        "description": "Runs the configured task.",
        "source": "https://gitlab.com/phellams/uhwriter"
    },
    "parameters": [
        {
            "name": "config",
            "aliases": ["c"],
            "type": "path",
            "required": false,
            "description": "Path to the configuration file.",
            "inline": false
        }
    ],
    "subcommands": [],
    "examples": ["mytool --config ./app.json"],
    "options": {
        "themeName": "uhwriter",
        "color": true,
        "helpSection": []
    }
}
```

Render the document from a native CLI build:

```bash
# POSIX shell
uhwriter render --input ./examples/help.json
```

The native executable is named `uhwriter`.

Apply a theme-defined gradient to selected help elements:

```powershell
# PowerShell
New-UHWriter @metadata -Gradient -GradientTarget Title,Section,ParameterName

# Override the theme's GradientSteps for every supported help element.
New-UHWriter @metadata -Gradient -GradientTarget All -CustomGradient 51,93,201
```

Rename headings for an external CLI without changing section filtering:

```powershell
# PowerShell
New-UHWriter @metadata -SectionLabel @{
    Parameters = 'OPTIONS'
    Examples   = 'USAGE'
}
```

## Documentation

- [Documentation home](docs/index.md)
- [Installation and downloads](docs/downloads.md)
- [Releases and package repositories](docs/releases.md)
- [Portable CLI and .NET API](docs/portable-cli.md)
- [Metadata extraction](docs/metadata-extraction.md)
- [Cmdlet reference](docs/cmdlet-reference.md)
- [API reference](docs/api-reference.md)
- [Themes](docs/themes.md)

## Build and test

```powershell
# PowerShell, repository root
./scripts/test/Test-UHWriterDotNet.ps1
Invoke-Pester ./test/test-unit-pester.ps1
pwsh ./Build-Docs.ps1 -Build
```

## API and configuration reference

| Field or command           | Type                | Default     | Purpose                                                           |
| -------------------------- | ------------------- | ----------- | ----------------------------------------------------------------- |
| `New-UHWriter`             | PowerShell function | —           | Renders help through the managed or PowerShell backend.           |
| `Export-UHWriterMetadata`  | PowerShell function | —           | Extracts PowerShell AST and comment-help metadata.                |
| `Invoke-UHWriterNative`    | PowerShell function | —           | Sends portable metadata to the native renderer.                   |
| `Get-UHModuleCommand`      | PowerShell function | `UHWriter`  | Lists public module commands with wildcard and category filters.  |
| `Show-UHCommandCatalog`    | PowerShell function | `2` columns | Navigates public commands and opens full help for a selection.    |
| `Get-UHModuleAbout`        | PowerShell function | `UHWriter`  | Inspects `.psd1` composition without importing the target module. |
| `parameters[].name`        | String              | Required    | Canonical parameter name.                                         |
| `parameters[].aliases`     | String array        | `[]`        | Explicit aliases for any source language.                         |
| `parameters[].param`       | String              | `""`        | Legacy alias/canonical label, such as `c                          | Config`. |
| `parameters[].type`        | String              | `string`    | Displayed value type.                                             |
| `parameters[].required`    | Boolean             | `false`     | Adds the required marker.                                         |
| `parameters[].description` | String              | Required    | Parameter description.                                            |
| `options.color`            | Boolean             | `true`      | Enables ANSI styling unless `NO_COLOR` is set.                    |
| `options.themeName`        | String              | `uhwriter`  | Selects a built-in theme.                                         |
| `options.helpParam`        | String or null      | `null`      | Filters by canonical name, legacy label, or configured alias.     |

## License

MIT. See [LICENSE](LICENSE).
