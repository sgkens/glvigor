# ==============================================================================
# File: Private/Undo-SecureString.ps1
# ==============================================================================
using namespace System.Runtime.InteropServices

function Undo-SecureString {
    <#
    .SYNOPSIS
        Converts a SecureString back to a plain-text string in memory safely.
    .DESCRIPTION
        Converts a SecureString to a plain-text string using unmanaged memory BSTR marshalling.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    [Alias('uss')]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [System.Security.SecureString]$SecureString
    )

    process {
        $pointer = [Marshal]::SecureStringToBSTR($SecureString)
        try {
            return [Marshal]::PtrToStringBSTR($pointer)
        }
        finally {
            [Marshal]::ZeroFreeBSTR($pointer)
        }
    }
}