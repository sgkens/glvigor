function New-Paragraph {
    <#
    .SYNOPSIS
    New-Paragraph is a function that generates readable text by indenting it, simulating the effect of a paragraph in a book.
    .DESCRIPTION
    New-Paragraph is a function that generates readable text by indenting it, simulating the effect of a paragraph in a book.
    .PARAMETER position
    The position at which to start the indent.
    .PARAMETER indent
    The number of spaces to indent.
    .PARAMETER string
    The string to be indented.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [int]$position,

        [Parameter(Mandatory = $true)]
        [int]$indent,
       
        [Parameter(Mandatory = $true)]
        [string]$string
    )

    $sb = [System.Text.StringBuilder]::new()
    $words = $string.Split(' ')
    $currentLineLength = 0
    [void]$sb.Append([char]' ', $indent)

    foreach ($word in $words) {
        $wordVisualLen = Get-ClapVisibleLength -Text $word
        if ($currentLineLength + $wordVisualLen -gt $position) {
            [void]$sb.AppendLine()
            [void]$sb.Append([char]' ', $indent)
            $currentLineLength = 0
        }

        [void]$sb.Append($word)
        [void]$sb.Append([char]' ')
        $currentLineLength += $wordVisualLen + 1
    }

    return $sb.ToString()
}
