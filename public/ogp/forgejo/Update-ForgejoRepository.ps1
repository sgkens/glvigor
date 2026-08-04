<#
.SYNOPSIS
Updates configuration parameters of a Forgejo repository.

.DESCRIPTION
Update-ForgejoRepository updates settings of a Forgejo repository via the Forgejo REST API.

.PARAMETER Owner
The owner (user or organization) of the repository.

.PARAMETER Name
The repository name.

.PARAMETER Description
Updated description string.

.PARAMETER Private
Switch to toggle repository privacy.

.PARAMETER Hostname
The Forgejo server hostname.

.PARAMETER ApiKey
The Forgejo personal access token.

.EXAMPLE
Update-ForgejoRepository -Owner "myorg" -Name "myrepo" -Description "New description" -Hostname "forgejo.local"

.NOTES
Requires Forgejo edit permissions.
#>

function Update-ForgejoRepository {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('glvfjup')]
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
                throw "Forgejo Hostname and ApiKey are required."
            }

            [string]$forgejo_api_url = "https://$Hostname/api/v1/repos/$Owner/$Name"

            $updateBody = @{}
            if ($PSBoundParameters.ContainsKey('Description')) { $updateBody['description'] = $Description }
            if ($PSBoundParameters.ContainsKey('Private')) { $updateBody['private'] = [bool]$Private }

            $http_header = @{
                'Authorization' = "token $ApiKey"
                'Content-Type'  = 'application/json'
            }

            $response = Invoke-RestMethod -Uri $forgejo_api_url -Method Patch -Headers $http_header -Body ($updateBody | ConvertTo-Json)

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
            [console]::write("$($global:_glvigor.logsub) Error updating Forgejo repository '$Owner/$Name': $($_.Exception.Message)`n")
            throw
        }
    }
}

$cmdlet_config = @{
    function = @('Update-ForgejoRepository')
    alias    = @('glvfjup')
}

Export-ModuleMember @cmdlet_config
