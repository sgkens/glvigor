# ==============================================================================
# File: Public/Register-GitTag.ps1
# ==============================================================================
<#
.SYNOPSIS
Creates a new repository tag in GitLab via API.

.DESCRIPTION
Creates a repository tag pointing to a ref (branch or commit SHA) with optional message and release notes.

.PARAMETER ProjectID
The ID of the project.

.PARAMETER TagName
The name of the tag (e.g. v1.0.0).

.PARAMETER Ref
The branch name or commit SHA (e.g. main).

.PARAMETER Message
Optional tag message.

.EXAMPLE
Register-GitTag -ProjectID 123 -TagName "v1.0.0" -Ref "main" -Message "Initial release"
#>
function Register-GitTag {
    [CmdletBinding()]
    [Alias('glvrgtg')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$Data,

        [Parameter(Mandatory = $false)]
        [int]$ProjectID,

        [Parameter(Mandatory = $true)]
        [string]$TagName,

        [Parameter(Mandatory = $true)]
        [string]$Ref,

        [Parameter(Mandatory = $false)]
        [string]$Message
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

        Write-GLVLog -Message "Creating tag '$TagName' (ref: $Ref) in Project ID: $targetProjId" -Level Api

        if (-not $global:_glvigor.auth -or -not $global:_glvigor.auth.apipath) {
            Write-GLVLog -Message "GitLab authentication token missing. Please run Request-GitLabAuth." -Level Error
            return
        }

        Assert-GLVProjectOwnerScope -ProjectID $targetProjId

        try {
            $body = @{
                tag_name = $TagName
                ref      = $Ref
            }
            if ($Message) { $body['message'] = $Message }

            $jsonBody = $body | ConvertTo-Json -Depth 3
            $uri = "$($global:_glvigor.auth.apipath)/projects/$targetProjId/repository/tags"

            Write-GLVLog -Message "POST $uri" -Level Debug

            $headers = @{
                "Authorization" = "Bearer $($global:_glvigor.auth.apikey | Undo-SecureString)"
                "Content-Type"  = "application/json"
            }

            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $jsonBody
            Write-GLVLog -Message "Successfully created tag '$TagName'." -Level Success
            return $response
        }
        catch {
            Write-GLVLog -Message "Failed to create tag: $($_.Exception.Message)" -Level Error
        }
    }
}
