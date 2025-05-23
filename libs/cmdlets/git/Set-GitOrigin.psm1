<#
.SYNOPSIS
Sets the git origin configuration for a repository, supporting both parameters and environment variables, supports any git repository.
uses format user:apikey@domain

.DESCRIPTION
This cmdlet sets the git origin configuration for a repository. It allows configuration via parameters or environment variables.

.PARAMETER Origin
The destination instance. Supported values: `gitlab`, `gitlaben`, `gitea`, `github`.

.PARAMETER User
The username or group name of the project to mirror.

.PARAMETER Group
The group name of the project to mirror.

.PARAMETER ApiKey
The API key for the destination instance.

.OUTPUTS
None. This cmdlet does not produce any output.

.EXAMPLE
Set-GitOrigin -Origin 'gitlab' -User 'user' -ApiKey 'apikey'

.EXAMPLE
Set-GitOrigin -Origin 'gitlab' -Group 'group' -ApiKey 'apikey'

.EXAMPLE
Set-GitOrigin -Origin 'gitlab' -Group 'group' -User 'user' -ApiKey 'apikey'

.EXAMPLE
Set-GitOrigin

.EXAMPLE
Set-GitOrigin -Origin 'gitlab'
#>

using module ..\..\ColorConsole\libs\cmdlets\New-ColorConsole.psm1

function Set-GitOrigin {
    [alias("glvso")]
    [cmdletbinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Origin,
        [Parameter(Mandatory = $false)]
        [string]$Group,
        [Parameter(Mandatory = $false)]
        [string]$User,
        [Parameter(Mandatory = $false)]
        [string]$ApiKey
    )

    process{
        try {
            [console]::write("$($global:_glvigor.log) starting gitlab origin add`n")

            # Support environment variable $ENV:GIT_HOST 
            if(!$ENV:GIT_HOST -and !$origin) { throw  "git host not set, set with $`ENV:GIT_HOST or -origin"}
            elseif($origin){ $origin = $origin}
            else{ $origin = $ENV:GIT_HOST }

            # Support environment variable $ENV:GIT_USER
            if(!$user -and $ENV:GIT_USER){ $user = $ENV:GIT_USER }
            else{ $user = $user }
            
            # # Support environment variable $ENV:GIT_USER for group namespace -group
            [string]$namespace = ''
            # Support environment variable $ENV:GIT_USER
            # if -param group and -param user not set and $ENV:GIT_USER is set use $ENV:GIT_USER
            if(!$group -and !$user -and $ENV:GIT_USER -ne ''){ $namespace = $ENV:GIT_USER }
            elseif($group){ $namespace = $Group }
            elseif(!$user -and $ENV:GIT_USER -and $group){ $namespace = $Group }
            elseif($user -and $group){ $namespace = $Group }
            elseif($user -and !$group){ $namespace = $User }
            else{
                throw "namespace not configured, configure with $`ENV:GIT_USER or -user or -group, by default $`ENV:GIT_USER or -user is used for group namespace"
            }
            
            [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.git_config)::($(csole -s "getting folder basename" -c white))`n")
            [string] $Repository = (Get-ItemProperty -Path .\ | select-Object baseName).BaseName
            $Repository = $Repository.ToLower()
            $url = "https://$user`:$ApiKey@$origin/$namespace/$Repository.git"
            $url_safe = "https://$user`:*****************@$origin/$namespace/$Repository.git"
            
            [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.git_config)::($(csole -s "git remote set-url origin" -c white))::$url_safe`n")
            git remote set-url origin $url | Out-Null # pull fetch

            [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.git_config)::($(csole -s "git remote set-url --push origin" -c yellow))::$url_safe`n")
            git remote set-url --push origin $url | Out-Null # push

            # [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.git_config)::($(csole -s "git remote get-url --all origin" -c magenta))::$url_safe`n")
            # git remote get-url --all origin

            # [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.git_config)::($(csole -s "git remote get-url --push origin" -c yellow))::$url_safe`n")
            # git remote get-url --push origin

            [console]::write("$($global:_glvigor.log) git origin update complete`n")
        }
        catch {
            [console]::write("$($global:_glvigor.logsub)$(csole -s ■ -c red)-error  $(csole -s $_.Exception.Message -c red)")
        }
    }
}

$cmdletconfig = @{
    function = @('Set-GitOrigin')
    alias = @('glvsgo')
}
Export-ModuleMember @cmdletconfig