# ==============================================================================
# File: Public/Request-License.ps1
# ==============================================================================
function Request-License {
    <#
    .SYNOPSIS
    Retrieves repository license templates from the GitLab REST API.

    .DESCRIPTION
    Fetches available license templates (e.g. MIT, Apache-2.0, GPL-3.0) from the GitLab templates API, with optional string interpolation and file saving.

    .PARAMETER Type
    The license template key (e.g. 'mit', 'apache-2.0').

    .PARAMETER Author
    The copyright holder name to interpolate into the license template.

    .PARAMETER SaveToFile
    Switch to save the license content to a local LICENSE file.

    .EXAMPLE
    Request-License -Type 'mit' -Author 'sgkens'
    #>
    [CmdletBinding()]
    [Alias('glvrl')]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [string]$Author,

        [Parameter(Mandatory = $false)]
        [switch]$SaveToFile
    )

    process {
        Write-GLVLog -Message "Fetching license templates from GitLab REST API..." -Level Api

        if (-not $global:_glvigor.auth -or -not $global:_glvigor.auth.apipath) {
            Write-GLVLog -Message "GitLab authentication token missing. Please run Request-GitLabAuth." -Level Error
            return
        }

        try {
            $plainToken = $global:_glvigor.auth.apikey | Undo-SecureString
            $headers = @{
                "Authorization" = "Bearer $plainToken"
                "Content-Type"  = "application/json"
            }

            $uri = "$($global:_glvigor.auth.apipath)/templates/licenses?page=1&per_page=100"
            Write-GLVLog -Message "GET $uri" -Level Debug
            $request_licensetemplate = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

            if ($SaveToFile) {
                Write-GLVLog -Message "Saving license to local file LICENSE..." -Level Info
                $request_licensetemplate | Out-File -FilePath "./LICENSE" -Force
            }

            if (-not $Type) {
                Write-GLVLog -Message "Successfully retrieved license templates list." -Level Success
                return $request_licensetemplate
            }
            else {
                $licenseObj = $request_licensetemplate | Where-Object { $_.key -eq $Type } | Select-Object -First 1
                if ($licenseObj) {
                    $authorName = if ($Author) { $Author } else { $global:_glvigor.auth.username }
                    $populated_license = $licenseObj.content -replace '\[fullname\]', $authorName -replace '\[year\]', (Get-Date).Year.ToString()
                    Write-GLVLog -Message "Successfully generated '$Type' license template for $authorName." -Level Success
                    return $populated_license
                } else {
                    Write-GLVLog -Message "License template '$Type' not found." -Level Warning
                }
            }
        }
        catch {
            Write-GLVLog -Message "Failed to fetch license template: $($_.Exception.Message)" -Level Error
        }
    }
}
