<#
.SYNOPSIS
Parses git remote -v and returns pscustomobject with property Name, Type, and URL

.DESCRIPTION
Parses git remote -v and returns pscustomobject with property Name, Type, and URL

.EXAMPLE
Get-LocalRemoteConfig

.NOTES
Doesnt require authentication

#>
using module ..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1

function Get-LocalRemoteConfig {
    [cmdletbinding()]
    [Alias('glvlrc')]
    [OutputType([pscustomobject])]
    param()
    process {
        [console]::write("$($global:_glvigor.log) getting repository $(csole -s origin -c 3) and $(csole -s mirror -c 3) configuration`n")
        [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.git_config)::($(csole -s 'git remote -v' -c 2)) `n")
        [string[]]$remotes = git remote -v # list all remotes mirrors and origins
        #$remotes_object = @{}
        [pscustomobject[]]$meta_data = @()
        foreach ($remote in $remotes) {
            $remote = $remote -split '\s+'
            $remote_name = $remote[0]
            $remote_url = $remote[1]
            $remote_type = $remote[2]

            $meta_data += [pscustomobject]@{
                Name = $remote_name
                Type = $remote_type -replace '\(|\)', ''
                URL = $remote_url
            }
        }
        [console]::write("$($global:_glvigor.logsub) $(csole -s 'parsing git remote data...' -c 2)`n")
        
        return $meta_data

    }
}

$cmdletconfig = @{
    function = @("Get-LocalRemoteConfig")
    alias    = @("glvlrc")
}

Export-Modulemember @cmdletconfig