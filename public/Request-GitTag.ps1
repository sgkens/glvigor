# ==============================================================================
# File: Public/Request-GitTag.ps1
# ==============================================================================
<#
.SYNOPSIS
Retrieves repository tags from the GitLab API.

.DESCRIPTION
Retrieves tags for a specified GitLab repository project.

.PARAMETER ProjectID
The ID of the project.

.PARAMETER TagName
Optional specific tag name.

.EXAMPLE
Request-GitTag -ProjectID 123
#>
function Request-GitTag {
    [CmdletBinding()]
    [Alias('glvrgt')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$Data,

        [Parameter(Mandatory = $false)]
        [int]$ProjectID,

        [Parameter(Mandatory = $false)]
        [string]$TagName
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

        Write-GLVLog -Message "Fetching repository tags for Project ID: $targetProjId" -Level Api

        if (-not $global:_glvigor.auth -or -not $global:_glvigor.auth.apipath) {
            Write-GLVLog -Message "GitLab authentication token missing. Please run Request-GitLabAuth." -Level Error
            return
        }

        try {
            $uri = if ($TagName) {
                "$($global:_glvigor.auth.apipath)/projects/$targetProjId/repository/tags/$TagName"
            } else {
                "$($global:_glvigor.auth.apipath)/projects/$targetProjId/repository/tags"
            }

            Write-GLVLog -Message "GET $uri" -Level Debug

            $headers = @{
                "Authorization" = "Bearer $($global:_glvigor.auth.apikey)"
                "Content-Type"  = "application/json"
            }

            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
            Write-GLVLog -Message "Successfully retrieved tag data." -Level Success
            return $response
        }
        catch {
            Write-GLVLog -Message "Failed to fetch repository tags: $($_.Exception.Message)" -Level Error
        }
    }
}
