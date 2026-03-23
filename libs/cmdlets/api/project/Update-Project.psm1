using module ..\..\..\securestring\undo-securestring.psm1
using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\private\Confirm-GitLabAuth.psm1
<#
.SYNOPSIS
@SYNOPSIS
Updates a project via the Gitlab API.

.DESCRIPTION
This script is used to request the update of a GitLab project via the GitLab REST API.

.PARAMETER ProjectID
The ID of the project to update.

.PARAMETER name
The new name of the project.

.PARAMETER description
Optional new description of the project.

.PARAMETER visibility
The new visibility level of the project.

.PARAMETER DefaultBranch
The new default branch of the project.

.EXAMPLE
# Update a project
Update-Project -ProjectID 1 -name "my-new-project" -description "My updated project"

.NOTES
Requires a Gitlab personal access token with appropriate project update permissions.
#>

function Update-Project {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('glvup')]
    param (
        [Parameter(Mandatory = $true)]
        [int]$ProjectID,
        [Parameter(Mandatory = $false)]
        [string]$name,
        [Parameter(Mandatory = $false)]
        [string]$description,
        [Parameter(Mandatory = $false)]
        [ValidateSet('public', 'private', 'internal', IgnoreCase = $true)]
        [string]$visibility,
        [Parameter(Mandatory = $false)]
        [string]$DefaultBranch,
        [Parameter(Mandatory = $false)]
        [switch]$Raw
    )

    process {
        try {


            [console]::write("$($global:_glvigor.log) $($global:_glvigor.logcmds.run) $(csole -s 'api-project-update-put-request' -c $global:__glvigor.colorpallet.yellow)...`n")

            #=== AUTH AND PIPELINE DATA ===
            # call auth check
            confirm-GitLabAuth
            #=== AUTH AND PIPELINE DATA ===

            [console]::write("$($global:_glvigor.logsub) update project '$(csole -s "$ProjectID" -c $global:__glvigor.colorpallet.magenta)'`n")

            [hashtable]$requestBody = @{}

            if ($name) { $requestBody.name = $name }
            if ($description) { $requestBody.description = $description }
            if ($visibility) { $requestBody.visibility = $visibility }
            if ($DefaultBranch) { $requestBody.default_branch = $DefaultBranch }


            $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
            $http_header = @{
                'Content-Type'         = 'application/json'
                'Authorization'        = "Bearer $_gitlab_apikey"
            }

            [console]::write("$($global:_glvigor.logsub) $($global:_glvigor.logcmds.api_put) $($global:_glvigor.auth.apipath)/projects/$ProjectID`n")
            $response = Invoke-RestMethod -Uri "$($global:_glvigor.auth.apipath)/projects/$ProjectID" -Method Put -Headers $http_header -Body ($requestBody | ConvertTo-Json)

            [console]::write("$($global:_glvigor.logsub) project $(csole -s "$name" -c $global:__glvigor.colorpallet.magenta) updated`n")
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
    function = @('Update-Project')
    alias    = @('glvup')
}

Export-ModuleMember @cmdlet_config