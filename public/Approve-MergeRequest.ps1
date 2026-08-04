# ==============================================================================
# File: Public/Approve-MergeRequest.ps1
# ==============================================================================
<#
.SYNOPSIS
Approves or merges a merge request via the GitLab API.

.DESCRIPTION
Sends a request to the GitLab API to approve or merge an open merge request.

.PARAMETER Data
Pipeline input object containing project or merge request metadata.

.PARAMETER ProjectID
The ID of the project.

.PARAMETER MergeRequestIID
The IID of the merge request.

.PARAMETER ApproveOnly
If specified, only approves the MR without merging it.

.PARAMETER MergeCommitMessage
Custom merge commit message.

.PARAMETER ShouldRemoveSourceBranch
If specified, removes the source branch upon merge.

.PARAMETER MergeWhenPipelineSucceeds
If specified, sets the merge request to merge when pipeline succeeds.

.PARAMETER Raw
Return raw REST response object.

.EXAMPLE
Approve-MergeRequest -ProjectID 123 -MergeRequestIID 5 -ShouldRemoveSourceBranch

.EXAMPLE
Approve-MergeRequest -ProjectID 123 -MergeRequestIID 5 -ApproveOnly
#>
function Approve-MergeRequest {
    [CmdletBinding()]
    [Alias('glvapmr')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$Data,

        [Parameter(Mandatory = $false)]
        [int]$ProjectID,

        [Parameter(Mandatory = $true)]
        [int]$MergeRequestIID,

        [Parameter(Mandatory = $false)]
        [switch]$ApproveOnly,

        [Parameter(Mandatory = $false)]
        [string]$MergeCommitMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ShouldRemoveSourceBranch,

        [Parameter(Mandatory = $false)]
        [switch]$MergeWhenPipelineSucceeds,

        [Parameter(Mandatory = $false)]
        [switch]$Raw
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
    }

    process {
        $targetProjId = $ProjectID
        if ($Data) {
            if ($Data.PSObject.Properties['project_id']) { $targetProjId = $Data.project_id }
            elseif ($Data.PSObject.Properties['id']) { $targetProjId = $Data.id }
        }

        if (-not $targetProjId -or $targetProjId -le 0) {
            Write-GLVLog -Message "Missing valid ProjectID parameter or pipeline object." -Level Error
            return
        }

        if (-not $global:_glvigor.auth -or -not $global:_glvigor.auth.apipath) {
            Write-GLVLog -Message "GitLab authentication token missing. Please run Request-GitLabAuth." -Level Error
            return
        }

        try {
            $headers = @{
                "Authorization" = "Bearer $($global:_glvigor.auth.apikey)"
                "Content-Type"  = "application/json"
            }

            if ($ApproveOnly) {
                Write-GLVLog -Message "Approving Merge Request !($MergeRequestIID) in Project ID $($targetProjId)" -Level Api
                $uri = "$($global:_glvigor.auth.apipath)/projects/$targetProjId/merge_requests/$MergeRequestIID/approve"
                Write-GLVLog -Message "POST $uri" -Level Debug
                $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post
                Write-GLVLog -Message "Successfully approved Merge Request !($MergeRequestIID)." -Level Success
            }
            else {
                Write-GLVLog -Message "Merging Merge Request !($MergeRequestIID) in Project ID $($targetProjId)" -Level Api
                $uri = "$($global:_glvigor.auth.apipath)/projects/$targetProjId/merge_requests/$MergeRequestIID/merge"
                Write-GLVLog -Message "PUT $uri" -Level Debug

                $body = @{}
                if ($MergeCommitMessage) { $body['merge_commit_message'] = $MergeCommitMessage }
                if ($ShouldRemoveSourceBranch) { $body['should_remove_source_branch'] = $true }
                if ($MergeWhenPipelineSucceeds) { $body['merge_when_pipeline_succeeds'] = $true }

                $jsonBody = $body | ConvertTo-Json -Depth 3
                $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Put -Body $jsonBody
                Write-GLVLog -Message "Successfully executed merge on MR !($MergeRequestIID) state=$($response.state)" -Level Success
            }

            if ($Raw) {
                return $response
            } else {
                return $response | Select-Object iid, title, state, source_branch, target_branch, web_url
            }
        }
        catch {
            Write-GLVLog -Message "Failed to process Merge Request !($MergeRequestIID) - $($_.Exception.Message)" -Level Error
        }
    }
}
