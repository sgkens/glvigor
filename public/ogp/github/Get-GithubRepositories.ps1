<#
.SYNOPSIS
Lists GitHub repositories for a specified user or organization (defaults to user space).

.DESCRIPTION
Get-GithubRepositories queries the GitHub REST API to list repositories under a user or organization.
If -Org is specified (or -IsOrg switch is set), it queries organization repositories. Otherwise defaults to user repositories.

.PARAMETER User
The GitHub username to list repositories for. If omitted, uses the authenticated user's repositories (/user/repos) or environment/global state.

.PARAMETER Org
The GitHub organization name to list repositories for.

.PARAMETER IsOrg
Switch to explicitly query organization scope instead of user space.

.PARAMETER ApiKey
The GitHub personal access token. If omitted, uses $env:GITHUB_API_KEY.

.PARAMETER Visibility
Filter repositories by visibility: all, public, private. Default is 'all'.

.PARAMETER Sort
Property to sort by: created, updated, pushed, full_name. Default is 'full_name'.

.EXAMPLE
Get-GithubRepositories -User "octocat"

.EXAMPLE
Get-GithubRepositories -Org "my-org" -IsOrg

.NOTES
Requires a GitHub access token if accessing private repositories.
#>

function Get-GithubRepositories {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    [Alias('glvghls')]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$User,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$Org,
        [Parameter(Mandatory = $false)]
        [switch]$IsOrg,
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        [Parameter(Mandatory = $false)]
        [ValidateSet('all', 'public', 'private', IgnoreCase = $true)]
        [string]$Visibility = 'all',
        [Parameter(Mandatory = $false)]
        [ValidateSet('created', 'updated', 'pushed', 'full_name', IgnoreCase = $true)]
        [string]$Sort = 'full_name',
        [Parameter(Mandatory = $false)]
        [switch]$Global = $false
    )

    process {
        try {
            # Handle token resolution
            if (-not $ApiKey -or $ApiKey -eq "") {
                if ($env:GITHUB_API_KEY) {
                    $ApiKey = $env:GITHUB_API_KEY
                }
                elseif ($global:_glvigor -and $global:_glvigor.github_apikey) {
                    $ApiKey = $global:_glvigor.github_apikey
                }
            }

            # Determine API URL endpoint based on Org / User space
            [string]$github_api_url = ""
            if ($Org -or $IsOrg) {
                [string]$targetOrg = if ($Org) { $Org } else { $User }
                if (-not $targetOrg -and $env:GITHUB_ORG) { $targetOrg = $env:GITHUB_ORG }

                if ($targetOrg) {
                    $github_api_url = "https://api.github.com/orgs/$targetOrg/repos?type=$Visibility&sort=$Sort&per_page=100"
                }
                else {
                    $github_api_url = "https://api.github.com/user/repos?type=$Visibility&sort=$Sort&per_page=100"
                }
            }
            elseif ($User) {
                $github_api_url = "https://api.github.com/users/$User/repos?type=$Visibility&sort=$Sort&per_page=100"
            }
            else {
                # Defaults to authenticated user space
                $github_api_url = "https://api.github.com/user/repos?type=$Visibility&sort=$Sort&per_page=100"
            }

            [console]::write("$($global:_glvigor.log) github repository listing request`n")
            [console]::write("$($global:_glvigor.logsub) requesting from $(csole -s "$github_api_url" -c $global:__glvigor.colorpallet.magenta)`n")

            $http_header = @{
                'Accept'               = 'application/vnd.github+json'
                'X-GitHub-Api-Version' = '2022-11-28'
            }
            if ($ApiKey) {
                $http_header['Authorization'] = "Bearer $ApiKey"
            }

            $response = Invoke-RestMethod -Uri $github_api_url -Method Get -Headers $http_header

            [System.Collections.Generic.List[pscustomobject]]$results = [System.Collections.Generic.List[pscustomobject]]::new()

            foreach ($item in $response) {
                $filtered = [pscustomobject]@{
                    id            = $item.id
                    name          = $item.name
                    full_name     = $item.full_name
                    owner         = $item.owner.login
                    description   = $item.description
                    html_url      = $item.html_url
                    git_url       = $item.git_url
                    ssh_url       = $item.ssh_url
                    clone_url     = $item.clone_url
                    private       = $item.private
                    default_branch = $item.default_branch
                    stargazers_count = $item.stargazers_count
                    forks_count   = $item.forks_count
                }
                $results.Add($filtered)
            }

            return Get-GLVNamespaceFilter -InputObject ($results.ToArray()) -Global:$Global
        }
        catch {
            [console]::write("$($global:_glvigor.logsub) error listing github repositories: $($_.Exception.Message)`n")
            throw
        }
    }
}

$cmdlet_config = @{
    function = @('Get-GithubRepositories')
    alias    = @('glvghls')
}

Export-ModuleMember @cmdlet_config
