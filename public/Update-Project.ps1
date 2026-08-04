# ==============================================================================
# File: Public/Update-Project.ps1
# ==============================================================================
function Update-Project {
    <#
    .SYNOPSIS
    Updates project metadata on a GitLab instance.

    .DESCRIPTION
    Sends a request to the GitLab REST API projects endpoint to update project parameters such as name, visibility, or description.

    .PARAMETER ProjectID
    The numeric ID of the project to update.

    .PARAMETER Name
    The new project name.

    .PARAMETER Hostname
    The GitLab instance hostname.

    .PARAMETER Gituser
    The target username or namespace.

    .PARAMETER APIKey
    The authentication API token.

    .EXAMPLE
    Update-Project -ProjectID 123 -Name "new-project-name"
    #>
    [CmdletBinding()]
    [Alias('pguproj')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Hostname,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$ProjectID,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Gituser,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$APIKey,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Name
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
    }

    process {
        Write-GLVLog -Message "Updating project ID: $ProjectID with new name '$Name'..." -Level Api

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

            $body = @{
                name = $Name
            }

            $uri = "$($global:_glvigor.auth.apipath)/projects/$ProjectID"
            Write-GLVLog -Message "PUT $uri" -Level Debug

            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Put -Body ($body | ConvertTo-Json)
            Write-GLVLog -Message "Successfully updated project: $($response.name)" -Level Success
            return $response
        }
        catch {
            Write-GLVLog -Message "Failed to update project: $($_.Exception.Message)" -Level Error
        }
    }
}
