
<#
.SYNOPSIS
Creates a new Codeberg repository via the Codeberg API with configurable settings.

.DESCRIPTION
This script is used to request the creation of a new Codeberg repository via the Codeberg REST API. It supports creating repositories under a user account or organization, with configurable settings like privacy, description, topics, and repository features.

.PARAMETER Name
The name of the repository to create. Must be unique within the user/organization scope.

.PARAMETER Token
The Codeberg personal access token used for authentication.

.PARAMETER Hostname
The Codeberg server hostname (e.g. codeberg.example.com).

.PARAMETER User
The Codeberg username under which to create the repository. Required if not creating under an organization.

.PARAMETER Group
The Codeberg organization name under which to create the repository. Takes precedence over user if both are provided.

.PARAMETER Description
Optional description of the repository.

.PARAMETER Private
Switch to make the repository private. Default is public.

.PARAMETER AutoInit
Switch to initialize repository with README. Default is true.

.PARAMETER hasWikki
Switch to enable wiki feature. Default is true.

.PARAMETER hasIssues
Switch to enable issues feature. Default is true.

.PARAMETER hasProjects
Switch to enable projects feature. Default is true.

.PARAMETER default_branch
The default branch name. Default is "main".

.EXAMPLE
# Create a public repository under user account
Register-CodebergRepository -Name "my-repo" -User "username" -Hostname "codeberg.example.com" -Token "token123" -Description "My new repo"

.EXAMPLE
# Create a private repository under an organization with custom settings
Register-CodebergRepository -Name "secret-project" -Group "my-org" -Private -Topics "internal","project" -hasWikki:$false -Token "token123" -Hostname "codeberg.example.com"

.NOTES
Requires a Codeberg personal access token with appropriate repository creation permissions.
#>
#>

function Register-CodebergRepository {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('glvrcbr')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [string]$apiKey,
        [Parameter(Mandatory = $false)]
        [string]$Hostname,
        [Parameter(Mandatory = $false)]
        [string]$User,
        [Parameter(Mandatory = $false)]
        [string]$Group,
        [Parameter(Mandatory = $false)]
        [string]$Description,
        [Parameter(Mandatory = $false)]
        [switch]$Private,
        [Parameter(Mandatory = $false)]
        [switch]$AutoInit,
        [Parameter(Mandatory = $false)]
        [switch]$HasWikki,
        [Parameter(Mandatory = $false)]
        [switch]$HasIssues,
        [Parameter(Mandatory = $false)]
        [switch]$HasProjects,
        [Parameter(Mandatory = $false)]
        [string]$DefaultBranch
    )

    process {
        try {
            # Set default values for switches if not specified
            if($Private){[bool]$Private = $true}else{[bool] $Private = $false}
            if($HasWikki){[bool]$HasWikki = $true}else{[bool]$HasWikki = $false}
            if($HasIssues){[bool]$HasIssues = $true}else{[bool]$HasIssues = $false}
            if($HasProjects){[bool]$HasProjects = $true}else{[bool]$HasProjects = $false}
            if($AutoInit){[bool]$AutoInit = $true}else{[bool]$AutoInit = $false}
            if($DefaultBranch){$DefaultBranch = "main"}

            [console]::write("$($global:_glvigor.log)$($global:_glvigor.logcmds.run) $(csole -s "codeberg repository creation request" -c $global:__glvigor.colorpallet.yellow)...`n")

            # if group is provided, use the organization API
            if ($group) {
                $codeberg_api_url = "https://$($hostname)/api/v1/orgs/$($group)/repos"
            }
            else {
                $codeberg_api_url = "https://$($hostname)/api/v1/user/repos"
            }

            # Support Environment Variable
            if ($env:GITEA_API_KEY -and (!$apikey -or $apikey -eq "")) {
                $apikey = $env:GITEA_API_KEY
            }
            elseif ($apikey) {
                $apikey = $apikey
            }
            else {
                throw "no codeberg token provided, using environment variable GITEA_API_KEY or parameter -apikey"

            }
            if ("codeberg.org" -and (!$hostname -or $hostname -eq "")) {
                $hostname = $ENV:GITEA_HOSTNAME
            }
            elseif ($hostname) {
                $hostname = $hostname
            }
            else {
                throw "no codeberg hostname provided, using environment variable GITEA_HOSTNAME or parameter -Hostname"
            }

            [console]::write("$($global:_glvigor.logsub) creating repository •-[$(csole -s "$name" -c $global:__glvigor.colorpallet.magenta)] on $hostname`n")

            [hashtable] $requestBody = @{
                name           = $Name
                auto_init      = $AutoInit
                has_issues     = $HasIssues
                has_projects   = $HasProjects
                has_wiki       = $HasWikki
                default_branch = $DefaultBranch
            }

            if($Private -eq $true){$requestBody.private = $true}
            if($description){$requestBody.description = $description}
            if($topics){$requestBody.topics = $topics}

            $http_header = @{
                'Authorization'        = "token $apiKey"
                'Content-Type'         = 'Application/json'
            }

            [console]::write("$($global:_glvigor.logsubrun)$($global:_glvigor.logcmds.codeberg_api_post) $(csole -s $codeberg_api_url -c $global:__glvigor.colorpallet.magenta)`n")

            $response = Invoke-RestMethod -uri $codeberg_api_url -Method POST -Headers $http_header -Body ($requestBody | ConvertTo-Json)
            [console]::write("$($global:_glvigor.logsub) created  $($global:_glvigor.sep) $(csole -s "$($response.name)-🆔:$($response.id)" -c $global:__glvigor.colorpallet.magenta) successfully`n")

            # filter response return as a pscustomobject
            [console]::write("$($global:_glvigor.logsublast) $(csole -s "filtering response..." -c $global:__glvigor.colorpallet.blue)`n")
            [pscustomobject]$filtered_response = @{
                id           = $response.id
                name         = $response.name
                full_name    = $response.full_name
                created_at   = $response.created_at
                description  = $response.description
                html_url     = $response.html_url
                ssh_url      = $response.ssh_url
                clone_url    = $response.clone_url
                private      = $response.private
                has_issues   = $response.has_issues
                has_projects = $response.has_projects
                has_wiki     = $response.has_wiki
                default_branch = $response.default_branch
                owner        = $response.owner.login
                owner_id     = $response.owner.id
            }
            return $filtered_response
        }
        catch {
            [console]::write("$($global:_glvigor.logsub) $($global:_glvigor.error) $response_statusCode $(csole -s $_.Exception.Message -c $global:__glvigor.colorpallet.red)`n")
        }
    }

}

$cmdlet_config = @{
    function = @('Register-CodebergRepository')
    alias    = @('glvrcbr')
}

Export-ModuleMember @cmdlet_config
