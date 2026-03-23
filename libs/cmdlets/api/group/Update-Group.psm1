using module ..\..\..\securestring\undo-securestring.psm1
using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\private\Confirm-GitLabAuth.psm1
<#
.SYNOPSIS
@SYNOPSIS
Updates a new group via the Gitlab API.

.DESCRIPTION
This script is used to request the update of a new Gitlub group via the Gitlab REST API.

.PARAMETER GroupID
The ID of the group to update.

.PARAMETER name
The new name of the group.

.PARAMETER path
The new path of the group.

.PARAMETER description
Optional new description of the group.

.EXAMPLE
# Update a group
Update-Group -GroupID 1 -name "my-group" -path "my-group" -description "My new group"

.NOTES
Requires a Gitlab personal access token with appropriate group creation permissions.
#>

function Update-Group {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('glvug')]
    param (
        [Parameter(Mandatory = $true)]
        [int]$GroupID,
        [Parameter(Mandatory = $false)]
        [string]$name,
        [Parameter(Mandatory = $false)]
        [string]$path,
        [Parameter(Mandatory = $false)]
        [string]$description,
        [Parameter(Mandatory = $false)]
        [ValidateSet('public', 'private', 'internal', IgnoreCase = $true)]
        [string]$visibility,
        [Parameter(Mandatory = $false)]
        [switch]$Raw
    )

    process {
        try {


            [console]::write("$($global:_glvigor.log) $($global:_glvigor.logcmds.run) $(csole -s 'api-group-update-put-request' -c $global:__glvigor.colorpallet.yellow)...`n")

            #=== AUTH AND PIPELINE DATA ===
            # call auth check
            confirm-GitLabAuth
            #=== AUTH AND PIPELINE DATA ===

            [console]::write("$($global:_glvigor.logsub) update group '$(csole -s "$GroupID" -c $global:__glvigor.colorpallet.magenta)'`n")

            [hashtable]$requestBody = @{}

            if ($name) { $requestBody.name = $name }
            if ($path) { $requestBody.path = $path }
            if ($description) { $requestBody.description = $description }
            if ($visibility) { $requestBody.visibility = $visibility }


            $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
            $http_header = @{
                'Content-Type'         = 'application/json'
                'Authorization'        = "Bearer $_gitlab_apikey"
            }

            [console]::write("$($global:_glvigor.logsub) $($global:_glvigor.logcmds.api_put) $($global:_glvigor.auth.apipath)/groups/$GroupID`n")
            $response = Invoke-RestMethod -Uri "$($global:_glvigor.auth.apipath)/groups/$GroupID" -Method Put -Headers $http_header -Body ($requestBody | ConvertTo-Json)

            [console]::write("$($global:_glvigor.logsub) group $(csole -s "$name" -c $global:__glvigor.colorpallet.magenta) updated`n")
            [console]::write("$($global:_glvigor.logsublast)`n")

            if($raw){
                return $response
            }else{
                $filtered_response = [PSCustomObject]@{
                    name = $response.name
                    id = $response.id
                    description = $response.description
                    created_at = $response.created_at
                    name_with_namespace = $response.name_with_namespace
                    path_with_namespace = $response.path_with_namespace
                    web_url = $response.web_url
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
    function = @('Update-Group')
    alias    = @('glvug')
}

Export-ModuleMember @cmdlet_config