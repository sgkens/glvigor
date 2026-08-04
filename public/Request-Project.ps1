# ==============================================================================
# File: Public/Request-Project.ps1
# ==============================================================================
<#
.SYNOPSIS
Sends a request to the GitLab API to retrieve a project.

.DESCRIPTION
Sends a request to the GitLab API to retrieve a project by numeric ID or auto-discovered local git context.

.PARAMETER ProjectID
The ID or path of the project to retrieve.

.EXAMPLE
Request-Project -ProjectID 123
Request-Project
#>
function Request-Project {
    [CmdletBinding()]
    [Alias('glvrp')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [object]$ProjectID
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
    }

    process {
        $targetProj = $ProjectID
        if (-not $targetProj) {
            $gitCtx = Get-GitContext
            if ($gitCtx) {
                $targetProj = [System.Web.HttpUtility]::UrlEncode($gitCtx.ProjectPath)
                Write-GLVLog -Message "Auto-discovered local git project path: '$($gitCtx.ProjectPath)'" -Level Info
            }
        }

        if (-not $targetProj) {
            Write-GLVLog -Message "Missing ProjectID parameter and no local .git context found." -Level Error
            return
        }

        Write-GLVLog -Message "Fetching project: $targetProj" -Level Api

        if (-not $global:_glvigor.auth -or -not $global:_glvigor.auth.apipath) {
            Write-GLVLog -Message "GitLab authentication token missing. Please run Request-GitLabAuth." -Level Error
            return
        }

        try {
            $plainToken = $global:_glvigor.auth.apikey | Undo-SecureString
            $uri = "$($global:_glvigor.auth.apipath)/projects/$targetProj"
            Write-GLVLog -Message "GET $uri" -Level Debug

            $headers = @{
                "Authorization" = "Bearer $plainToken"
                "Content-Type"  = "application/json"
            }

            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
            Write-GLVLog -Message "Successfully retrieved project: $($response.name)" -Level Success
            return $response
        }
        catch {
            Write-GLVLog -Message "Failed to fetch project: $($_.Exception.Message)" -Level Error
        }
    }
}
