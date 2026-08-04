function Initialize-UHWriterCore {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if ('Uhwriter.HelpRenderer' -as [type]) { return $true }

    $candidates = @(
        [System.IO.Path]::Combine($script:__uhwriter.rootpath, 'libs', 'net8.0', 'Uhwriter.Core.dll'),
        [System.IO.Path]::Combine($script:__uhwriter.rootpath, 'libs', 'net10.0', 'Uhwriter.Core.dll'),
        [System.IO.Path]::Combine($script:__uhwriter.rootpath, 'src', 'Uhwriter.Core', 'bin', 'Release', 'net8.0', 'Uhwriter.Core.dll'),
        [System.IO.Path]::Combine($script:__uhwriter.rootpath, 'src', 'Uhwriter.Core', 'bin', 'Release', 'net10.0', 'Uhwriter.Core.dll'),
        [System.IO.Path]::Combine($script:__uhwriter.rootpath, 'src', 'Uhwriter.Core', 'bin', 'Debug', 'net8.0', 'Uhwriter.Core.dll'),
        [System.IO.Path]::Combine($script:__uhwriter.rootpath, 'src', 'Uhwriter.Core', 'bin', 'Debug', 'net10.0', 'Uhwriter.Core.dll')
    )

    foreach ($candidate in $candidates) {
        if (-not [System.IO.File]::Exists($candidate)) { continue }
        try {
            Add-Type -Path $candidate -ErrorAction Stop
            return $null -ne ('Uhwriter.HelpRenderer' -as [type])
        } catch {
            Write-Verbose "Unable to load UHWriter .NET core from '$candidate': $($_.Exception.Message)"
        }
    }
    return $false
}
