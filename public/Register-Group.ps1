


<#
.SYNOPSIS
@SYNOPSIS
Creates a new group via the Gitlab API.

.DESCRIPTION
This script is used to request the creation of a new Gitlub group via the Gitlab REST API.

.PARAMETER name
The name of the group to create. Must be unique within the user/organization scope.

.PARAMETER path
The path of the group to create. Must be unique within the user/organization scope.

.PARAMETER gitlab_token
The Gitlab personal access token used for authentication. If not provided, will attempt to use gitlab_API_KEY environment variable.

.PARAMETER description
Optional description of the group.

.EXAMPLE
# Create a public group
Register-Group -name "my-group" -path "my-group" -description "My new group"

.NOTES
Requires a Gitlab personal access token with appropriate group creation permissions.
#>

function Register-Group {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('glvrg')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$name,
        [Parameter(Mandatory = $true)]
        [string]$path,
        [Parameter(Mandatory = $false)]
        [string]$description,
        [Parameter(Mandatory = $false)]
        [ValidateSet('public', 'private', 'internal', IgnoreCase = $true)]
        [string]$visibility = 'private',
        [Parameter(Mandatory = $false)]
        [switch]$Raw
    )

    process {
        try {


            [console]::write("$($global:_glvigor.log) $($global:_glvigor.logcmds.run) $(csole -s 'api-group-creation-post-request' -c $global:__glvigor.colorpallet.yellow)...`n")

            #=== AUTH AND PIPELINE DATA ===
            # call auth check
            Confirm-GitLabAuth
            #=== AUTH AND PIPELINE DATA ===

            [console]::write("$($global:_glvigor.logsub) create group '$(csole -s "$name" -c $global:__glvigor.colorpallet.magenta)'`n")

            [hashtable]$requestBody = @{
                name           = $name
                path           = $path
                visibility     = $visibility
            }

            if ($description) { $requestBody.description = $description }

            if ($null -ne (search-gitlab -title $name -type groups -match).id) {
                throw "gitlab group '$(csole -s $name -c $global:__glvigor.colorpallet.magenta)' already exists. please choose another name."
                return
            }

            $_gitlab_apikey = $global:_glvigor.auth.apikey | Undo-SecureString
            $http_header = @{
                'Content-Type'         = 'application/json'
                'Authorization'        = "Bearer $_gitlab_apikey"
            }

            [console]::write("$($global:_glvigor.logsub) $($global:_glvigor.logcmds.api_post) $($global:_glvigor.auth.apipath)/groups`n")
            $response = Invoke-RestMethod -Uri "$($global:_glvigor.auth.apipath)/groups" -Method Post -Headers $http_header -Body ($requestBody | ConvertTo-Json)

            [console]::write("$($global:_glvigor.logsub) group $(csole -s "$name" -c $global:__glvigor.colorpallet.magenta) created`n")
            [console]::write("$($global:_glvigor.logsublast)`n")

            if($raw){
                return $response
            }else{
                $filtered_response = [PSCustomObject]@{
                    name = $response.name
                    id = $response.id
                    description = $response.description
                    created_at = $response.created_at
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
    function = @('Register-Group')
    alias    = @('glvrg')
}

Export-ModuleMember @cmdlet_config
