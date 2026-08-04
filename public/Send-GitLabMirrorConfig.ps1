# ==============================================================================
# File: Public/Send-GitLabMirrorConfig.ps1
# ==============================================================================
function Send-GitLabMirrorConfig {
    <#
    .SYNOPSIS
    Pushes a remote push mirror configuration payload to a target GitLab project.

    .DESCRIPTION
    Configures a push mirror endpoint on a target GitLab project using the GitLab REST API remote_mirrors endpoint.

    .PARAMETER Hostname
    The target GitLab instance hostname.

    .PARAMETER ProjectID
    The numeric ID of the GitLab project.

    .PARAMETER Gituser
    The target GitLab username or namespace.

    .PARAMETER APIKey
    The primary GitLab API token.

    .PARAMETER MirrorHost
    The remote destination mirror host URL.

    .PARAMETER MirrorUser
    The remote destination mirror username.

    .PARAMETER MirrorAPIKey
    The remote destination mirror API key or access token.

    .EXAMPLE
    Send-GitLabMirrorConfig -Hostname "gitlab.example.com" -ProjectID "1024" -Gituser "my-org" -APIKey "pat123" -MirrorHost "github.com" -MirrorUser "my-org" -MirrorAPIKey "ghp123"
    #>
    [CmdletBinding()]
    [Alias('pglmc')]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Hostname,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$ProjectID,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Gituser,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$APIKey,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$MirrorHost,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$MirrorUser,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$MirrorAPIKey
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
    }

    process {
        $targetHost = if ($Hostname) { $Hostname } else { $ENV:GMM_HOSTNAME }
        $targetUser = if ($Gituser)  { $Gituser }  else { $ENV:GMM_USER }
        $targetKey  = if ($APIKey)   { $APIKey }   else { $ENV:GMM_APIKEY }

        if (-not $targetHost -or -not $ProjectID) {
            Write-GLVLog -Message "Missing required Hostname or ProjectID parameters." -Level Error
            return
        }

        Write-GLVLog -Message "PGLMC: Sending remote push mirror payload to Project ID: $ProjectID" -Level Api

        $GitlabHost = if ($targetHost.StartsWith("http")) { "$targetHost/api/v4" } else { "https://$targetHost/api/v4" }
        $mirrorURL  = "https://$MirrorAPIKey@$MirrorHost/$targetUser/$ProjectID.git"

        $headers = @{
            "Authorization" = "Bearer $targetKey"
            "Content-Type"  = "application/json"
        }

        Assert-GLVProjectOwnerScope -ProjectID $ProjectID -ApiPath $GitlabHost -AccessToken $targetKey

        try {
            $body = @{
                url                     = $mirrorURL
                enabled                 = $true
                only_protected_branches = $false
                keep_divergent_refs     = $false
            }

            $uri = "$GitlabHost/projects/$ProjectID/remote_mirrors"
            Write-GLVLog -Message "POST $uri" -Level Debug
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body ($body | ConvertTo-Json)
            Write-GLVLog -Message "Successfully pushed remote mirror configuration payload." -Level Success
            return $response
        }
        catch {
            Write-GLVLog -Message "Failed to send mirror configuration: $($_.Exception.Message)" -Level Error
        }
    }
}
