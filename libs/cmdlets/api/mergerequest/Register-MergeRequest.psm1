using module ..\..\..\securestring\undo-securestring.psm1
using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\private\Confirm-GitLabAuth.psm1
<#
.SYNOPSIS
@SYNOPSIS
Creates a new merge request via the Gitlab API.

.DESCRIPTION
This script is used to request the creation of a new Gitlub merge request via the Gitlab REST API.

.PARAMETER ProjectID
The ID of the project to create the merge request in.

.PARAMETER SourceBranch
The source branch of the merge request.

.PARAMETER TargetBranch
The target branch of the merge request.

.PARAMETER Title
The title of the merge request.

.PARAMETER description
Optional description of the merge request.

.EXAMPLE
# Create a new merge request
Register-MergeRequest -ProjectID 1 -SourceBranch "feature" -TargetBranch "main" -Title "My new merge request"

.NOTES
Requires a Gitlab personal access token with appropriate merge request creation permissions.
#>

function Register-MergeRequest {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('glvrmr')]
    param (
        [Parameter(Mandatory = $true)]
        [int]$ProjectID,
        [Parameter(Mandatory = $true)]
        [string]$SourceBranch,
        [Parameter(Mandatory = $true)]
        [string]$TargetBranch,
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [Parameter(Mandatory = $false)]
        [string]$description,
        [Parameter(Mandatory = $false)]
        [switch]$Raw
    )

    process {
        try {


            [console]::write("$($global:_glvigor.log) $($global:_glvigor.logcmds.run) $(csole -s 'api-mergerequest-creation-post-request' -c yellow)...`n")

            #=== AUTH AND PIPELINE DATA ===
            # call auth check
            confirm-GitLabAuth
            #=== AUTH AND PIPELINE DATA ===

            [console]::write("$($global:_glvigor.logsub) create merge request '$(csole -s "$Title" -c magenta)'`n")

            [hashtable]$requestBody = @{
                source_branch = $SourceBranch
                target_branch = $TargetBranch
                title         = $Title
            }

            if ($description) { $requestBody.description = $description }

            $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
            $http_header = @{
                'Content-Type'         = 'application/json'
                'Authorization'        = "Bearer $_gitlab_apikey"
            }

            [console]::write("$($global:_glvigor.logsub) $($global:_glvigor.logcmds.api_post) $($global:_glvigor.auth.apipath)/projects/$ProjectID/merge_requests`n")
            $response = Invoke-RestMethod -Uri "$($global:_glvigor.auth.apipath)/projects/$ProjectID/merge_requests" -Method Post -Headers $http_header -Body ($requestBody | ConvertTo-Json)

            [console]::write("$($global:_glvigor.logsub) merge request $(csole -s "$Title" -c magenta) created`n")
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
            [console]::write("`n$($global:_glvigor.logsub) $(csole -s '■─error:' -c red) $($_.Exception.Message)`n")
            return $response
        }
    }

}

$cmdlet_config = @{
    function = @('Register-MergeRequest')
    alias    = @('glvrmr')
}

Export-ModuleMember @cmdlet_config