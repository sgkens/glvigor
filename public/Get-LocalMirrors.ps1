<#
.SYNOPSIS
Calls Get-LocalRemoteConfig and parses git mirror and returns filtered pscustomobject

.DESCRIPTION
Calls Get-LocalRemoteConfig and parses git mirror and returns filtered pscustomobject

.EXAMPLE
Get-LocalMirror

.NOTES
#>



function Get-LocalMirrors {
    [cmdletbinding()]
    [outputtype([pscustomobject])]
    [Alias('glvlm')]
    param()
    process {
        try{
            [console]::write("$($global:_glvigor.log) parsing repository mirror configurations`n")
            [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.git_config)::($(csole -s 'Get-LocalRemoteConfig' -c $global:__glvigor.colorpallet.blue))`n")
            $LocalMirrors  = Get-LocalRemoteConfig | where-Object { $_.Name -NotLike 'origin*' }
            if ($LocalMirrors.count -eq 0){
                [console]::write("$($global:_glvigor.logSub)$(csole -s ■ -c $global:__glvigor.colorpallet.cyan)-notification $(csole -s 'No mirrors found' -c $global:__glvigor.colorpallet.red)`n")
                break;
            }
        }
        catch [System.Exception] {
            [console]::write("$($global:_glvigor.logSub)$(csole -s ■ -c $global:__glvigor.colorpallet.red)-error $(csole -s $_.Exception.Message -c $global:__glvigor.colorpallet.red)`n")
        }
        return $LocalMirrors
    }
}

$cmdletconfig = @{
    function  = @('Get-LocalMirrors')
    alias     = @('glvlm')
}

Export-Modulemember @cmdletconfig
