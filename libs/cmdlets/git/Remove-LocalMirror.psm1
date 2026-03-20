<#
.SYNOPSIS
Removes a local git mirror

.DESCRIPTION
Removes a local git mirror

.PARAMETER Name
The name of the mirror to remove

.EXAMPLE
Remove-LocalMirror -Name 'mirror'

.NOTES
none.
#>

using module ..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
function Remove-LocalMirror {
    [cmdletbinding()]
    [outputtype([void])]
    [Alias('glvslm')]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    process {
        try{
            [console]::write("$($global:_glvigor.log) getting local remote configuration`n")
            if(Get-LocalRemoteConfig | where-Object { $_.Name -eq $Name }){
                [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.git_config)::($(csole -s "git remote remove $Name" -c 3)) `n")
                git remote remove $Name
                [console]::write("$($global:_glvigor.logsub) done.`n")
            }
        } catch [system.Exception] {
            [console]::write("$($global:_glvigor.log) $(csole -s $_.Exception.Message -c 1)`n")
        }
    }
}

$cmdletconfig = @{
    function = @('Remove-LocalMirror')
    alias = @('glvslm')
}
Export-ModuleMember @cmdletconfig