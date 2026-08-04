<#
.SYNOPSIS
  Colorize a string using ANSI escape sequences.

.DESCRIPTION
  The New-Color function takes a string and a color, and returns the string with the specified color.

.PARAMETER string
  The input string to be colorized.

.PARAMETER color
  The color to be applied to the string.

.PARAMETER bgcolor
  The background color to be applied to the string.

.PARAMETER padding
  The padding to be applied to the string.

.EXAMPLE
  New-Color -string "Hello World" -color 1
  New-Color -string "Hello World" -color 1 -bgcolor 2

.OUTPUTS
  The colorized string.

.NOTES
  The available colors are from 0 to 255.

.LINK
  https://en.wikipedia.org/wiki/ANSI_escape_code
#>

Function New-ColorConsole() {
    [CmdletBinding()]
    [Alias('csole')]
    [OutputType([string])]
    param(
        [parameter(mandatory = $true, Position = 0)]
        [string]$string,
        [parameter(mandatory = $false, Position = 1)]
        [int]$color = 15,
        [parameter(mandatory = $false)]
        [int]$bgcolor = 0,
        [parameter(mandatory = $false)]
        [int]$padding = 0
    )
    Begin {
        # Define the escape sequence for color formatting
        $escapeSequence = [char]27
        # Define color codes
        $colorReset = "${escapeSequence}[0m"   # Reset color
    }
    process {
        $paddedString = "{0,-$padding}" -f $string
        if ($PSVersionTable.PSVersion.Major -eq 5) {
            $colorString = "${escapeSequence}[38;5;${color}m${paddedString}${colorReset}"
            if ($bgcolor -ge 0) {
                $colorString = "${escapeSequence}[48;5;${bgcolor}m$colorString"
            }
            return $colorString
        }
        else {
            # PowerShell 7.0 and above
            # Use ANSI escape sequences to colorize the string
            # https://en.wikipedia.org/wiki/ANSI_escape_code
            $colorString = "`e[38;5;${color}m${paddedString}`e[0m"
            if ($bgcolor -ge 0) {
                $colorString = "`e[48;5;${bgcolor}m$colorString"
            }
            return $colorString
        }
    }
}

$cmdletconfig = @{
    function = @('New-ColorConsole')
    alias    = @('csole')
}
Export-ModuleMember @cmdletconfig