<#
.SYNOPSIS
Register-MirrorConfig registers a mirror to a project.

.DESCRIPTION
Register-MirrorConfig registers a mirror to a project.

.PARAMETER Endpoint
The destination instance. Supported values: gitlab, gitlaben, gitea, github

.PARAMETER Namespace
Namespace of the project to mirror.

.PARAMETER User
Username or groupname of the project to mirror.

.PARAMETER Group
Groupname of the project to mirror.

.PARAMETER APIKey
Apikey of the destination instance.

.PARAMETER GiteaHost
Url of the gitea instance ie host.domain excluding protocol.

.PARAMETER GitLabHostz
Url of the GitLab instance ie host.domain excluding protocol.

.PARAMETER Enabled
Sets the mirror to enabled. Enables on mirror creation

.PARAMETER OnlyProtected
sets the mirror to only protected branches. Enables on mirror creation

.PARAMETER DivergentRefs
sets the mirror to keep divergent refs. Enables on mirror creation

.OUTPUTS
[PSCustomObject]

.NOTES
Request-GitLabAuth must be called before this function

.EXAMPLE
register-MirrorConfig -Endpoint gitlab -Namespace 'sgkens' -apikey $apikey

.EXAMPLE
register-MirrorConfig -Endpoint gitlaben -Namespace 'powershell' -apikey $apikey -gitlabhost gitlab.custom.domain

.EXAMPLE
register-MirrorConfig -Endpoint gitea -Namespace 'sgkens' -apikey $apikey -giteahost gitea.custom.domain -onlyprotected -divergentrefs -enabled

.EXAMPLE

#>
using module ..\..\..\securestring\undo-securestring.psm1
using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\private\confirm-GitLabAuth.psm1

function Register-MirrorConfig {
    [cmdletbinding()]
    [alias('glvrm')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('gitlab', 'gitlaben', 'gitea', 'github', IgnoreCase = $true)]
        [string]$Endpoint,
        [Parameter(Mandatory = $false)]
        [string]$ProjectName,
        [Parameter(Mandatory = $false)]
        [string]$Namespace,
        [Parameter(Mandatory = $false)]
        [string]$User,
        # [Parameter(Mandatory = $false)]
        # [string]$Group,
        [Parameter(Mandatory = $false)]
        [string]$APIKey,
        [Parameter(Mandatory = $false)]
        [string]$GiteaHost,
        [Parameter(Mandatory = $false)]
        [string]$GitLabHost,
        [Parameter(Mandatory = $false)]
        [switch]$Enabled,
        [Parameter(Mandatory = $false)]
        [string]$OnlyProtected,
        [Parameter(Mandatory = $false)]
        [string]$DivergentRefs,
        [Parameter(Mandatory = $false)]
        [switch]$byPassPrompt
    )
    
    process {
        
        [console]::write("$nl$($global:_glvigor.log)$($global:_glvigor.logcmds.run) $(csole -s 'api-project-post-request' -c $global:__glvigor.colorpallet.yellow)...`n")

        #=== AUTH AND PIPELINE DATA ===
        # call auth check
        confirm-GitLabAuth
        #=== AUTH AND PIPELINE DATA ===

        # set defaults
        [string]$MirrorHost_url = $null
        if(!$enabled){ $Enabled = $true }
        if (!$OnlyProtected){ $OnlyProtected = $false }
        if (!$DivergentRefs){ $DivergentRefs = $false }

        # base name or the current directory/repo
        if (!$ProjectName) {
            $RepoName = (Get-ItemProperty -Path .\ | select-Object baseName).basename
        }else{
            $RepoName = $projectname
        }

        [console]::write("$($global:_glvigor.log) starting mirror configuration for $(csole -s $RepoName -c $global:__glvigor.colorpallet.yellow) `n")

        try {

            switch ($Endpoint) {
                "gitlab" {
                    # Predefined
                    $MirrorHost_url = "gitlab.com" 
                } 
                "gitlaben" {
                    # requires -GitLabHost which can be bypassed by using $ENV:GITLAB_HOST
                    if ($GitLabHost) {
                        $MirrorHost_url = $GitLabHost
                    }
                    else {
                        throw 'Gitlab host not set, set with -GitLabHost or $ENV:GITLAB_HOST'
                        break;
                    }
                } 
                "github" {
                    # Predefined
                    $MirrorHost_url = "github.com" 
                }
                # "bitbucket" {
                #     # Predefined 
                #     $MirrorHost_url = "https://bitbucket.org" 
                # }
                "gitea" {
                    if ($GiteaHost) {
                        $MirrorHost_url = $GiteaHost
                    }
                    else {
                        throw 'gitea host not set, set with -GiteaHost or $ENV:GITEA_HOST'
                        break;
                    }
                }
                default { 
                    Throw "no mirror host set for $Endpoint"
                    break;
                }
            }

            if (!$Namespace) {
                if ($null -eq $ENV:GlV_MIRROR_NAMESPACE -or $ENV:GlV_MIRROR_NAMESPACE -eq "") {
                    throw 'gitlab namespace not set, set with $ENV:GlV_MIRROR_NAMESPACE or -Namespace'
                }
                else {
                    $Namespace = $ENV:GlV_MIRROR_NAMESPACE
                }
            }
            else {

            }
            if (!$APIKey) {
                if ($null -eq $ENV:GLV_MIRROR_APIKEY -or $ENV:GLV_MIRROR_APIKEY -eq "") {
                    throw 'mirror api key not set, set with $ENV:GLV_MIRROR_APIKEY or -APIKey'
                }
                else {
                    $APIKey = $ENV:GLV_MIRROR_APIKEY
                }
            }

            #todo test this search function with gitlab.com which has a lot of repos
            #todo   - Unsure how $_.Name -match $reponame works with multiple repos with the same name in different groups
            #todo   - Maybe use if ($response_search.count -gt 1) match group / project for a difinitive match
            [console]::write("$($global:_glvigor.logsub) getting repository details`n")
            $response_search = Search-GitLab -type projects -title $reponame -NameSpace $namespace -match 
            if($response_search.count -gt 1){
                [console]::write("$($global:_glvigor.logsub) multiple repos found for $reponame filtering...`n")
                $response_search = $response_search.where({ $_.Name -match $reponame -and $_.path_with_namespace -match "$Namespace/$reponame" })
            }
            $id = $response_search[0].id
            $name = $response_search[0].name
            $http_url_to_repo = $response_search[0].http_url_to_repo
            [console]::write("$($global:_glvigor.log) 🆔: $id 💼: $name `n")
            
            # Output repo details
            $response_search | select-object id, name, path_with_namespace| format-table -Wrap -AutoSize

            
            # # output mirror details
            #$response

            [console]::write("$($global:_glvigor.log) generating mirror configuration: $(csole -s $reponame -c $global:__glvigor.colorpallet.yellow)`n")
        
            $protected_api_mirror_path = "https://********@$MirrorHost_url/$Namespace/$RepoName.git"
            if($endpoint -eq 'gitlab'){ # gitlab.com requires the user:token SH-CE only requires the https://apikey@...
                if(!$User){throw 'gitlab user not set, set with -User required for gitlab.com'}
                $apikey = "$user`:$APIKey"
                $protected_api_mirror_path = "https://$user`:********@$MirrorHost_url/$Namespace/$RepoName.git"
            }
            $mirror_payload = @{
                url                     = "https://$APIKey@$MirrorHost_url/$Namespace/$RepoName.git"
                enabled                 = ($Enabled).ToString().ToLower()
                only_protected_branches = ($OnlyProtected).ToString().ToLower()
                keep_divergent_refs     = ($DivergentRefs).ToString().ToLower()
            }

            [console]::write("$($global:_glvigor.log) mirror configuration`n")
            [console]::write("$($global:_glvigor.logsub) $(csole -s '🆔' -c $global:__glvigor.colorpallet.magenta): $(csole -s $id -c $global:__glvigor.colorpallet.magenta)`n")
            [console]::write("$($global:_glvigor.logsub) $(csole -s '💼' -c $global:__glvigor.colorpallet.magenta): $(csole -s $Reponame -c $global:__glvigor.colorpallet.yellow)`n")
            [console]::write("$($global:_glvigor.logsubni)   • $(csole -s 'mirror-source' -c $global:__glvigor.colorpallet.magenta): $(csole -s $http_url_to_repo -c $global:__glvigor.colorpallet.yellow)`n")
            [console]::write("$($global:_glvigor.logsubni)   • $(csole -s 'mirror-api-path' -Color $global:__glvigor.colorpallet.magenta): $(csole -s "$($global:_glvigor.auth.apipath)/projects/$id/remote_mirrors" -c $global:__glvigor.colorpallet.green)`n")
            [console]::write("$($global:_glvigor.logsubni)   • $(csole -s 'mirror-pointer' -c $global:__glvigor.colorpallet.magenta): $protected_api_mirror_path`n" )
            [console]::write("$($global:_glvigor.logsubni)   • $(csole -s 'enabled' -c $global:__glvigor.colorpallet.magenta): $Enabled`n" )
            [console]::write("$($global:_glvigor.logsubni)   • $(csole -s 'only-protected-branches' -c $global:__glvigor.colorpallet.magenta): $OnlyProtected`n" )
            [console]::write("$($global:_glvigor.logsubni)   • $(csole -s 'keep-divergent-refs' -c $global:__glvigor.colorpallet.magenta): $DivergentRefs`n" )

            if (!$byPassPrompt){
                $confirm = Read-Host -Prompt "$($global:_glvigor.log) procced with mirror creation? [y/n]"
                if ($confirm -eq 'y' -or $confirm -eq 'yes') {
                    #unsecure string
                    $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
                    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                    $headers.Add("Authorization", "Bearer $_gitlab_apikey")
                    $headers.Add("Content-Type", "application/json")
                    [console]::write("$($global:_glvigor.log) $($global:_glvigor.logcmds.api_post)::$($global:_glvigor.auth.apipath)/projects/$(csole -s $id -c $global:__glvigor.colorpallet.magenta)/remote_mirrors `n")
                    $request_mirror = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$id/remote_mirrors" `
                        -Headers $headers `
                        -Method 'POST' `
                        -Body ($mirror_payload | ConvertTo-Json)
                    [console]::write("$($global:_glvigor.log) added mirror configuration for  $(csole -s $id -c $global:__glvigor.colorpallet.cyan): $RepoName - Mirror id:($($request_mirror.id))`n`n")
                }
                else {
                    [console]::writeline("$($global:_glvigor.log) Cancelled`n")
                }
            }else{
                $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
                $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                $headers.Add("Authorization", "Bearer $_gitlab_apikey")
                $headers.Add("Content-Type", "application/json")
                [console]::write("$($global:_glvigor.log) $($global:_glvigor.logcmds.api_post)::$($global:_glvigor.auth.apipath)/projects/$(csole -s $id -c $global:__glvigor.colorpallet.magenta)/remote_mirrors `n")
                $request_mirror = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$id/remote_mirrors" `
                    -Headers $headers `
                    -Method 'POST' `
                    -Body ($mirror_payload | ConvertTo-Json)
                [console]::write("$($global:_glvigor.log) added mirror configuration for  $(csole -s $id -c $global:__glvigor.colorpallet.cyan): $RepoName - Mirror id:($($request_mirror.id))`n`n")
            }

            return $request_mirror
        }
        catch {
            [console]::write("$($global:_glvigor.log) error: $(csole -s $_.Exception.Message -c $global:__glvigor.colorpallet.red)`n")
        }
    }
}
$cmdletconfig = @{
    function = @("Register-MirrorConfig")
    alias    = @("glvrm")
}

Export-Modulemember @cmdletconfig