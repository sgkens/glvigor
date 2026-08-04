<#
.SYNOPSIS
Calls Get-LocalRemoteConfig and parses git origin and returns filtered pscustomobject

.DESCRIPTION
Calls Get-LocalRemoteConfig and parses git origin and returns filtered pscustomobject

.EXAMPLE
Get-GitOrigin

.NOTES
#>




function Get-GitOrigin {
    [cmdletbinding()]
    [OutputType([pscustomobject])]
    [Alias('glvgo')]
    param()
    process {
        [console]::write("$($global:_glvigor.log) getting git origin configuration`n")
        $origin = Get-LocalRemoteConfig | where-Object { $_.Name -eq 'origin' }
        [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.git_config)::($(csole -s 'filter origin in object' -c $global:__glvigor.colorpallet.yellow))`n")
        return $origin
    }
}

$cmdletconfig = @{
    function = @("Get-GitOrigin")
    alias    = @("glvgo")
}

Export-Modulemember @cmdletconfig
