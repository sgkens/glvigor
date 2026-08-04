# ==============================================================================
# File: Public/Invoke-GLVigor.ps1
# ==============================================================================
<#
.SYNOPSIS
    Master Router and dispatcher for all GLVigor commands and interactive TUI modules.

.DESCRIPTION
    Provides unified access to all GitLab resource management, git remote/mirroring actions,
    group/label orchestration, package publishing, CI/CD pipelines, visual styling,
    and interactive full-screen alt-buffer TUIs using `uhwriter` router.

.PARAMETER Mode
    Execution mode domain: repo, task, merge, group, label, mirror, git, tag, package, pipeline, auth, ui, help, tui.

.PARAMETER Action
    CRUD Action: Get, Create, Update, Delete, List, Sync, Upload.

.PARAMETER TargetId
    ID or name of the target project, issue, merge request, group, label, or mirror.

.PARAMETER BorderStyle
    TUI Border style: Thin, Double, Rounded, None.

.EXAMPLE
    Invoke-GLVigor -Mode pipeline -Action Get
    glv mirror -Action Get
    glv group -Action List
    glv git -Action Get
    glv ui -Action Create
    glv -Mode tui
#>
function Invoke-GLVigor {
    [CmdletBinding()]
    [Alias('glv')]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Mode,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$Action,

        [Parameter(Mandatory = $false, Position = 2)]
        [string]$TargetId,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Thin', 'Double', 'Rounded', 'None')]
        [string]$BorderStyle = 'Rounded',

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$RemainingArgs
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
    }

    process {
        if (-not $Action -and $Mode -ne 'help') {
            $Action = 'Get'
        }
        $intTargetId = 0
        if ($TargetId -and [int]::TryParse($TargetId, [ref]$intTargetId)) {
            # Parsed target integer id if applicable
        }

        # Comprehensive Route Mapping for ALL Public Cmdlets in GLVigor
        $routes = @{
            'tui'      = { Start-GLVTui -BorderStyle $BorderStyle }

            'repo'     = {
                switch ($Action) {
                    'Get'    { if ($intTargetId -gt 0) { Request-Project -ProjectID $intTargetId } else { Search-GitLab -Type project } }
                    'Create' { Register-Project }
                    'Update' { Update-Project -ProjectID $intTargetId }
                    'Delete' { Unregister-Project -ProjectID $intTargetId }
                    'List'   { Search-GitLab -Type project }
                }
            }

            'task'     = {
                switch ($Action) {
                    'Get'    { Request-Issue -IssueID $intTargetId }
                    'Create' { Register-Issue }
                    'Update' { Update-Issue -IssueID $intTargetId }
                    'Delete' { Unregister-Issue -IssueID $intTargetId }
                    'List'   { Search-GitLab -Type issue }
                    'Sync'   { Request-GitLabIssuesSync }
                }
            }

            'merge'    = {
                switch ($Action) {
                    'Get'    { Request-MergeRequest -MergeRequestID $intTargetId }
                    'Create' { Register-MergeRequest }
                    'Update' { Update-MergeRequest -MergeRequestID $intTargetId }
                    'Delete' { Unregister-MergeRequest -MergeRequestID $intTargetId }
                    'List'   { Search-GitLab -Type mergerequest }
                }
            }

            'group'    = {
                switch ($Action) {
                    'Get'    { Request-Group -GroupID $TargetId }
                    'Create' { Register-Group }
                    'Update' { Update-Group -GroupID $TargetId }
                    'Delete' { Unregister-Group -GroupID $TargetId }
                    'List'   { Search-GitLabGroups }
                }
            }

            'label'    = {
                switch ($Action) {
                    'Get'    { Request-Label -ProjectID $intTargetId }
                    'Create' { Register-Label }
                    'Update' { Update-Label -ProjectID $intTargetId }
                    'Delete' { Unregister-Label -ProjectID $intTargetId }
                    'List'   { Request-Label -ProjectID $intTargetId }
                }
            }

            'mirror'   = {
                switch ($Action) {
                    'Get'    { Request-MirrorConfig -ProjectID $TargetId }
                    'Create' { Register-MirrorConfig }
                    'Update' { Update-MirrorConfig -ProjectID $TargetId }
                    'Delete' { Unregister-MirrorConfig -ProjectID $TargetId; Remove-Localmirrorconfig }
                    'List'   { Get-LocalMirrors }
                    'Sync'   { Send-GitLabMirrorConfig }
                }
            }

            'git'      = {
                switch ($Action) {
                    'Get'    { Get-GitOrigin; Get-LocalRemoteConfig }
                    'Create' { Add-LocalMirror }
                    'Update' { Set-GitOrigin }
                    'Delete' { Remove-LocalMirror }
                    'List'   { Get-GitLog }
                }
            }

            'tag'      = {
                switch ($Action) {
                    'Get'    { Request-GitTag -ProjectID $intTargetId }
                    'Create' { Register-GitTag }
                    'List'   { Request-GitTag -ProjectID $intTargetId }
                }
            }

            'provider' = {
                switch ($Action) {
                    'Create' {
                        Register-GithubRepository
                        Register-GiteaRepository
                    }
                    'Get'    { Request-License }
                    'List'   { Request-Blob }
                }
            }

            'package'  = {
                switch ($Action) {
                    'Upload' { Publish-GenericPackage }
                    default  { Publish-GenericPackage }
                }
            }

            'pipeline' = { Get-GLVPipeline }

            'auth'     = { Request-GitLabAuth }

            'ui'       = {
                switch ($Action) {
                    'Create' { New-AsciiGradient }
                    'Get'    { New-ColorConsole }
                    default  { New-AsciiGradient }
                }
            }

            'search'   = { Search-GitLab }

            'help'     = {
                $topic = if ($Action) { $Action } elseif ($TargetId) { $TargetId } elseif ($RemainingArgs -and $RemainingArgs.Count -gt 0) { $RemainingArgs[0] } else { $null }
                $usePager = ($RemainingArgs -contains '-Pager') -or ($RemainingArgs -contains '--pager') -or ($Action -eq '-Pager') -or ($TargetId -eq '-Pager')
                if ($topic -and $topic -ne '-Pager') {
                    Get-GLVHelp -CmdletName $topic -Pager:$usePager
                } else {
                    Get-GLVHelp -Catalog
                }
            }

            'default'  = {
                if (-not $Mode -or $Mode -eq 'help') {
                    Get-GLVHelp -Catalog
                } else {
                    $usePager = ($RemainingArgs -contains '-Pager') -or ($Action -eq '-Pager')
                    Get-GLVHelp -CmdletName $Mode -Pager:$usePager
                }
            }
        }

        # Dispatch via uhwriter router engine (`New-UHRouter`)
        $dispatchArgs = @()
        if ($Mode) { $dispatchArgs += $Mode }
        if ($Action) { $dispatchArgs += $Action }
        if ($TargetId) { $dispatchArgs += $TargetId }
        if ($RemainingArgs) { $dispatchArgs += $RemainingArgs }

        New-UHRouter -Routes $routes -ArgumentList $dispatchArgs -ModuleName 'glvigor' -RegisterCompleter
    }
}
