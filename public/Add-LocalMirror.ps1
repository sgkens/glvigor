# ==============================================================================
# File: Public/Add-LocalMirror.ps1
# ==============================================================================
function Add-LocalMirror {
    <#
    .SYNOPSIS
    Sets the local mirror configuration for a repository, supporting both parameters and environment variables.

    .DESCRIPTION
    This cmdlet sets the local mirror configuration for a repository. It allows configuration via parameters or environment variables.

    .PARAMETER Endpoint
    The destination instance. Supported values are: `gitlab`, `gitlaben`, `gitea`, `github`. For self-hosted instances, use the `-GiteaHost` and `-GitLabHost` parameters together with the respective endpoint.

    .PARAMETER User
    The user name for authentication or repo path ownership.

    .PARAMETER Group
    The username or group name of the project to mirror, for github this is the org name.

    .PARAMETER apikey
    The API key for the destination instance.

    .PARAMETER GiteaHost
    The URL of the Gitea instance, e.g., `host.domain`, excluding the protocol.

    .PARAMETER GitLabHost
    The URL of the GitLab instance, e.g., `host.domain`, excluding the protocol.

    .PARAMETER Name
    The name of the mirror. The default value is 'mirror'.

    .EXAMPLE
    Add-LocalMirror -Endpoint 'gitlab' -User 'user' -apikey 'key'

    .NOTES
    Does not request authentication, but requires git.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    [Alias('glvalm')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('github', 'gitlab', 'gitea', 'gitlaben', IgnoreCase = $true)]
        [string]$Endpoint,

        [Parameter(Mandatory = $false)]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [string]$Group,

        [Parameter(Mandatory = $false)]
        [string]$apikey,

        [Parameter(Mandatory = $false)]
        [string]$GiteaHost,

        [Parameter(Mandatory = $false)]
        [string]$GitLabHost,

        [Parameter(Mandatory = $false)]
        [string]$Name
    )

    process {
        try {
            $RepoName = (Get-ItemProperty -Path .\ | Select-Object -ExpandProperty BaseName)

            Write-GLVLog -Message "Starting local mirror configuration for '$RepoName'..." -Level Info
            Write-GLVLog -Message "Setting '$Endpoint' as target endpoint" -Level Debug

            $mirrorName = if ($Name) { $Name } else { 'mirror' }

            switch ($Endpoint) {
                "gitlab" {
                    $MirrorHost_url = "gitlab.com"
                }
                "gitlaben" {
                    if ($GitLabHost) {
                        $MirrorHost_url = $GitLabHost
                    } else {
                        throw 'GitLab host not set, set with -GitLabHost or $ENV:GITLAB_HOST'
                    }
                }
                "github" {
                    $MirrorHost_url = "github.com"
                }
                "gitea" {
                    if ($GiteaHost) {
                        $MirrorHost_url = $GiteaHost
                    } else {
                        throw 'Gitea host not set, set with -GiteaHost or $ENV:GITEA_HOST'
                    }
                }
                default {
                    throw "No mirror host set for $Endpoint"
                }
            }

            if (-not $User -and -not $ENV:GLV_MIRROR_USER) {
                throw 'User param is not set, set with $ENV:GLV_MIRROR_USER or -User'
            }
            if (-not $Group) { $Group = $User }

            $targetKey = if ($apikey) { $apikey } else { $ENV:GLV_MIRROR_APIKEY }
            if (-not $targetKey) {
                throw 'APIKEY param is not set, set with $ENV:GLV_MIRROR_APIKEY or -apikey'
            }
        }
        catch {
            Write-GLVLog -Message "Error: $($_.Exception.Message)" -Level Error
            return
        }

        if (Get-Command -Name git -ErrorAction SilentlyContinue) {
            try {
                $repo_string = "https://$User`:$targetKey@$MirrorHost_url/$Group/$RepoName.git"
                $repo_string_safe = "https://$User`:*******************@$MirrorHost_url/$Group/$RepoName.git"
                Write-GLVLog -Message "Generating endpoint string: $repo_string_safe" -Level Api

                $non_origin = Get-LocalRemoteConfig | Where-Object { $_.Name -ne 'origin' }
                if ($non_origin -and $non_origin.Name -contains $mirrorName) {
                    throw "Mirror '$mirrorName' already exists for $RepoName"
                } else {
                    git remote add $mirrorName $repo_string 2>$null
                    git remote set-url --push $mirrorName $repo_string 2>$null
                    Write-GLVLog -Message "Git remote add mirror '$mirrorName' complete." -Level Success
                }
            }
            catch {
                Write-GLVLog -Message "Error: $($_.Exception.Message)" -Level Error
            }
        }
    }
}
