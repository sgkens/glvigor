# ==============================================================================
# File: Public/Request-GitBranch.ps1
# ==============================================================================
<#
.SYNOPSIS
Retrieves branches for a GitLab repository.

.DESCRIPTION
Retrieves a list of branches or details for a single branch from a specified GitLab project.

.PARAMETER Data
Pipeline input object containing project metadata.

.PARAMETER ProjectID
The ID of the project.

.PARAMETER BranchName
Optional branch name to filter for a single branch.

.PARAMETER Search
Optional search query to filter branches by name.

.PARAMETER Raw
Return raw REST response object.

.EXAMPLE
Request-GitBranch -ProjectID 123

.EXAMPLE
Request-GitBranch -ProjectID 123 -BranchName "main"
#>
function Request-GitBranch {
    [CmdletBinding()]
    [Alias('glvrqbr')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$Data,

        [Parameter(Mandatory = $false)]
        [int]$ProjectID,

        [Parameter(Mandatory = $false)]
        [string]$BranchName,

        [Parameter(Mandatory = $false)]
        [string]$Search,

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
            $headers = @{
                "Authorization" = "Bearer $($global:_glvigor.auth.apikey | Undo-SecureString)"
                "Content-Type"  = "application/json"
            }

            if ($BranchName) {
                $encodedBranch = [System.Web.HttpUtility]::UrlEncode($BranchName)
                $uri = "$($global:_glvigor.auth.apipath)/projects/$targetProjId/repository/branches/$encodedBranch"
                Write-GLVLog -Message "GET $uri" -Level Debug
                $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
                Write-GLVLog -Message "Successfully retrieved branch '$BranchName'." -Level Success
            }
            else {
                $queryString = if ($Search) { "?search=$([System.Web.HttpUtility]::UrlEncode($Search))" } else { "" }
                $uri = "$($global:_glvigor.auth.apipath)/projects/$targetProjId/repository/branches$queryString"
                Write-GLVLog -Message "GET $uri" -Level Debug
                $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
                Write-GLVLog -Message "Successfully retrieved $($response.Count) branches." -Level Success
            }

            if ($Raw) {
                return $response
            } else {
                if ($response -is [array]) {
                    return $response | Select-Object name, merged, protected, default, web_url
                } else {
                    return $response | Select-Object name, merged, protected, default, web_url
                }
            }
        }
        catch {
            Write-GLVLog -Message "Failed to retrieve branches: $($_.Exception.Message)" -Level Error
        }
    }
}
