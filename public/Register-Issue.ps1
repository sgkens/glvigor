# ==============================================================================
# File: Public/Register-Issue.ps1
# ==============================================================================
<#
.SYNOPSIS
Sends a request to the GitLab API to create an issue for a project.

.DESCRIPTION
Sends a request to the GitLab API to create an issue for a project with optional parameters.

.PARAMETER ProjectID
The ID of the project.

.PARAMETER Title
The title of the issue.

.PARAMETER Description
The description of the issue.

.PARAMETER Type
The type of issue: issue, incident, task.

.PARAMETER MilestoneID
The ID of the milestone.

.PARAMETER AssigneeID
The ID of the assignee user.

.PARAMETER Labels
Array of label names.

.PARAMETER Confidential
Switch to mark issue confidential.

.EXAMPLE
Register-Issue -ProjectID 123 -Title "Bug in login screen" -Description "Fix login bug"
#>
function Register-Issue {
    [CmdletBinding()]
    [Alias('glvri')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$Data,

        [Parameter(Mandatory = $false)]
        [int]$ProjectID,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [ValidateSet('issue', 'incident', 'task', IgnoreCase = $true)]
        [string]$Type = 'issue',

        [Parameter(Mandatory = $false)]
        [int]$MilestoneID,

        [Parameter(Mandatory = $false)]
        [int]$AssigneeID,

        [Parameter(Mandatory = $false)]
        [string[]]$Labels,

        [Parameter(Mandatory = $false)]
        [switch]$Confidential
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

        Write-GLVLog -Message "Creating issue '$Title' in Project ID: $targetProjId" -Level Api

        if (-not $global:_glvigor.auth -or -not $global:_glvigor.auth.apipath) {
            Write-GLVLog -Message "GitLab authentication token missing. Please run Request-GitLabAuth." -Level Error
            return
        }

        Assert-GLVProjectOwnerScope -ProjectID $targetProjId

        try {
            $body = @{
                title        = $Title
                issue_type   = $Type
                confidential = $Confidential.IsPresent
            }

            if ($Description) { $body['description'] = $Description }
            if ($MilestoneID -gt 0) { $body['milestone_id'] = $MilestoneID }
            if ($AssigneeID -gt 0) { $body['assignee_id'] = $AssigneeID }
            if ($Labels) { $body['labels'] = ($Labels -join ',') }

            $jsonBody = $body | ConvertTo-Json -Depth 3

            $uri = "$($global:_glvigor.auth.apipath)/projects/$targetProjId/issues"
            Write-GLVLog -Message "POST $uri" -Level Debug

            $headers = @{
                "Authorization" = "Bearer $($global:_glvigor.auth.apikey | Undo-SecureString)"
                "Content-Type"  = "application/json"
            }

            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $jsonBody
            Write-GLVLog -Message "Successfully created issue #$($response.iid): $($response.title)" -Level Success
            return $response
        }
        catch {
            Write-GLVLog -Message "Failed to create issue: $($_.Exception.Message)" -Level Error
        }
    }
}
