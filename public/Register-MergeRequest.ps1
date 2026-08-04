# ==============================================================================
# File: Public/Register-MergeRequest.ps1
# ==============================================================================
<#
.SYNOPSIS
Creates a new merge request via the GitLab API.

.DESCRIPTION
Creates a new GitLab merge request between a source branch and target branch.

.PARAMETER ProjectID
The ID of the project.

.PARAMETER SourceBranch
The source branch name.

.PARAMETER TargetBranch
The target branch name.

.PARAMETER Title
The title of the merge request.

.PARAMETER Description
Optional description of the merge request.

.PARAMETER Raw
Return raw REST response object.

.EXAMPLE
Register-MergeRequest -ProjectID 123 -SourceBranch "feature" -TargetBranch "main" -Title "New feature"
#>
function Register-MergeRequest {
    [CmdletBinding()]
    [Alias('glvrgmr')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$Data,

        [Parameter(Mandatory = $false)]
        [int]$ProjectID,

        [Parameter(Mandatory = $true)]
        [string]$SourceBranch,

        [Parameter(Mandatory = $true)]
        [string]$TargetBranch,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [string]$Description,

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

        Write-GLVLog -Message "Creating Merge Request '$Title' ($SourceBranch -> $TargetBranch) in Project ID: $targetProjId" -Level Api

        if (-not $global:_glvigor.auth -or -not $global:_glvigor.auth.apipath) {
            Write-GLVLog -Message "GitLab authentication token missing. Please run Request-GitLabAuth." -Level Error
            return
        }

        try {
            $body = @{
                source_branch = $SourceBranch
                target_branch = $TargetBranch
                title         = $Title
            }

            if ($Description) { $body['description'] = $Description }

            $jsonBody = $body | ConvertTo-Json -Depth 3

            $uri = "$($global:_glvigor.auth.apipath)/projects/$targetProjId/merge_requests"
            Write-GLVLog -Message "POST $uri" -Level Debug

            $headers = @{
                "Authorization" = "Bearer $($global:_glvigor.auth.apikey)"
                "Content-Type"  = "application/json"
            }

            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $jsonBody
            Write-GLVLog -Message "Successfully created Merge Request !($response.iid): $($response.title)" -Level Success

            if ($Raw) {
                return $response
            } else {
                return $response | Select-Object iid, title, source_branch, target_branch, state, web_url
            }
        }
        catch {
            Write-GLVLog -Message "Failed to create merge request: $($_.Exception.Message)" -Level Error
        }
    }
}
