using module ..\..\..\securestring\undo-securestring.psm1
using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\private\Confirm-GitLabAuth.psm1
<#
.SYNOPSIS
@SYNOPSIS
Updates a new merge request via the Gitlab API.

.DESCRIPTION
This script is used to request the update of a new Gitlub merge request via the Gitlab REST API.

.PARAMETER ProjectID
The ID of the project to update the merge request in.

.PARAMETER MergeRequestIID
The IID of the merge request to update.

.PARAMETER Title
The new title of the merge request.

.PARAMETER description
Optional new description of the merge request.

.EXAMPLE
# Update a merge request
Update-MergeRequest -ProjectID 1 -MergeRequestIID 1 -Title "My new title"

.NOTES
Requires a Gitlab personal access token with appropriate merge request creation permissions.
#>

function Update-MergeRequest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('glvumr')]
    param (
        [Parameter(Mandatory = $true)]
        [int]$ProjectID,
        [Parameter(Mandatory = $true)]
        [int]$MergeRequestIID,
        [Parameter(Mandatory = $false)]
        [string]$Title,
        [Parameter(Mandatory = $false)]
        [string]$description,
        [Parameter(Mandatory = $false)]
        [switch]$Raw
    )

    process {
        try {


            [console]::write("$($global:_glvigor.log) $($global:_glvigor.logcmds.run) $(csole -s 'api-mergerequest-update-put-request' -c $global:__glvigor.colorpallet.yellow)...`n")

            #=== AUTH AND PIPELINE DATA ===
            # call auth check
            confirm-GitLabAuth
            #=== AUTH AND PIPELINE DATA ===

            [console]::write("$($global:_glvigor.logsub) update merge request '$(csole -s "$MergeRequestIID" -c $global:__glvigor.colorpallet.magenta)'`n")

            [hashtable]$requestBody = @{}

            if ($Title) { $requestBody.title = $Title }
            if ($description) { $requestBody.description = $description }


            $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
            $http_header = @{
                'Content-Type'         = 'application/json'
                'Authorization'        = "Bearer $_gitlab_apikey"
            }

            [console]::write("$($global:_glvigor.logsub) $($global:_glvigor.logcmds.api_put) $($global:_glvigor.auth.apipath)/projects/$ProjectID/merge_requests/$MergeRequestIID`n")
            $response = Invoke-RestMethod -Uri "$($global:_glvigor.auth.apipath)/projects/$ProjectID/merge_requests/$MergeRequestIID" -Method Put -Headers $http_header -Body ($requestBody | ConvertTo-Json)

            [console]::write("$($global:_glvigor.logsub) merge request $(csole -s "$Title" -c $global:__glvigor.colorpallet.magenta) updated`n")
            [console]::write("$($global:_glvigor.logsublast)`n")

            if($raw){
                return $response
            }else{
                $filtered_response = [PSCustomObject]@{
                    title = $response.title
                    id = $response.id
                    iid = $response.iid
                    description = $response.description
                    state = $response.state
                    created_at = $response.created_at
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
    function = @('Update-MergeRequest')
    alias    = @('glvumr')
}

Export-ModuleMember @cmdlet_config