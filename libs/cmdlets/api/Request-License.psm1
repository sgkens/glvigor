using module ..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module .\private\Confirm-GitLabAuth.psm1
using module ..\..\securestring\undo-securestring.psm1

function Request-License {

    [CmdletBinding()]
    [Alias('glvrl')]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Type,
        [Parameter(Mandatory = $false)]
        [string]$Author,
        [Parameter(Mandatory = $false)]
        [switch]$SaveToFile = $false
    )
    process {
        try {

            [console]::write("$($global:_glvigor.log)$($global:_glvigor.logcmds.run) $(csole -s 'api-license-get-request' -c $global:__glvigor.colorpallet.yellow)...`n")
            
            # call auth check
            confirm-GitLabAuth

            if(!$author){
                $author = $global:_glvigor.auth.user
            }

            $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", "Bearer $_gitlab_apikey")
            $headers.Add("Content-Type", "application/json")
            $request_licensetemplate = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/templates/licenses?page=1&per_page=100" -headers $headers
            [console]::write("$($global:_glvigor.logsub) $($global:_glvigor.logcmds.api_get)::$($global:_glvigor.auth.apipath)/templates/licenses`n")
            if ($SaveToFile) {
                [console]::write("$($global:_glvigor.logsub) saving to file $(csole -s 'LICENSE' -c $global:__glvigor.colorpallet.magenta)...`n")
                $request_licensetemplate | Out-File -FilePath "$($SaveToFile)/LICENSE"
            }
        
            if (!$Type) {
                [console]::write("$($global:_glvigor.logsub) $(csole -s "fetching all license templates" -c $global:__glvigor.colorpallet.green)`n")
                [console]::write("$($global:_glvigor.logsublast)") 
                return $request_licensetemplate 
            }
            else { 
                [console]::write("$($global:_glvigor.logsub) $(csole -s "fetching license template $(csole -s $Type -c $global:__glvigor.colorpallet.magenta)" -c $global:__glvigor.colorpallet.green)`n")
                [console]::write("$($global:_glvigor.logsublast)`n")
                [string]$populated_license = $request_licensetemplate.where({ $_.key -eq $Type }).content
                $populated_license = $populated_license -replace '\[fullname\]', $author -replace '\[year\]', (Get-Date).Year.tostring()                                 
                return $populated_license
            }
        }
        catch {
            [console]::write("$($global:_glvigor.logsub) $(csole -s $_.Exception.Message -c $global:__glvigor.colorpallet.red)`n")
        }
    }
}

$cmdlet_config = @{
    function = @('Request-License')
    alias    = @('glvrl')
}

Export-ModuleMember @cmdlet_config