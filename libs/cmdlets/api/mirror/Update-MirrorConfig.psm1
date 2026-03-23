using module ..\..\..\securestring\undo-securestring.psm1
using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\private\Confirm-GitLabAuth.psm1
<#
.SYNOPSIS
@SYNOPSIS
Updates a mirror configuration via the Gitlab API.

.DESCRIPTION
This script is used to request the update of a GitLab mirror configuration via the GitLab REST API.

.PARAMETER ProjectID
The ID of the project the mirror configuration belongs to.

.PARAMETER MirrorID
The ID of the mirror configuration to update.

.PARAMETER url
The new URL of the remote mirror.

.PARAMETER enabled
Whether the mirror is enabled.

.EXAMPLE
# Update a mirror configuration
Update-MirrorConfig -ProjectID 1 -MirrorID 1 -url "https://github.com/my/repo.git" -enabled $true

.NOTES
Requires a Gitlab personal access token with appropriate mirror configuration update permissions.
#>

function Update-MirrorConfig {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('glvumc')]
    param (
        [Parameter(Mandatory = $true)]
        [int]$ProjectID,
        [Parameter(Mandatory = $true)]
        [int]$MirrorID,
        [Parameter(Mandatory = $false)]
        [string]$url,
        [Parameter(Mandatory = $false)]
        [bool]$enabled,
        [Parameter(Mandatory = $false)]
        [switch]$Raw
    )

    process {
        try {


            [console]::write("$($global:_glvigor.log) $($global:_glvigor.logcmds.run) $(csole -s 'api-mirrorconfig-update-put-request' -c $global:__glvigor.colorpallet.yellow)...`n")

            #=== AUTH AND PIPELINE DATA ===
            # call auth check
            confirm-GitLabAuth
            #=== AUTH AND PIPELINE DATA ===

            [console]::write("$($global:_glvigor.logsub) update mirror configuration '$(csole -s "$MirrorID" -c $global:__glvigor.colorpallet.magenta)'`n")

            [hashtable]$requestBody = @{}

            if ($url) { $requestBody.url = $url }
            if ($enabled -ne $null) { $requestBody.enabled = $enabled }


            $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
            $http_header = @{
                'Content-Type'         = 'application/json'
                'Authorization'        = "Bearer $_gitlab_apikey"
            }

            [console]::write("$($global:_glvigor.logsub) $($global:_glvigor.logcmds.api_put) $($global:_glvigor.auth.apipath)/projects/$ProjectID/remote_mirrors/$MirrorID`n")
            $response = Invoke-RestMethod -Uri "$($global:_glvigor.auth.apipath)/projects/$ProjectID/remote_mirrors/$MirrorID" -Method Put -Headers $http_header -Body ($requestBody | ConvertTo-Json)

            [console]::write("$($global:_glvigor.logsub) mirror configuration $(csole -s "$MirrorID" -c $global:__glvigor.colorpallet.magenta) updated`n")
            [console]::write("$($global:_glvigor.logsublast)`n")

            if($raw){
                return $response
            }else{
                $filtered_response = [PSCustomObject]@{
                    id = $response.id
                    url = $response.url
                    enabled = $response.enabled
                    last_update_at = $response.last_update_at
                }
                return $filtered_response
            }

        }
        catch {
            [console]::write("`n$($global:_glvigor.logsub) $(csole -s '■─error:' -c $global:__glvigor.colorpallet.red) $($_.Exception.Message)`n")
            return $response
        }
    }

}

$cmdlet_config = @{
    function = @('Update-MirrorConfig')
    alias    = @('glvumc')
}

Export-ModuleMember @cmdlet_config