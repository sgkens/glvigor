# ==============================================================================
# File: Public/Request-Issue.ps1
# ==============================================================================
function Request-Issue {
    <#
    .SYNOPSIS
    Sends a request to the GitLab API to retrieve issues for a project.

    .DESCRIPTION
    Sends a request to the GitLab API to retrieve issues for a project, filtered by IssueID, State, Labels, or Milestone.

    .PARAMETER Data
    Pipeline input object containing project or issue metadata.

    .PARAMETER IssueID
    The IID of the issue to retrieve.

    .PARAMETER ProjectID
    The ID of the project.

    .PARAMETER State
    Filter by issue state: opened, closed, active, all.

    .PARAMETER Labels
    Filter by array of labels.

    .PARAMETER Milestone
    Filter by milestone title.

    .PARAMETER Raw
    Return raw REST response object.

    .EXAMPLE
    Request-Issue -ProjectID 123 -IssueID 2
    #>
    [CmdletBinding()]
    [Alias('glvrqi')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$Data,

        [Parameter(Mandatory = $false)]
        [int]$IssueID,

        [Parameter(Mandatory = $false)]
        [int]$ProjectID,

        [Parameter(Mandatory = $false)]
        [ValidateSet('opened', 'closed', 'active', 'all', IgnoreCase = $true)]
        [string]$State = 'all',

        [Parameter(Mandatory = $false)]
        [string[]]$Labels,

        [Parameter(Mandatory = $false)]
        [string]$Milestone,

        [Parameter(Mandatory = $false)]
        [switch]$Raw
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
    }

    process {
        # Determine target project ID from Pipeline or Parameter
        $targetProjId = $ProjectID
        if ($Data) {
            if ($Data.PSObject.Properties['project_id']) { $targetProjId = $Data.project_id }
            elseif ($Data.PSObject.Properties['id']) { $targetProjId = $Data.id }
        }

        if (-not $targetProjId -or $targetProjId -le 0) {
            Write-GLVLog -Message "Missing valid ProjectID parameter or pipeline object." -Level Error
            return
        }

        Write-GLVLog -Message "Querying issues for Project ID: $targetProjId" -Level Api

        if (-not $global:_glvigor.auth -or -not $global:_glvigor.auth.apipath) {
            Write-GLVLog -Message "GitLab authentication token missing. Please run Request-GitLabAuth." -Level Error
            return
        }

        try {
            # Build Query Parameters
            $queryParams = [System.Collections.Generic.List[string]]::new()
            if ($State -and $State -ne 'all') { $queryParams.Add("state=$State") }
            if ($Labels) { $queryParams.Add("labels=$([string]::Join(',', $Labels))") }
            if ($Milestone) { $queryParams.Add("milestone=$([System.Web.HttpUtility]::UrlEncode($Milestone))") }

            $queryString = if ($queryParams.Count -gt 0) { "?" + ($queryParams -join "&") } else { "" }

            $uri = if ($IssueID -gt 0) {
                "$($global:_glvigor.auth.apipath)/projects/$targetProjId/issues/$IssueID"
            } else {
                "$($global:_glvigor.auth.apipath)/projects/$targetProjId/issues$queryString"
            }

            Write-GLVLog -Message "GET $uri" -Level Debug

            $headers = @{
                "Authorization" = "Bearer $($global:_glvigor.auth.apikey)"
                "Content-Type"  = "application/json"
            }

            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

            if (-not $response) {
                Write-GLVLog -Message "No issues found." -Level Warning
                return
            }

            Write-GLVLog -Message "Successfully retrieved issue data." -Level Success

            if ($Raw) {
                return $response
            }
            else {
                if ($response -is [array]) {
                    return $response | Select-Object iid, title, state, labels, web_url
                } else {
                    return $response | Select-Object iid, title, state, labels, web_url
                }
            }
        }
        catch {
            Write-GLVLog -Message "Failed to retrieve issues: $($_.Exception.Message)" -Level Error
        }
    }
}
