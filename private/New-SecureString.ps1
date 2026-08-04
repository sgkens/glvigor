<#
.SYNOPSIS
    Creates a SecureString from a string

.DESCRIPTION
    Creates a SecureString from a string

.PARAMETER String
    The string to convert to a SecureString

.EXAMPLE
    PS C:\> New-SecureString -String "Hello World"
#>
function New-SecureString {
    [CmdletBinding()]
    [OutputType('SecureString')]
    [Alias('nss')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$String
    )
    process{
        # Initialize a new SecureString and populate it
        [SecureString] $SecureString = [SecureString]::new()
        $String.ToCharArray() | ForEach-Object { $SecureString.AppendChar($_) }
        $SecureString.MakeReadOnly()
        return $SecureString
    }
}