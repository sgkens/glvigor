# ==============================================================================
# File: Public/Request-GitLabAuth.ps1
# ==============================================================================
<#
.SYNOPSIS
Authenticates with a GitLab instance and initializes the global session auth object.

.DESCRIPTION
Verifies connectivity and personal access token against the specified GitLab instance, populating $global:_glvigor.auth safely with SecureString memory protection.

.PARAMETER Hostname
The hostname or full URL of the GitLab instance. Defaults to $ENV:GITLAB_HOST.

.PARAMETER APIKey
The Personal Access Token (PAT). Defaults to $ENV:GITLAB_API_KEY.

.EXAMPLE
Request-GitLabAuth
#>
function Request-GitLabAuth {
    [CmdletBinding()]
    [Alias('rgla')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Hostname,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$APIKey
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
    }

    process {
        Write-GLVLog -Message "Initializing GitLab authentication sequence..." -Level Info

        $targetHost = if ($Hostname) { $Hostname } else { $ENV:GITLAB_HOST }
        $targetKey  = if ($APIKey)   { $APIKey }   else { $ENV:GITLAB_API_KEY }

        if (-not $targetHost) { $targetHost = 'gitlab.com' }
        if (-not $targetHost.StartsWith('http://') -and -not $targetHost.StartsWith('https://')) {
            $targetHost = "https://$targetHost"
        }

        if (-not $targetKey) {
            Write-GLVLog -Message "No API Token supplied in parameters or `$ENV:GITLAB_API_KEY." -Level Error
            return
        }

        $apiPath = "$targetHost/api/v4"
        Write-GLVLog -Message "Target Endpoint: $apiPath" -Level Debug

        try {
            # Convert raw APIKey to SecureString for memory protection
            $secToken = [System.Security.SecureString]::new()
            $targetKey.ToCharArray() | ForEach-Object { $secToken.AppendChar($_) }
            $secToken.MakeReadOnly()

            $plainToken = $secToken | Undo-SecureString

            $headers = @{
                "Authorization" = "Bearer $plainToken"
                "Content-Type"  = "application/json"
            }

            Write-GLVLog -Message "Verifying identity with GET $apiPath/user" -Level Api
            $userData = Invoke-RestMethod -Uri "$apiPath/user" -Headers $headers -Method Get

            if ($userData -and $userData.id) {
                $global:_glvigor.auth = [PSCustomObject]@{
                    hostname   = $targetHost
                    apipath    = $apiPath
                    apikey     = $secToken
                    id         = $userData.id
                    username   = $userData.username
                    name       = $userData.name
                    httpstatus = 200
                }

                Write-GLVLog -Message "Authentication SUCCESS. Logged in as: '$($userData.username)' (ID: $($userData.id))" -Level Success
                return $global:_glvigor.auth
            }
            else {
                Write-GLVLog -Message "Failed to validate user identity response." -Level Error
            }
        }
        catch {
            Write-GLVLog -Message "Authentication failed: $($_.Exception.Message)" -Level Error
        }
    }
}
