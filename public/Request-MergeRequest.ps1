# ==============================================================================
# File: Public/Request-MergeRequest.ps1
# ==============================================================================
<#
.SYNOPSIS
Sends a request to the GitLab API to retrieve a merge request.

.DESCRIPTION
Sends a request to the GitLab API to retrieve a merge request by ProjectID and MergeRequestIID.

.PARAMETER ProjectID
The ID of the project.

.PARAMETER MergeRequestIID
The IID of the merge request.

.EXAMPLE
Request-MergeRequest -ProjectID 123 -MergeRequestIID 1
#>
function Request-MergeRequest {
    [CmdletBinding()]
    [Alias('glvrmr')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$Data,

        [Parameter(Mandatory = $false)]
        [int]$ProjectID,

        [Parameter(Mandatory = $false)]
        [int]$MergeRequestIID
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

        Write-GLVLog -Message "Fetching Merge Requests for Project ID: $targetProjId" -Level Api

        if (-not $global:_glvigor.auth -or -not $global:_glvigor.auth.apipath) {
            Write-GLVLog -Message "GitLab authentication token missing. Please run Request-GitLabAuth." -Level Error
            return
        }

        try {
            $uri = if ($MergeRequestIID -gt 0) {
                "$($global:_glvigor.auth.apipath)/projects/$targetProjId/merge_requests/$MergeRequestIID"
            } else {
                "$($global:_glvigor.auth.apipath)/projects/$targetProjId/merge_requests"
            }

            Write-GLVLog -Message "GET $uri" -Level Debug

            $headers = @{
                "Authorization" = "Bearer $($global:_glvigor.auth.apikey)"
                "Content-Type"  = "application/json"
            }

            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
            Write-GLVLog -Message "Successfully retrieved merge request data." -Level Success
            return $response
        }
        catch {
            Write-GLVLog -Message "Failed to fetch merge request: $($_.Exception.Message)" -Level Error
        }
    }
}
