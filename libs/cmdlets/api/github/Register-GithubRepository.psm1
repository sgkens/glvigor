using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
<#
.SYNOPSIS
@SYNOPSIS
Creates a new GitHub repository via the GitHub API.

.DESCRIPTION
This script is used to request the creation of a new GitHub repository via the GitHub REST API. It supports creating repositories under a user account or organization, with configurable settings like privacy, description and tags.

.PARAMETER name
The name of the repository to create. Must be unique within the user/organization scope.

.PARAMETER apikey 
The GitHub personal access token used for authentication. If not provided, will attempt to use GITHUB_API_KEY environment variable.

.PARAMETER user
The GitHub username under which to create the repository. Required if not creating under an organization.

.PARAMETER group
The GitHub organization name under which to create the repository. Takes precedence over user if both are provided.

.PARAMETER description
Optional description of the repository.

.EXAMPLE
# Create a public repository under user account
Request-GithubRepository -name "my-repo" -user "username" -description "My new repo"

.EXAMPLE
# Create a private repository under an organization
Request-GithubRepository -name "secret-project" -group "my-org" -private $true -github_token "ghp_token"

.NOTES
Requires a GitHub personal access token with appropriate repository creation permissions.
#>

function Register-GithubRepository {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$name,
        [Parameter(Mandatory = $false)]
        [string]$apikey,
        [Parameter(Mandatory = $false)]
        [string]$user,
        [Parameter(Mandatory = $false)]
        [string]$group,
        [Parameter(Mandatory = $false)]
        [string]$description,
        [Parameter(Mandatory = $false)]
        [string]$tags
    )

    process {
        try {
            [string]$homepage = ""

            [console]::write("$($global:_glvigor.log) github repository creation request`n")

            # if group is provided, use the organization API
            if ($group) {   
                $github_api_url = "https://api.github.com/orgs/$($group)/repos"
                $homepage = "https://github.com/$($group)/$($name)"
            }
            else {
                $homepage = "https://github.com/$($user)/$($name)"
                $github_api_url = "https://api.github.com/$($user)/repos"
            }
        
            # Support Environment Variable
            if ($env:GITHUB_API_KEY -and (!$apikey -or $apikey -eq "")) {
                $apikey = $env:GITEA_API_KEY
            }
            elseif ($apikey) {
                $apikey = $apikey
            }
            else {
                throw "no gitea token provided, using environment variable GITEA_API_KEY or parameter -apikey"
        
            }

            [console]::write("$($global:_glvigor.logsub) creating repository $(csole -s "$name" -c $global:__glvigor.colorpallet.magenta) for userspace: $(csole -s "$github_api_url" -c $global:__glvigor.colorpallet.magenta)`n")

            [string] $requestBody = @{
                org          = 'ORG'
                name         = $name
                description  = $description
                homepage     = $homepage
                tags         = $tags
                private      = $false
                has_issues   = $true
                has_projects = $true
                has_wiki     = $true
            } | ConvertTo-Json

            $http_header = @{
                'Accept'               = 'application/vnd.github+json'
                'Authorization'        = "Bearer $apikey"
                'X-GitHub-Api-Version' = '2022-11-28'
            }

            [console]::write("$($global:_glvigor.logsub) makeing $(csole -s "POST" -c $global:__glvigor.colorpallet.magenta) request to $(csole -s "$github_api_url" -c $global:__glvigor.colorpallet.magenta)`n")

            try {
                $response = Invoke-RestMethod -Uri $github_api_url -Method Post -Headers $http_header -Body $requestBody
            }
            catch {
                [console]::write("$($global:_glvigor.logsub) Error creating repository: $($_.Exception.Message)`n")
                throw
            }

            # filter response return as a pscustomobject
            [pscustomobject]$filtered_response = @{
                name         = $response.name
                description  = $response.description
                html_url     = $response.html_url
                git_url      = $response.git_url
                ssh_url      = $response.ssh_url
                clone_url    = $response.clone_url
                svn_url      = $response.svn_url
                homepage     = $response.homepage
                tags         = $response.tags
                private      = $response.private
                has_issues   = $response.has_issues
                has_projects = $response.has_projects
                has_wiki     = $response.has_wiki
            }
            return $filtered_response
        }
        catch {
            [console]::write("$($global:_glvigor.logsub) error creating repository: $($_.Exception.Message)`n")
        }
    }

}

$cmdlet_config = @{
    function = @('Register-GithubRepository')   
    alias    = @('glvrgr')
}

Export-ModuleMember @cmdlet_config