# ==============================================================================
# File: Public/Register-GitBranch.ps1
# ==============================================================================
<#
.SYNOPSIS
Creates a new branch in a GitLab repository.

.DESCRIPTION
Sends a request to the GitLab API to create a new branch from a specified commit SHA or ref.

.PARAMETER Data
Pipeline input object containing project metadata.

.PARAMETER ProjectID
The ID of the project.

.PARAMETER BranchName
The name of the new branch to create.

.PARAMETER Ref
The commit SHA or existing branch name to branch from.

.PARAMETER Raw
Return raw REST response object.

.EXAMPLE
Register-GitBranch -ProjectID 123 -BranchName "feature/auth" -Ref "main"
#>
function Register-GitBranch {
    [CmdletBinding()]
    [Alias('glvrgbr')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$Data,

        [Parameter(Mandatory = $false)]
        [int]$ProjectID,

        [Parameter(Mandatory = $true)]
        [string]$BranchName,

        [Parameter(Mandatory = $true)]
        [string]$Ref,

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
            Write-GLVLog -Message "Creating branch '$BranchName' from '$Ref' in Project ID $($targetProjId)" -Level Api

            $headers = @{
                "Authorization" = "Bearer $($global:_glvigor.auth.apikey | Undo-SecureString)"
                "Content-Type"  = "application/json"
            }

            $body = @{
                branch = $BranchName
                ref    = $Ref
            }

            $jsonBody = $body | ConvertTo-Json -Depth 3
            $uri = "$($global:_glvigor.auth.apipath)/projects/$targetProjId/repository/branches"
            Write-GLVLog -Message "POST $uri" -Level Debug

            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $jsonBody
            Write-GLVLog -Message "Successfully created branch '$BranchName'." -Level Success

            if ($Raw) {
                return $response
            } else {
                return $response | Select-Object name, merged, protected, default, web_url
            }
        }
        catch {
            Write-GLVLog -Message "Failed to create branch '$BranchName' - $($_.Exception.Message)" -Level Error
        }
    }
}
