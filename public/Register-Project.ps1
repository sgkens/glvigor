


<#
.SYNOPSIS
@SYNOPSIS
Creates a new repository via the Gitlab API.

.DESCRIPTION
This script is used to request the creation of a new Gitlub repository via the Gitlab REST API. It supports creating repositories under a user account or organization, with configurable settings like privacy, description and tags.

.PARAMETER name
The name of the repository to create. Must be unique within the user/organization scope.

.PARAMETER gitlab_token 
The Gitlab personal access token used for authentication. If not provided, will attempt to use gitlab_API_KEY environment variable.

.PARAMETER user
The Gitlab username under which to create the repository. Required if not creating under an organization.

.PARAMETER group
The Gitlab organization name under which to create the repository. Takes precedence over user if both are provided.

.PARAMETER description
Optional description of the repository.

.EXAMPLE
# Create a public repository under user account
Register-Project -name "my-repo" -user "username" -description "My new repo"

.EXAMPLE
# Create a private repository under an organization
Register-Project -name "secret-project" -group "my-org" -private $true -gitlab_token "ghp_token"

.NOTES
Requires a Gitlab personal access token with appropriate repository creation permissions.
#>

function Register-Project {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('glvrp')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$name,
        [Parameter(Mandatory = $false)]
        [string]$group,
        [Parameter(Mandatory = $false)]
        [string]$description,
        [Parameter(Mandatory = $false)]
        [string[]]$tags,
        [Parameter(Mandatory = $false)]
        [ValidateSet('public', 'private', IgnoreCase = $true)]
        [string]$visibilitys,
        [Parameter(Mandatory = $false)]
        [string]$DefaultBranch,
        [Parameter(Mandatory = $false)]
        [switch]$Raw
    )

    process {
        try {

            
            [console]::write("$($global:_glvigor.log) $($global:_glvigor.logcmds.run) $(csole -s 'api-project-creation-post-request' -c $global:__glvigor.colorpallet.yellow)...`n")

            #=== AUTH AND PIPELINE DATA ===
            # call auth check
            Confirm-GitLabAuth
            #=== AUTH AND PIPELINE DATA ===

            [console]::write("$($global:_glvigor.logsub) create repository '$(csole -s "$name" -c $global:__glvigor.colorpallet.magenta)'`n")
            
            if (!$visibility) { $visibility = "public" }
            if (!$DefaultBranch) { $DefaultBranch = "main" }            

            [hashtable]$requestBody = @{
                name           = $name
                visibility     = $visibility
                default_branch = $DefaultBranch
            }

            if ($tags) { $requestBody.tags = $tags }
            if ($description) { $requestBody.description = $description }

            if($group){
                # check namespace(group) for group namespace
                $groupobject = Search-Gitlab -title $group -Type groups -Match
                if ($null -eq $groupobject.id) {
                    throw "gitlab group 'cosmicshell' not found, please create it first."
                    return
                }
                $requestBody.namespace_id = $groupobject.id
            }

            if ($null -ne (search-gitlab -title $name -type projects -match).id) {
                throw "gitlab repository '$(csole -s $name -c $global:__glvigor.colorpallet.magenta)' already exists. please choose another name."
                return
            }

            $_gitlab_apikey = $global:_glvigor.auth.apikey | Undo-SecureString
            $http_header = @{
                'Content-Type'         = 'application/json'
                'Authorization'        = "Bearer $_gitlab_apikey"
            }

            [console]::write("$($global:_glvigor.logsub) $($global:_glvigor.logcmds.api_post) $($global:_glvigor.auth.apipath)/projects`n")
            $response = Invoke-RestMethod -Uri "$($global:_glvigor.auth.apipath)/projects" -Method Post -Headers $http_header -Body ($requestBody | ConvertTo-Json)

            [console]::write("$($global:_glvigor.logsub) repository $(csole -s "$name" -c $global:__glvigor.colorpallet.magenta) created`n")
            [console]::write("$($global:_glvigor.logsublast)`n")

            if($raw){
                return $response
            }else{
                $filtered_response = [PSCustomObject]@{
                    name = $response.name
                    id = $response.id
                    description = $response.description
                    tags = $response.tags
                    created_at = $response.created_at
                    default_branch = $response.default_branch
                    name_with_namespace = $response.name_with_namespace
                    path_with_namespace = $response.path_with_namespace
                    web_url = $response.web_url
                }
                return $filtered_response
            }
            
        }
        catch {
            [console]::write("`n$($global:_glvigor.logsub) $(csole -s '■─error:' -c $global:__glvigor.colorpallet.red) $($_.Exception.Message)`n")
            return $response
        }
    }

}

$cmdlet_config = @{
    function = @('Register-Project')   
    alias    = @('glvrp')
}

Export-ModuleMember @cmdlet_config
