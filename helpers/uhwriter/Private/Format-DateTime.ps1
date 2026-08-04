function Format-DateTime {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [datetime]$DateTime,

        [Parameter(Mandatory = $true)]
        [validateSet(
            'Standard',
            'LongDate',
            'logDate',
            'ShortDate',
            'FileName',
            'logShort',
            'logShortTime'
        )]
        [string]$FormatName
    )

    $DateFormats = @{
        Standard     = 'yyyy-MM-dd HH:mm:ss'
        LongDate     = 'yyyy-MM-dd HH:mm:ss'
        logDate      = 'yy-MM-dd-HH:mm:ss'
        logShort     = 'MM-dd-HH:mm:ss'
        logShortTime = 'HH:mm:ss'
        ShortDate    = 'yyyy-MM-dd'
        FileName     = 'yyyyMMdd_HHmmss'
    }

    if ($DateFormats.ContainsKey($FormatName)) {
        return $DateTime.ToString($DateFormats[$FormatName])
    }
    return $DateTime.ToString($FormatName)
}
