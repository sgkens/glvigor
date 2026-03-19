<# ----------------------------------------------------------------------

 .88888.  dP                 oo
d8'   `88 88
88        88        dP   .dP dP .d8888b. .d8888b. 88d888b.
88   YP88 88        88   d8' 88 88'  `88 88'  `88 88'  `88
Y8.   .88 88        88 .88'  88 88.  .88 88.  .88 88
 `88888'  88888888P 8888P'   dP `8888P88 `88888P' dP
                                     .88
______________--------------------d8888P----------------------------------

GLViger offers a comprehensive set of cmdlets for managing key resources
on a GitLab instance. With this module, you can create, view, update, remove,
and search for issues, merge requests, projects, groups, and labels through
the GitLab API. Additionally, the module includes cmdlets for handling
Git-related functions, such as viewing, adding, and removing mirrors, as well
as updating the origin, and registering and unregistering mirrors via the
GitLab API, performing git commands, and more.

#>
using module libs\colorconsole\libs\cmdlets\New-ColorConsole.psm1 #api
using module libs\cmdlets\api\Request-GitLabAuth.psm1 #api
using module libs\cmdlets\api\Search-GitLab.psm1 #api
# project
using module libs\cmdlets\api\project\Request-Project.psm1 #api
using module libs\cmdlets\api\project\Register-Project.psm1 #api
using module libs\cmdlets\api\project\Unregister-Project.psm1 #api
# mirror
using module libs\cmdlets\api\mirror\Request-MirrorConfig.psm1 #api
using module libs\cmdlets\api\mirror\Register-MirrorConfig.psm1 #api
using module libs\cmdlets\api\mirror\Unregister-MirrorConfig.psm1 #api
# issue
using module libs\cmdlets\api\issue\Request-Issue.psm1 #api
using module libs\cmdlets\api\issue\Register-Issue.psm1 #api
# group
using module libs\cmdlets\api\group\Request-Group.psm1 #api
using module libs\cmdlets\api\group\Register-Group.psm1 #api
using module libs\cmdlets\api\group\Unregister-Group.psm1 #api
using module libs\cmdlets\api\group\Update-Group.psm1 #api
# label
using module libs\cmdlets\api\label\Request-Label.psm1 #api
using module libs\cmdlets\api\label\Register-Label.psm1 #api
using module libs\cmdlets\api\label\Unregister-Label.psm1 #api
using module libs\cmdlets\api\label\Update-Label.psm1 #api
# mergerequest
using module libs\cmdlets\api\mergerequest\Request-MergeRequest.psm1 #api
using module libs\cmdlets\api\mergerequest\Register-MergeRequest.psm1 #api
using module libs\cmdlets\api\mergerequest\Unregister-MergeRequest.psm1 #api
using module libs\cmdlets\api\mergerequest\Update-MergeRequest.psm1 #api
# blob
using module libs\cmdlets\api\blob\Request-Blob.psm1 #api
# github api
using module libs\cmdlets\api\github\Register-GithubRepository.psm1 #api
# gitea api
using module libs\cmdlets\api\gitea\Register-GiteaRepository.psm1 #api
# license
using module libs\cmdlets\api\Request-License.psm1 #api
# using module libs\cmdlets\api\Unregister-Issue.psm1 #api #todo create cmdlets
# git
using module libs\cmdlets\git\Get-LocalRemoteConfig.psm1 #git
using module libs\cmdlets\git\Add-LocalMirror.psm1 #git
using module libs\cmdlets\git\Remove-LocalMirror.psm1 #git
using module libs\cmdlets\git\Get-LocalMirrors.psm1 #git
using module libs\cmdlets\git\Set-GitOrigin.psm1 #git
using module libs\cmdlets\git\Get-GitOrigin.psm1 #git
using module libs\cmdlets\git\Get-GitLog.psm1 #git


#! NOTE to self - set api functions to request, register, and unregister
#! NOTE to self - set git functions to get, set, and remove
#? for consistancy

# using module libs\cmdlets\Send-GitLabMirrorConfig.psm1
# using module libs\cmdlets\Request-GitLabMirrorConfig.psm1
# using module libs\cmdlets\Search-Gitlab.psm1
# using module libs\cmdlets\Search-GitLabGroups.psm1
# using module libs\cmdlets\Request-GitLabAuth.psm1
# using module libs\cmdlets\Register-MirrorConfig.psm1
# using module cmdlets\Set-Localmirrorconfig.psm1

# GMM(GitMirrorManager)
# I like GLVigor

# Enable utf8 encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# api::request mirror config

# request types
# api::get
# api::post
# api::put/update
# api::delete
# git::command remote, fetch, push

# emojis
# 🚪🦜

# console logo glv
# log message
# log sub message
# log sub with no logo or log indentation
$glv_icon        = "┬$(csole -s g -c white -bg darkcyan)$(csole -s l -c white -bg darkyellow)$(csole -s viger -c white -bg darkblue)"
$glviger_n       = csole -s "$(csole -s Ø─ -c cyan)$glv_icon" -c yellow
$glviger_s       = csole -s "─" -c green
$glvlt           = $glviger_n + $glviger_s # GLViger LogTitle

$glvlt_sub_base  = "$(" " * 2)$(csole -String '│  ' -Color cyan)"
$glvlt_sub       = "$(" " * 2)$(csole -String '│ «' -Color cyan)" #  sub console message
$glvlt_subrun    = "$(" " * 2)$(csole -String '├───⬡─' -Color cyan)" #  sub console message
$glvlt_sublast   = "$(" " * 2)$(csole -String '└─▫' -Color cyan)" # put after a return or an output to console
$glvlt_subreturn = "$(" " * 1)$(csole -String '┌┴' -Color cyan)" # put after a return or an output to console
$glvlt_sub_ni    = "$(" " * 2)" #  sub console message

$glvlt_sepapi    = "$(csole -s '⇆' -c magenta)" # speparator icon api
$glvlt_sep       = "$(csole -s '⇒' -c yellow)" # speparator icon
$glvlt_pg        = "$(csole -s '↻' -c green)" # Paganate icon
# error icon emoji red circle
$error_icon      = "$(csole -s '⌫═•' -c red)" # error icon emoji red circle

$global:_glvigor = @{
    rootpath     = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    log          = $glvlt
    logSub       = $glvlt_sub
    logSubReturn = $glvlt_subreturn
    logSubRun    = $glvlt_subrun
    logsubni     = $glvlt_sub_ni
    logsublast   = $glvlt_sublast
    sep          = $glvlt_sep
    pg           = $glvlt_pg
    auth         = $null
    error        = $error_icon
    logcmds      = @{
        api_get        = "$(csole -s '🟢' -c green)─{$(csole -s 'gilab-api' -c magenta)}$('::')$(csole -s 'get' -c green) $glvlt_sepapi";
        api_post       = "$(csole -s '🟡' -c yellow)─{$(csole -s 'gilab-api' -c magenta)}$('::')$(csole -s 'post' -c yellow) $glvlt_sepapi";
        api_update     = "$(csole -s '🟣' -c darkyellow)─$(csole -s 'gilab-api' -c magenta)}$('::')$(csole -s 'update' -c cyan) $glvlt_sepapi";
        api_delete     = "$(csole -s '🔥' -c red)─{$(csole -s 'gilab-api' -c magenta)}$('::')$(csole -s 'delete' -c red) $glvlt_sepapi";
        api_sub        = "$(csole -s "$glvlt_sub_base └──•" -c white)";
        git_command    = "$(csole -s '🔹' -c white)─{$(csole -s 'git' -c magenta)}$('::')$(csole -s 'command' -c blue) $glvlt_sep";
        # git_fetch      = "$(csole -s '🔹' -c green)─{$(csole -s 'git' -c magenta)}$('::')$(csole -s 'fetch' -c green) $glvlt_sep";
        # git_push       = "$(csole -s '🔹' -c darkcyan)─{$(csole -s 'git' -c magenta)}$('::')$(csole -s 'push' -c yellow) $glvlt_sep";
        git_config     = "$(csole -s '📝' -c white)─{$(csole -s 'git' -c white)}$('::')$(csole -s 'cmd' -c white) $glvlt_sep";
        git_github_api = "$(csole -s '🟡' -c white)─$(csole -s 'git' -c magenta)}$('::')$(csole -s 'github api' -c white) $glvlt_sep";
        run            = "$(csole -s '🌀' -c white)─{$(csole -s 'action' -c blue)}$('::')$(csole -s 'run' -c white) $glvlt_sep";

        gitea_api_post  = "$(csole -s '🟡' -c white)─{$(csole -s 'gitea-api' -c magenta)}$('::')$(csole -s 'post' -c yellow) $glvlt_sepapi";
        gitea_api_get   = "$(csole -s '🟢' -c white)─{$(csole -s 'gitea-api' -c magenta)}$('::')$(csole -s 'get' -c green) $glvlt_sepapi";
    }
}

$moduleconfig = @{
    function = @(
        'Request-GitLabAuth',
        'Search-GitLab',
        'Request-MirrorConfig',
        'Register-MirrorConfig',
        'Unregister-MirrorConfig',
        'Request-Project',
        'Request-Issue',
        'Register-Issue',
        'Request-Group',
        'Register-Group',
        'Unregister-Group',
        'Update-Group',
        'Request-Label',
        'Register-Label',
        'Unregister-Label',
        'Update-Label',
        'Request-MergeRequest',
        'Register-MergeRequest',
        'Unregister-MergeRequest',
        'Update-MergeRequest',
        'Request-Blob',
        'Get-LocalRemoteConfig',
        'Add-LocalMirror',
        'Remove-LocalMirror',
        'Get-LocalMirrors',
        'Set-GitOrigin',
        'Get-GitOrigin',
        'Get-GitLog',
        'Register-Project',
        'Request-License',
        'Unregister-Project',
        'Register-GithubRepository',
        'Register-GiteaRepository'
    )
    alias = @()
}

Export-ModuleMember @moduleconfig