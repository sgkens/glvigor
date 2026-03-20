<#
.SYNOPSIS
Calls Get-LocalRemoteConfig and parses git mirror and returns filtered pscustomobject

.DESCRIPTION
Calls Get-LocalRemoteConfig and parses git mirror and returns filtered pscustomobject

.EXAMPLE
Get-LocalMirror

.NOTES
#>

using module ..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1

function Get-LocalMirrors {
    [cmdletbinding()]
    [outputtype([pscustomobject])]
    [Alias('glvlm')]
    param()
    process {
        try{
            [console]::write("$($global:_glvigor.log) parsing repository mirror configurations`n")
            [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.git_config)::($(csole -s 'Get-LocalRemoteConfig' -c 4))`n")
            $LocalMirrors  = Get-LocalRemoteConfig | where-Object { $_.Name -NotLike 'origin*' }
            if ($LocalMirrors.count -eq 0){
                [console]::write("$($global:_glvigor.logSub)$(csole -s ■ -c 6)-notification $(csole -s 'No mirrors found' -c 1)`n")
                break;
            }
        }
        catch [System.Exception] {
            [console]::write("$($global:_glvigor.logSub)$(csole -s ■ -c 1)-error $(csole -s $_.Exception.Message -c 1)`n")
        }
        return $LocalMirrors
    }
}

$cmdletconfig = @{
    function  = @('Get-LocalMirrors')
    alias     = @('glvlm')
}

Export-Modulemember @cmdletconfig