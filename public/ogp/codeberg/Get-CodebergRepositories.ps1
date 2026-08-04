<#
.SYNOPSIS
Lists Codeberg repositories for a specified user, organization, or authenticated user scope.

.DESCRIPTION
Get-CodebergRepositories queries the Codeberg REST API to list repositories under a user or organization.
Defaults to user space or authenticated user scope if Org/Group is omitted.

.PARAMETER User
The Codeberg username to list repositories for.

.PARAMETER Group
The Codeberg organization name to list repositories for.

.PARAMETER IsOrg
Switch to explicitly query organization scope instead of user space.

.PARAMETER Hostname
The Codeberg server hostname (e.g. codeberg.example.com).

.PARAMETER ApiKey
The Codeberg personal access token.

.EXAMPLE
Get-CodebergRepositories -User "codeberguser" -Hostname "codeberg.example.com"

.NOTES
Requires Codeberg token and hostname.
#>

function Get-CodebergRepositories {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    [Alias('glvcbls')]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Global = $false,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$User,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$Group,
        [Parameter(Mandatory = $false)]
        [switch]$IsOrg,
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
            if (-not $Hostname) {
                throw "No Codeberg hostname provided."
            }

            [string]$codeberg_api_url = ""
            if ($Group -or $IsOrg) {
                [string]$targetGroup = if ($Group) { $Group } else { $User }
                $codeberg_api_url = "https://$Hostname/api/v1/orgs/$targetGroup/repos"
            }
            elseif ($User) {
                $codeberg_api_url = "https://$Hostname/api/v1/users/$User/repos"
            }
            else {
                $codeberg_api_url = "https://$Hostname/api/v1/user/repos"
            }

            [console]::write("$($global:_glvigor.log) codeberg repository listing request`n")

            $http_header = @{
                'Content-Type' = 'application/json'
            }
            if ($ApiKey) {
                $http_header['Authorization'] = "token $ApiKey"
            }

            $response = Invoke-RestMethod -Uri $codeberg_api_url -Method Get -Headers $http_header

            [System.Collections.Generic.List[pscustomobject]]$results = [System.Collections.Generic.List[pscustomobject]]::new()

            foreach ($item in $response) {
                $filtered = [pscustomobject]@{
                    id            = $item.id
                    name          = $item.name
                    full_name     = $item.full_name
                    owner         = $item.owner.login
                    description   = $item.description
                    html_url      = $item.html_url
                    ssh_url       = $item.ssh_url
                    clone_url     = $item.clone_url
                    private       = $item.private
                    default_branch = $item.default_branch
                }
                $results.Add($filtered)
            }

            return Get-GLVNamespaceFilter -InputObject ($results.ToArray()) -Global:$Global
        }
        catch {
            [console]::write("$($global:_glvigor.logsub) error listing codeberg repositories: $($_.Exception.Message)`n")
            throw
        }
    }
}

$cmdlet_config = @{
    function = @('Get-CodebergRepositories')
    alias    = @('glvcbls')
}

Export-ModuleMember @cmdlet_config
