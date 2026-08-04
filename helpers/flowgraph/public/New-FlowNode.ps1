function New-FlowNode {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Id,

        [Parameter(Position = 1)]
        [Alias('Name')]
        [string]$Label,

        [Parameter(Position = 2)]
        [ValidateSet('Default','Start','End','Process','Decision','IO','Error','Warning','Info','Success')]
        [string]$Type = 'Default',

        [Parameter()]
        [string]$Meta,

        [Parameter()]
        [hashtable]$Style
    )

    $defaultStyle = @{
        Status         = 'Default'
        CompleteStatus = 'Complete'
        ColorMode      = 'Static'
        Color          = ''
        GradientFrom   = ''
        GradientTo     = ''
        Value          = 0
        Maximum        = 100
        CompleteColor  = ''
    }

    if ($Style) {
        foreach ($k in $Style.Keys) {
            $defaultStyle[$k] = $Style[$k]
        }
    }

    $node = @{
        Id             = $Id
        Label          = if ($Label) { $Label } else { $Id }
        Type           = $Type
        Status         = 'Default'
        CompleteStatus = 'Complete'
        ColorMode      = 'Static'
        Style          = $defaultStyle
    }

    if ($Meta) { $node.Meta = $Meta }

    return $node
}
