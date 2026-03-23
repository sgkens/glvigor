using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
# private cmdlet for auth check and confirmation
function confirm-gitlabauth {
    [cmdletbinding()]
    [OutputType('void')]
    param()
    process {
        [console]::write("$($global:_glvigor.logSubRun)$($global:_glvigor.logcmds.run) authentication status`n")
        #  if null write error to console then break
        # http _glvigor.auth.httpstatus will not be set if not authenticated see Request-GitLabAuth
        if($null -eq $global:_glvigor.auth.httpstatus) {
            [console]::write("$($global:_glvigor.logsub) error => $(csole -s 'not authenticated, use request-gitlabauth to authenticate' -c $global:__glvigor.colorpallet.red)`n")
            break;
        }
        # !unsure if auth logic will make it here because auth throws if not 200 statis code
        # if $global:_glvigor.auth.httpstatus is not 200 write error to console then break
        elseif($global:_glvigor.auth.httpstatus -eq 404) {
            [console]::write("$($global:_glvigor.logSub) error => $(csole -s "Unable to establish a connection to:$($global:_glvigor.auth) " -c $global:__glvigor.colorpallet.red)`n")
            break;
        }
        # if auth is successfull and returns a payload with required fields write success to console and continue
        else{
            [console]::write("$($global:_glvigor.logSub) impersonate $(csole -s "user •─$($global:_glvigor.auth.id)-<👤>-$($global:_glvigor.auth.user)" -c $global:__glvigor.colorpallet.green)`n")
        }
    }
}

$cmdletconfig = @{ 
    function = @('confirm-gitlabauth') 
}

Export-ModuleMember @cmdletconfig