# ==============================================================================
# File: Public/Search-GitLabGroups.ps1
# ==============================================================================
<#
.SYNOPSIS
Searches for groups on a GitLab instance by name.

.DESCRIPTION
Performs a GET request to the GitLab REST API groups endpoint to search for matching groups.

.PARAMETER Hostname
The hostname of the GitLab instance.

.PARAMETER Name
The group name or search query string.

.PARAMETER APIKey
The authentication API token.

.EXAMPLE
Search-GitLabGroups -Hostname "gitlab.example.com" -Name "my-group" -APIKey "token123"
#>
function Search-GitLabGroups {
    [CmdletBinding()]
    [Alias('pgs')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Hostname,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$APIKey,

        [Parameter(Mandatory = $false)]
        [switch]$Global
    )

    process {
        Write-GLVLog -Message "Searching GitLab Groups for '$Name' on $Hostname" -Level Api
        $headers = @{
            "Authorization" = "Bearer $APIKey"
            "Content-Type"  = "application/json"
        }

        $GitlabHost = if ($Hostname.StartsWith('http')) { "$($Hostname.TrimEnd('/'))/api/v4" } else { "https://$Hostname/api/v4" }

        try {
            if ($Global) {
                $uri = "$GitlabHost/groups?search=$([uri]::EscapeDataString($Name))&per_page=100"
                Write-GLVLog -Message "GET $uri" -Level Debug
                $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            }
            else {
                $response = Get-GLVOwnedGroups -Search $Name -ApiPath $GitlabHost -AccessToken $APIKey
            }
            Write-GLVLog -Message "Successfully retrieved group details." -Level Success
            return $response
        }
        catch {
            Write-GLVLog -Message "Error: $($_.Exception.Message)" -Level Error
        }
    }
}
