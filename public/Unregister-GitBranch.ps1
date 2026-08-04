# ==============================================================================
# File: Public/Unregister-GitBranch.ps1
# ==============================================================================
<#
.SYNOPSIS
Deletes a branch from a GitLab repository.

.DESCRIPTION
Sends a DELETE request to the GitLab API to remove a branch from a specified project.

.PARAMETER Data
Pipeline input object containing project metadata.

.PARAMETER ProjectID
The ID of the project.

.PARAMETER BranchName
The name of the branch to delete.

.PARAMETER Raw
Return raw REST response object.

.EXAMPLE
Unregister-GitBranch -ProjectID 123 -BranchName "feature/auth"
#>
function Unregister-GitBranch {
    [CmdletBinding()]
    [Alias('glvrmbr')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$Data,

        [Parameter(Mandatory = $false)]
        [int]$ProjectID,

        [Parameter(Mandatory = $true)]
        [string]$BranchName,

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

        Assert-GLVProjectOwnerScope -ProjectID $targetProjId

        try {
            Write-GLVLog -Message "Deleting branch '$BranchName' from Project ID $($targetProjId)" -Level Api

            $headers = @{
                "Authorization" = "Bearer $($global:_glvigor.auth.apikey | Undo-SecureString)"
                "Content-Type"  = "application/json"
            }

            $encodedBranch = [System.Web.HttpUtility]::UrlEncode($BranchName)
            $uri = "$($global:_glvigor.auth.apipath)/projects/$targetProjId/repository/branches/$encodedBranch"
            Write-GLVLog -Message "DELETE $uri" -Level Debug

            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Delete
            Write-GLVLog -Message "Successfully deleted branch '$BranchName'." -Level Success

            if ($Raw) {
                return $response
            } else {
                return [PSCustomObject]@{
                    ProjectID  = $targetProjId
                    BranchName = $BranchName
                    Status     = 'Deleted'
                }
            }
        }
        catch {
            Write-GLVLog -Message "Failed to delete branch '$BranchName' - $($_.Exception.Message)" -Level Error
        }
    }
}
