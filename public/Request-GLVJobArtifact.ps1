# ==============================================================================
# File: Public/Request-GLVJobArtifact.ps1
# ==============================================================================
<#
.SYNOPSIS
Downloads build artifacts from a GitLab CI job.

.DESCRIPTION
Sends a request to the GitLab API to download the zipped artifacts archive (or a specific artifact file) produced by a CI/CD job.

.PARAMETER Data
Pipeline input object containing project or job metadata.

.PARAMETER ProjectID
The ID of the project.

.PARAMETER JobID
The ID of the job.

.PARAMETER ArtifactPath
Optional relative file path inside the job's artifact archive.

.PARAMETER OutFile
Output file path where the artifact file or archive will be saved.

.EXAMPLE
Request-GLVJobArtifact -ProjectID 123 -JobID 456 -OutFile "./artifacts.zip"

.EXAMPLE
Request-GLVJobArtifact -ProjectID 123 -JobID 456 -ArtifactPath "dist/app.dll" -OutFile "./app.dll"
#>
function Request-GLVJobArtifact {
    [CmdletBinding()]
    [Alias('glvrqart')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$Data,

        [Parameter(Mandatory = $false)]
        [int]$ProjectID,

        [Parameter(Mandatory = $true)]
        [int]$JobID,

        [Parameter(Mandatory = $false)]
        [string]$ArtifactPath,

        [Parameter(Mandatory = $true)]
        [string]$OutFile
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
            }

            $resolvedOut = [System.IO.Path]::GetFullPath($OutFile)

            if ($ArtifactPath) {
                Write-GLVLog -Message "Downloading single artifact '$ArtifactPath' for Job ID $($JobID)" -Level Api
                $encodedPath = [System.Web.HttpUtility]::UrlEncode($ArtifactPath)
                $uri = "$($global:_glvigor.auth.apipath)/projects/$targetProjId/jobs/$JobID/artifacts/$encodedPath"
            }
            else {
                Write-GLVLog -Message "Downloading full artifact zip for Job ID $($JobID)" -Level Api
                $uri = "$($global:_glvigor.auth.apipath)/projects/$targetProjId/jobs/$JobID/artifacts"
            }

            Write-GLVLog -Message "GET $uri -> $resolvedOut" -Level Debug
            Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -OutFile $resolvedOut

            Write-GLVLog -Message "Successfully downloaded artifact to: $resolvedOut" -Level Success
            return $resolvedOut
        }
        catch {
            Write-GLVLog -Message "Failed to download artifact for Job ID $($JobID) - $($_.Exception.Message)" -Level Error
        }
    }
}
