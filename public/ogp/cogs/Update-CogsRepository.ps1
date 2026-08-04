<#
.SYNOPSIS
Updates configuration parameters of a Cogs repository.

.DESCRIPTION
Update-CogsRepository updates settings of a Cogs repository via the Cogs REST API.

.PARAMETER Owner
The owner (user or organization) of the repository.

.PARAMETER Name
The repository name.

.PARAMETER Description
Updated description string.

.PARAMETER Private
Switch to toggle repository privacy.

.PARAMETER Hostname
The Cogs server hostname.

.PARAMETER ApiKey
The Cogs personal access token.

.EXAMPLE
Update-CogsRepository -Owner "myorg" -Name "myrepo" -Description "New description" -Hostname "cogs.local"

.NOTES
Requires Cogs edit permissions.
#>

function Update-CogsRepository {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('glvcgup')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Owner,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [string]$Description,
        [Parameter(Mandatory = $false)]
        [switch]$Private,
        [Parameter(Mandatory = $false)]
        [string]$Hostname,
        [Parameter(Mandatory = $false)]
        [string]$ApiKey
    )

    process {
        try {
            if (-not $ApiKey -or $ApiKey -eq "") {
                if ($env:GITEA_API_KEY) { $ApiKey = $env:GITEA_API_KEY }
            }
            if (-not $Hostname -or $Hostname -eq "") {
                if ($env:GITEA_HOSTNAME) { $Hostname = $env:GITEA_HOSTNAME }
            }
            if (-not $Hostname -or -not $ApiKey) {
                throw "Cogs Hostname and ApiKey are required."
            }

            [string]$cogs_api_url = "https://$Hostname/api/v1/repos/$Owner/$Name"

            $updateBody = @{}
            if ($PSBoundParameters.ContainsKey('Description')) { $updateBody['description'] = $Description }
            if ($PSBoundParameters.ContainsKey('Private')) { $updateBody['private'] = [bool]$Private }

            $http_header = @{
                'Authorization' = "token $ApiKey"
                'Content-Type'  = 'application/json'
            }

            $response = Invoke-RestMethod -Uri $cogs_api_url -Method Patch -Headers $http_header -Body ($updateBody | ConvertTo-Json)

            [pscustomobject]$filtered_response = @{
                id           = $response.id
                name         = $response.name
                full_name    = $response.full_name
                description  = $response.description
                html_url     = $response.html_url
                private      = $response.private
                owner        = $response.owner.login
            }
            return $filtered_response
        }
        catch {
            [console]::write("$($global:_glvigor.logsub) Error updating Cogs repository '$Owner/$Name': $($_.Exception.Message)`n")
            throw
        }
    }
}

$cmdlet_config = @{
    function = @('Update-CogsRepository')
    alias    = @('glvcgup')
}

Export-ModuleMember @cmdlet_config
