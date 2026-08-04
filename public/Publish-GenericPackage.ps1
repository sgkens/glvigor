# ==============================================================================
# File: Public/Publish-GenericPackage.ps1
# ==============================================================================
<#
.SYNOPSIS
Uploads a file artifact to the GitLab Generic Package Registry.

.DESCRIPTION
Uploads a binary or text file to the project's Generic Package Registry via REST API.

.PARAMETER ProjectID
The ID of the project.

.PARAMETER PackageName
The name of the package.

.PARAMETER PackageVersion
The semver version of the package.

.PARAMETER FilePath
The absolute path to the local file to upload.

.EXAMPLE
Publish-GenericPackage -ProjectID 123 -PackageName "my-app" -PackageVersion "1.0.0" -FilePath "./dist/app.zip"
#>
function Publish-GenericPackage {
    [CmdletBinding()]
    [Alias('glvpkgup')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$Data,

        [Parameter(Mandatory = $false)]
        [int]$ProjectID,

        [Parameter(Mandatory = $true)]
        [string]$PackageName,

        [Parameter(Mandatory = $true)]
        [string]$PackageVersion,

        [Parameter(Mandatory = $true)]
        [string]$FilePath
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

        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-GLVLog -Message "File not found at path: $FilePath" -Level Error
            return
        }

        $fileName = [System.IO.Path]::GetFileName($FilePath)
        Write-GLVLog -Message "Uploading artifact '$fileName' to Generic Package Registry [$PackageName v$PackageVersion]..." -Level Api

        if (-not $global:_glvigor.auth -or -not $global:_glvigor.auth.apipath) {
            Write-GLVLog -Message "GitLab authentication token missing. Please run Request-GitLabAuth." -Level Error
            return
        }

        try {
            $uri = "$($global:_glvigor.auth.apipath)/projects/$targetProjId/packages/generic/$PackageName/$PackageVersion/$fileName"
            Write-GLVLog -Message "PUT $uri" -Level Debug

            $headers = @{
                "Authorization" = "Bearer $($global:_glvigor.auth.apikey)"
            }

            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Put -InFile $FilePath
            Write-GLVLog -Message "Successfully published package file '$fileName'." -Level Success
            return $response
        }
        catch {
            Write-GLVLog -Message "Failed to publish generic package: $($_.Exception.Message)" -Level Error
        }
    }
}
