<#
.SYNOPSIS
Lists Forgejo repositories for a specified user, organization, or authenticated user scope.

.DESCRIPTION
Get-ForgejoRepositories queries the Forgejo REST API to list repositories under a user or organization.
Defaults to user space or authenticated user scope if Org/Group is omitted.

.PARAMETER User
The Forgejo username to list repositories for.

.PARAMETER Group
The Forgejo organization name to list repositories for.

.PARAMETER IsOrg
Switch to explicitly query organization scope instead of user space.

.PARAMETER Hostname
The Forgejo server hostname (e.g. forgejo.example.com).

.PARAMETER ApiKey
The Forgejo personal access token.

.EXAMPLE
Get-ForgejoRepositories -User "forgejouser" -Hostname "forgejo.example.com"

.NOTES
Requires Forgejo token and hostname.
#>

function Get-ForgejoRepositories {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    [Alias('glvfjls')]
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
                if ($env:GITEA_HOSTNAME) { $Hostname = $env:GITEA_HOSTNAME }
            }
            if (-not $Hostname) {
                throw "No Forgejo hostname provided. Set -Hostname or \$env:GITEA_HOSTNAME"
            }

            [string]$forgejo_api_url = ""
            if ($Group -or $IsOrg) {
                [string]$targetGroup = if ($Group) { $Group } else { $User }
                $forgejo_api_url = "https://$Hostname/api/v1/orgs/$targetGroup/repos"
            }
            elseif ($User) {
                $forgejo_api_url = "https://$Hostname/api/v1/users/$User/repos"
            }
            else {
                $forgejo_api_url = "https://$Hostname/api/v1/user/repos"
            }

            [console]::write("$($global:_glvigor.log) forgejo repository listing request`n")

            $http_header = @{
                'Content-Type' = 'application/json'
            }
            if ($ApiKey) {
                $http_header['Authorization'] = "token $ApiKey"
            }

            $response = Invoke-RestMethod -Uri $forgejo_api_url -Method Get -Headers $http_header

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
            [console]::write("$($global:_glvigor.logsub) error listing forgejo repositories: $($_.Exception.Message)`n")
            throw
        }
    }
}

$cmdlet_config = @{
    function = @('Get-ForgejoRepositories')
    alias    = @('glvfjls')
}

Export-ModuleMember @cmdlet_config
