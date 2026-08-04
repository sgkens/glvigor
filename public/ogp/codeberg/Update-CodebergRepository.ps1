<#
.SYNOPSIS
Updates configuration parameters of a Codeberg repository.

.DESCRIPTION
Update-CodebergRepository updates settings of a Codeberg repository via the Codeberg REST API.

.PARAMETER Owner
The owner (user or organization) of the repository.

.PARAMETER Name
The repository name.

.PARAMETER Description
Updated description string.

.PARAMETER Private
Switch to toggle repository privacy.

.PARAMETER Hostname
The Codeberg server hostname.

.PARAMETER ApiKey
The Codeberg personal access token.

.EXAMPLE
Update-CodebergRepository -Owner "myorg" -Name "myrepo" -Description "New description" -Hostname "codeberg.local"

.NOTES
Requires Codeberg edit permissions.
#>

function Update-CodebergRepository {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('glvcbup')]
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
                if ($env:CODEBERG_HOSTNAME) { $Hostname = $env:CODEBERG_HOSTNAME } else { $Hostname = "codeberg.org" }
            }
            if (-not $Hostname -or -not $ApiKey) {
                throw "Codeberg Hostname and ApiKey are required."
            }

            [string]$codeberg_api_url = "https://$Hostname/api/v1/repos/$Owner/$Name"

            $updateBody = @{}
            if ($PSBoundParameters.ContainsKey('Description')) { $updateBody['description'] = $Description }
            if ($PSBoundParameters.ContainsKey('Private')) { $updateBody['private'] = [bool]$Private }

            $http_header = @{
                'Authorization' = "token $ApiKey"
                'Content-Type'  = 'application/json'
            }

            $response = Invoke-RestMethod -Uri $codeberg_api_url -Method Patch -Headers $http_header -Body ($updateBody | ConvertTo-Json)

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
            [console]::write("$($global:_glvigor.logsub) Error updating Codeberg repository '$Owner/$Name': $($_.Exception.Message)`n")
            throw
        }
    }
}

$cmdlet_config = @{
    function = @('Update-CodebergRepository')
    alias    = @('glvcbup')
}

Export-ModuleMember @cmdlet_config
