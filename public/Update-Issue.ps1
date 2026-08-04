


<#
.SYNOPSIS
@SYNOPSIS
Updates an issue via the Gitlab API.

.DESCRIPTION
This script is used to request the update of a GitLab issue via the GitLab REST API.

.PARAMETER ProjectID
The ID of the project the issue belongs to.

.PARAMETER IssueIID
The IID of the issue to update.

.PARAMETER Title
The new title of the issue.

.PARAMETER description
Optional new description of the issue.

.PARAMETER state_event
The new state event of the issue (close, reopen).

.EXAMPLE
# Update an issue
Update-Issue -ProjectID 1 -IssueIID 1 -Title "My updated issue" -description "Updated description"

.NOTES
Requires a Gitlab personal access token with appropriate issue update permissions.
#>

function Update-Issue {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('glvui')]
    param (
        [Parameter(Mandatory = $true)]
        [int]$ProjectID,
        [Parameter(Mandatory = $true)]
        [int]$IssueIID,
        [Parameter(Mandatory = $false)]
        [string]$Title,
        [Parameter(Mandatory = $false)]
        [string]$description,
        [Parameter(Mandatory = $false)]
        [ValidateSet('close', 'reopen', IgnoreCase = $true)]
        [string]$state_event,
        [Parameter(Mandatory = $false)]
        [switch]$Raw
    )

    process {
        try {


            [console]::write("$($global:_glvigor.log) $($global:_glvigor.logcmds.run) $(csole -s 'api-issue-update-put-request' -c $global:__glvigor.colorpallet.yellow)...`n")

            #=== AUTH AND PIPELINE DATA ===
            # call auth check
            Confirm-GitLabAuth
            #=== AUTH AND PIPELINE DATA ===

            [console]::write("$($global:_glvigor.logsub) update issue '$(csole -s "$IssueIID" -c $global:__glvigor.colorpallet.magenta)'`n")

            [hashtable]$requestBody = @{}

            if ($Title) { $requestBody.title = $Title }
            if ($description) { $requestBody.description = $description }
            if ($state_event) { $requestBody.state_event = $state_event }


            $_gitlab_apikey = $global:_glvigor.auth.apikey | Undo-SecureString
            $http_header = @{
                'Content-Type'         = 'application/json'
                'Authorization'        = "Bearer $_gitlab_apikey"
            }

            [console]::write("$($global:_glvigor.logsub) $($global:_glvigor.logcmds.api_put) $($global:_glvigor.auth.apipath)/projects/$ProjectID/issues/$IssueIID`n")
            $response = Invoke-RestMethod -Uri "$($global:_glvigor.auth.apipath)/projects/$ProjectID/issues/$IssueIID" -Method Put -Headers $http_header -Body ($requestBody | ConvertTo-Json)

            [console]::write("$($global:_glvigor.logsub) issue $(csole -s "$Title" -c $global:__glvigor.colorpallet.magenta) updated`n")
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
    function = @('Update-Issue')
    alias    = @('glvui')
}

Export-ModuleMember @cmdlet_config
