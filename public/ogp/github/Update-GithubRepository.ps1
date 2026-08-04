<#
.SYNOPSIS
Updates a GitHub repository via the GitHub REST API.

.DESCRIPTION
Update-GithubRepository modifies configuration settings of an existing GitHub repository (e.g. description, privacy, default branch, features).

.PARAMETER Owner
The owner (username or organization) of the GitHub repository.

.PARAMETER Name
The current name of the repository.

.PARAMETER Description
Updated description string.

.PARAMETER Private
Switch to toggle repository privacy.

.PARAMETER DefaultBranch
Updated default branch name.

.PARAMETER ApiKey
The GitHub personal access token used for authentication.

.EXAMPLE
Update-GithubRepository -Owner "octocat" -Name "my-repo" -Description "Updated description"

.NOTES
Requires a GitHub token with repository admin/write permissions.
#>

function Update-GithubRepository {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('glvghup')]
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
        [string]$DefaultBranch,
        [Parameter(Mandatory = $false)]
        [string]$ApiKey
    )

    process {
        try {
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

            [string]$github_api_url = "https://api.github.com/repos/$Owner/$Name"

            [console]::write("$($global:_glvigor.log) updating repository $(csole -s "$Owner/$Name" -c $global:__glvigor.colorpallet.magenta)`n")

            $updateFields = @{}
            if ($PSBoundParameters.ContainsKey('Description')) { $updateFields['description'] = $Description }
            if ($PSBoundParameters.ContainsKey('Private')) { $updateFields['private'] = [bool]$Private }
            if ($PSBoundParameters.ContainsKey('DefaultBranch')) { $updateFields['default_branch'] = $DefaultBranch }

            [string]$requestBody = $updateFields | ConvertTo-Json

            $http_header = @{
                'Accept'               = 'application/vnd.github+json'
                'Authorization'        = "Bearer $ApiKey"
                'X-GitHub-Api-Version' = '2022-11-28'
            }

            $response = Invoke-RestMethod -Uri $github_api_url -Method Patch -Headers $http_header -Body $requestBody

            [pscustomobject]$filtered_response = @{
                id           = $response.id
                name         = $response.name
                full_name    = $response.full_name
                description  = $response.description
                html_url     = $response.html_url
                private      = $response.private
                default_branch = $response.default_branch
                owner        = $response.owner.login
            }
            return $filtered_response
        }
        catch {
            [console]::write("$($global:_glvigor.logsub) error updating repository '$Owner/$Name': $($_.Exception.Message)`n")
            throw
        }
    }
}

$cmdlet_config = @{
    function = @('Update-GithubRepository')
    alias    = @('glvghup')
}

Export-ModuleMember @cmdlet_config
