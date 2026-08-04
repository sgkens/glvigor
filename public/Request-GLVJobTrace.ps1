# ==============================================================================
# File: Public/Request-GLVJobTrace.ps1
# ==============================================================================
<#
.SYNOPSIS
Fetches the execution log trace of a specific GitLab CI job.

.DESCRIPTION
Sends a request to the GitLab API to retrieve the plain text raw execution log output for a CI/CD job.

.PARAMETER Data
Pipeline input object containing project or job metadata.

.PARAMETER ProjectID
The ID of the project.

.PARAMETER JobID
The ID of the target job.

.PARAMETER OutFile
Optional output file path to save the trace content.

.EXAMPLE
Request-GLVJobTrace -ProjectID 123 -JobID 456

.EXAMPLE
Request-GLVJobTrace -ProjectID 123 -JobID 456 -OutFile "./job-456.log"
#>
function Request-GLVJobTrace {
    [CmdletBinding()]
    [Alias('glvrqtrace')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$Data,

        [Parameter(Mandatory = $false)]
        [int]$ProjectID,

        [Parameter(Mandatory = $true)]
        [int]$JobID,

        [Parameter(Mandatory = $false)]
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
            Write-GLVLog -Message "Fetching trace log for Job ID $($JobID) in Project ID $($targetProjId)" -Level Api

            $headers = @{
                "Authorization" = "Bearer $($global:_glvigor.auth.apikey)"
            }

            $uri = "$($global:_glvigor.auth.apipath)/projects/$targetProjId/jobs/$JobID/trace"
            Write-GLVLog -Message "GET $uri" -Level Debug

            $traceText = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

            Write-GLVLog -Message "Successfully fetched trace log ($($traceText.Length) bytes)." -Level Success

            if ($OutFile) {
                $resolvedPath = [System.IO.Path]::GetFullPath($OutFile)
                [System.IO.File]::WriteAllText($resolvedPath, $traceText)
                Write-GLVLog -Message "Trace log saved to: $resolvedPath" -Level Info
            }

            return $traceText
        }
        catch {
            Write-GLVLog -Message "Failed to fetch trace log for Job ID $($JobID) - $($_.Exception.Message)" -Level Error
        }
    }
}
