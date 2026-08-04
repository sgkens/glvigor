function New-ColorConsole {
    <#
    .SYNOPSIS
      Colorize a string using ANSI escape sequences.
    .DESCRIPTION
      Wrapper around New-AsciiColor for backwards compatibility.
    .PARAMETER String
      The input string to be colorized.
    .PARAMETER Color
      The foreground color name or index.
    .PARAMETER BgColor
      The background color name or index.
    .PARAMETER Format
      The formatting flags.
    #>
    [CmdletBinding()]
    [Alias('csole')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$String,

        [Parameter(Position = 1)]
        [string]$Color = 'white',

        [Parameter(Position = 2)]
        [string]$BgColor = '',

        [Parameter(Position = 3)]
        [string[]]$Format = @()
    )

    process {
        New-AsciiColor -String $String -Color $Color -BgColor $BgColor -Format $Format
    }
}
