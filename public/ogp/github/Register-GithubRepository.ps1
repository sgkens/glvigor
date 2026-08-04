<#
.SYNOPSIS
Creates a new GitHub repository via the GitHub API.

.DESCRIPTION
Register-GithubRepository creates a new GitHub repository under a user account or organization.

.PARAMETER Name
The name of the repository to create. Must be unique within the user/organization scope.

.PARAMETER ApiKey
The GitHub personal access token used for authentication.

.PARAMETER User
The GitHub username under which to create the repository.

.PARAMETER Group
The GitHub organization name under which to create the repository. Takes precedence over User if provided.

.PARAMETER Description
Optional description of the repository.

.PARAMETER Private
Switch to create a private repository.

.EXAMPLE
Register-GithubRepository -Name "my-repo" -User "username" -Description "My new repo"

.NOTES
Requires a GitHub personal access token with repo creation permissions.
#>

function Register-GithubRepository {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('glvrgr', 'Register-GithubRepositories')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        [Parameter(Mandatory = $false)]
        [string]$User,
        [Parameter(Mandatory = $false)]
        [string]$Group,
        [Parameter(Mandatory = $false)]
        [string]$Description,
        [Parameter(Mandatory = $false)]
        [switch]$Private
    )

    process {
        try {
            [string]$homepage = ""

            [console]::write("$($global:_glvigor.log) github repository creation request`n")

            if ($Group) {
                $github_api_url = "https://api.github.com/orgs/$Group/repos"
                $homepage = "https://github.com/$Group/$Name"
            }
            elseif ($User) {
                $homepage = "https://github.com/$User/$Name"
                $github_api_url = "https://api.github.com/user/repos"
            }
            else {
                $github_api_url = "https://api.github.com/user/repos"
            }

            if (-not $ApiKey -or $ApiKey -eq "") {
                if ($env:GITHUB_API_KEY) {
                    $ApiKey = $env:GITHUB_API_KEY
                }
                elseif ($global:_glvigor -and $global:_glvigor.github_apikey) {
                    $ApiKey = $global:_glvigor.github_apikey
                }
                else {
                    throw "No GitHub token provided. Use -ApiKey parameter or set \$env:GITHUB_API_KEY"
                }
            }

            [console]::write("$($global:_glvigor.logsub) creating repository $(csole -s "$Name" -c $global:__glvigor.colorpallet.magenta) via: $(csole -s "$github_api_url" -c $global:__glvigor.colorpallet.magenta)`n")

            $requestBodyHash = @{
                name         = $Name
                description  = $Description
                private      = [bool]$Private
                has_issues   = $true
                has_projects = $true
                has_wiki     = $true
            }
            if ($homepage) { $requestBodyHash['homepage'] = $homepage }

            [string]$requestBody = $requestBodyHash | ConvertTo-Json

            $http_header = @{
                'Accept'               = 'application/vnd.github+json'
                'Authorization'        = "Bearer $ApiKey"
                'X-GitHub-Api-Version' = '2022-11-28'
            }

            [console]::write("$($global:_glvigor.logsub) making POST request to $(csole -s "$github_api_url" -c $global:__glvigor.colorpallet.magenta)`n")

            $response = Invoke-RestMethod -Uri $github_api_url -Method Post -Headers $http_header -Body $requestBody

            [pscustomobject]$filtered_response = @{
                id           = $response.id
                name         = $response.name
                full_name    = $response.full_name
                description  = $response.description
                html_url     = $response.html_url
                git_url      = $response.git_url
                ssh_url      = $response.ssh_url
                clone_url    = $response.clone_url
                homepage     = $response.homepage
                private      = $response.private
                has_issues   = $response.has_issues
                has_projects = $response.has_projects
                has_wiki     = $response.has_wiki
                owner        = $response.owner.login
            }
            return $filtered_response
        }
        catch {
            [console]::write("$($global:_glvigor.logsub) error creating repository: $($_.Exception.Message)`n")
            throw
        }
    }
}

$cmdlet_config = @{
    function = @('Register-GithubRepository')
    alias    = @('glvrgr', 'Register-GithubRepositories')
}

Export-ModuleMember @cmdlet_config
