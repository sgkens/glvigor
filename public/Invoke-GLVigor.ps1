# ==============================================================================
# File: Public/Invoke-GLVigor.ps1
# ==============================================================================
<#
.SYNOPSIS
    Master Router and TUI dispatcher for all GLVigor commands and interactive modules.

.DESCRIPTION
    Provides unified access to all GitLab resource management, git remote/mirroring actions,
    group/label orchestration, package publishing, CI/CD pipelines, visual styling,
    interactive Creation & Update Form Cards (-it), and clean native help routing via `uhwriter`.

.PARAMETER Mode
    Execution mode domain: status, repo, task, merge, group, label, mirror, git, tag, branch, package, pipeline, auth, ui, help, tui.

.PARAMETER Action
    CRUD Action: Get, Create, Update, Delete, List, Sync, Upload.

.PARAMETER TargetId
    ID or name of the target project, issue, merge request, group, label, or mirror.

.PARAMETER BorderStyle
    TUI Border style: Thin, Double, Rounded, None.

.PARAMETER Raw
    Returns the complete GitLab API objects to the success pipeline instead of rendering TUI output.
    Use this switch when piping glv search or request results into another GLVigor command.

.PARAMETER Update
    Refreshes cached GitLab metadata when used with status mode.

.EXAMPLE
    glv status
    glv status -Update
    glv repo create -it
    glv task update 42 -it
    glv repo list
    glv search help
    glv search 'old issue title' -Type issues -Raw | glv task update -Title 'Updated issue title'
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

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$InputObject,

        [Parameter(Mandatory = $false)]
        [switch]$Raw,

        [Parameter(Mandatory = $false)]
        [switch]$Update,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Thin', 'Double', 'Rounded', 'None')]
        [string]$BorderStyle,

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$RemainingArgs
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
    }

    process {
        # Fallback BorderStyle from global config ~/.phellams/glvigor/config.json if not explicitly specified
        if (-not $BorderStyle -or $BorderStyle -eq "") {
            $BorderStyle = if ($global:GLVTheme -and $global:GLVTheme.BorderStyle) { $global:GLVTheme.BorderStyle } else { 'Rounded' }
        }

        # Normalize Action parameter for modes that do not use CRUD verbs.
        if (-not $Action) {
            if ($Mode -in @('status', 'search', 'help', 'tui', 'pipeline', 'auth')) {
                $Action = ''
            } else {
                $Action = 'Get'
            }
        }

        # Parse RemainingArgs into a parameter dictionary namespace ($boundParams)
        $boundParams = @{}
        if ($InputObject) {
            $boundParams['Data'] = $InputObject
        }
        if ($RemainingArgs) {
            for ($i = 0; $i -lt $RemainingArgs.Count; $i++) {
                $arg = $RemainingArgs[$i]
                if ($arg.StartsWith("-")) {
                    $paramName = $arg.TrimStart("-")
                    if (($i + 1) -lt $RemainingArgs.Count -and -not $RemainingArgs[$i + 1].StartsWith("-")) {
                        $boundParams[$paramName] = $RemainingArgs[$i + 1]
                        $i++
                    } else {
                        $boundParams[$paramName] = $true
                    }
                }
            }
        }

        $intTargetId = 0
        if ($TargetId -and [int]::TryParse($TargetId, [ref]$intTargetId)) {
            # Parsed integer target ID
        }

        # Check for interactive flag (-it, -i, --interactive, -Interactive)
        $isInteractive = ($RemainingArgs -contains '-it') -or
                         ($RemainingArgs -contains '-i') -or
                         ($RemainingArgs -contains '-Interactive') -or
                         ($RemainingArgs -contains '--interactive')

        # Helper: Render raw cmdlet output to TUI panel or table
        $renderOutput = {
            param($data, $title, $type = 'auto')
            if (-not $data) { return }

            if ($Raw) {
                Write-Output $data
                return
            }

            if ($data -is [array] -or $type -eq 'table') {
                Write-GLVTable -Title $title -Rows $data
            } elseif ($data -is [PSCustomObject] -or $data -is [hashtable]) {
                $hash = @{}
                foreach ($prop in $data.PSObject.Properties) {
                    $hash[$prop.Name] = $prop.Value
                }
                Write-GLVPanel -Title $title -Data $hash
            } else {
                Write-Output $data
            }
        }

        # Comprehensive Route Mapping for ALL Public Cmdlets in GLVigor
        $routes = @{
            'tui'      = { Start-GLVTui -BorderStyle $BorderStyle }
            'status'   = { Get-GLVStatus -Update:$Update -Raw:$Raw -BorderStyle $BorderStyle }

            'repo'     = {
                $isGlobal = ($RemainingArgs -contains '-Global') -or ($RemainingArgs -contains '-g')
                switch ($Action) {
                    'Get'    {
                        $res = if ($intTargetId -gt 0) { Request-Project -ProjectID $intTargetId } else { Search-GitLab -Type projects -Raw -Global:$isGlobal }
                        & $renderOutput $res "Project Details"
                    }
                    'Create' {
                        if ($isInteractive) {
                            $fields = @(
                                @{ name = 'Name'; label = 'Project Name'; required = $true },
                                @{ name = 'Path'; label = 'Project Path'; required = $false },
                                @{ name = 'Description'; label = 'Description'; required = $false },
                                @{ name = 'Visibility'; label = 'Visibility (private/public)'; required = $false; default = 'private' }
                            )
                            $inputData = Invoke-GLVFormCard -Title "Create New GitLab Project" -Fields $fields
                            if ($inputData) {
                                Register-Project -Name $inputData['Name'] -Description $inputData['Description'] -Visibility $inputData['Visibility']
                            }
                        } elseif ($boundParams.Count -gt 0) {
                            Register-Project @boundParams
                        } else {
                            Register-Project
                        }
                    }
                    'Update' {
                        if ($isInteractive) {
                            $existing = if ($intTargetId -gt 0) { Request-Project -ProjectID $intTargetId -Raw } else { $null }
                            $fields = @(
                                @{ name = 'ProjectID'; label = 'Project ID'; required = $true; default = "$intTargetId" },
                                @{ name = 'Name'; label = 'Project Name'; required = $false },
                                @{ name = 'Description'; label = 'Description'; required = $false }
                            )
                            $inputData = Invoke-GLVFormCard -Title "Update Project Settings" -Fields $fields -ExistingData $existing
                            if ($inputData) {
                                Update-Project -ProjectID ([int]$inputData['ProjectID']) -Name $inputData['Name'] -Description $inputData['Description']
                            }
                        } elseif ($boundParams.Count -gt 0) {
                            if ($intTargetId -gt 0 -and -not $boundParams.ContainsKey('ProjectID')) { $boundParams['ProjectID'] = $intTargetId }
                            Update-Project @boundParams
                        } else {
                            Update-Project -ProjectID $intTargetId
                        }
                    }
                    'Delete' {
                        if ($boundParams.Count -gt 0) { Unregister-Project @boundParams } else { Unregister-Project -ProjectID $intTargetId }
                    }
                    'List'   {
                        $res = Search-GitLab -Type projects -Raw -Global:$isGlobal
                        & $renderOutput $res "GitLab Repositories" 'table'
                    }
                }
            }

            'task'     = {
                $isGlobal = ($RemainingArgs -contains '-Global') -or ($RemainingArgs -contains '-g')
                switch ($Action) {
                    'Get'    {
                        $res = Request-Issue -IssueID $intTargetId -Raw
                        & $renderOutput $res "Issue #$intTargetId Details"
                    }
                    'Create' {
                        if ($isInteractive) {
                            $fields = @(
                                @{ name = 'ProjectID'; label = 'Project ID'; required = $true },
                                @{ name = 'Title'; label = 'Issue Title'; required = $true },
                                @{ name = 'Description'; label = 'Description'; required = $false }
                            )
                            $inputData = Invoke-GLVFormCard -Title "Create New Issue" -Fields $fields
                            if ($inputData) {
                                Register-Issue -ProjectID ([int]$inputData['ProjectID']) -Title $inputData['Title'] -Description $inputData['Description']
                            }
                        } elseif ($boundParams.Count -gt 0) {
                            Register-Issue @boundParams
                        } else {
                            Register-Issue
                        }
                    }
                    'Update' {
                        if ($isInteractive) {
                            $fields = @(
                                @{ name = 'ProjectID'; label = 'Project ID'; required = $true },
                                @{ name = 'IssueID'; label = 'Issue IID'; required = $true; default = "$intTargetId" },
                                @{ name = 'Title'; label = 'New Title'; required = $false },
                                @{ name = 'StateEvent'; label = 'State (close/reopen)'; required = $false }
                            )
                            $inputData = Invoke-GLVFormCard -Title "Update Issue Settings" -Fields $fields
                            if ($inputData) {
                                Update-Issue -ProjectID ([int]$inputData['ProjectID']) -IssueID ([int]$inputData['IssueID']) -Title $inputData['Title'] -StateEvent $inputData['StateEvent']
                            }
                        } elseif ($boundParams.Count -gt 0) {
                            if ($intTargetId -gt 0 -and -not $boundParams.ContainsKey('IssueID')) { $boundParams['IssueID'] = $intTargetId }
                            Update-Issue @boundParams
                        } else {
                            Update-Issue -IssueID $intTargetId
                        }
                    }
                    'Delete' {
                        if ($boundParams.Count -gt 0) { Unregister-Issue @boundParams } else { Unregister-Issue -IssueID $intTargetId }
                    }
                    'List'   {
                        $res = Search-GitLab -Type issues -Raw -Global:$isGlobal
                        & $renderOutput $res "Project Issues" 'table'
                    }
                    'Sync'   { Request-GitLabIssuesSync }
                }
            }

            'merge'    = {
                $isGlobal = ($RemainingArgs -contains '-Global') -or ($RemainingArgs -contains '-g')
                switch ($Action) {
                    'Get'    {
                        $res = Request-MergeRequest -MergeRequestID $intTargetId -Raw
                        & $renderOutput $res "Merge Request !($intTargetId)"
                    }
                    'Create' {
                        if ($isInteractive) {
                            $fields = @(
                                @{ name = 'ProjectID'; label = 'Project ID'; required = $true },
                                @{ name = 'SourceBranch'; label = 'Source Branch'; required = $true },
                                @{ name = 'TargetBranch'; label = 'Target Branch'; required = $true; default = 'main' },
                                @{ name = 'Title'; label = 'MR Title'; required = $true }
                            )
                            $inputData = Invoke-GLVFormCard -Title "Create Merge Request" -Fields $fields
                            if ($inputData) {
                                Register-MergeRequest -ProjectID ([int]$inputData['ProjectID']) -SourceBranch $inputData['SourceBranch'] -TargetBranch $inputData['TargetBranch'] -Title $inputData['Title']
                            }
                        } else {
                            Register-MergeRequest
                        }
                    }
                    'Update' {
                        if ($isInteractive) {
                            $fields = @(
                                @{ name = 'ProjectID'; label = 'Project ID'; required = $true },
                                @{ name = 'MergeRequestIID'; label = 'MR IID'; required = $true; default = "$intTargetId" },
                                @{ name = 'Title'; label = 'Updated Title'; required = $false }
                            )
                            $inputData = Invoke-GLVFormCard -Title "Update Merge Request" -Fields $fields
                            if ($inputData) {
                                Update-MergeRequest -ProjectID ([int]$inputData['ProjectID']) -MergeRequestID ([int]$inputData['MergeRequestIID']) -Title $inputData['Title']
                            }
                        } else {
                            Update-MergeRequest -MergeRequestID $intTargetId
                        }
                    }
                    'Delete' { Unregister-MergeRequest -MergeRequestID $intTargetId }
                    'List'   {
                        $res = Search-GitLab -Type merge_requests -Raw -Global:$isGlobal
                        & $renderOutput $res "Merge Requests" 'table'
                    }
                }
            }

            'branch'   = {
                switch ($Action) {
                    'Get'    {
                        $res = Request-GitBranch -BranchName $TargetId -Raw
                        & $renderOutput $res "Branch Details: $TargetId"
                    }
                    'Create' {
                        if ($isInteractive) {
                            $fields = @(
                                @{ name = 'ProjectID'; label = 'Project ID'; required = $true },
                                @{ name = 'BranchName'; label = 'New Branch Name'; required = $true },
                                @{ name = 'Ref'; label = 'Ref / Commit SHA'; required = $true; default = 'main' }
                            )
                            $inputData = Invoke-GLVFormCard -Title "Create Repository Branch" -Fields $fields
                            if ($inputData) {
                                Register-GitBranch -ProjectID ([int]$inputData['ProjectID']) -BranchName $inputData['BranchName'] -Ref $inputData['Ref']
                            }
                        } else {
                            Register-GitBranch -BranchName $TargetId -Ref 'main'
                        }
                    }
                    'Delete' { Unregister-GitBranch -BranchName $TargetId }
                    'List'   {
                        $res = Request-GitBranch -Raw
                        & $renderOutput $res "Repository Branches" 'table'
                    }
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

            'package'  = {
                switch ($Action) {
                    'Upload' { Publish-GenericPackage }
                    default  { Publish-GenericPackage }
                }
            }

            'pipeline' = { Get-GLVPipeline }

            'auth'     = {
                $authHost = if ($boundParams['Hostname']) { $boundParams['Hostname'] } elseif ($boundParams['Host']) { $boundParams['Host'] } elseif ($TargetId) { $TargetId } else { $null }
                $authKey  = if ($boundParams['APIKey']) { $boundParams['APIKey'] } elseif ($boundParams['Key']) { $boundParams['Key'] } elseif ($boundParams['Token']) { $boundParams['Token'] } elseif ($Action -and $Action -ne 'Get') { $Action } else { $null }

                $authArgs = @{}
                if ($authHost) { $authArgs['Hostname'] = $authHost }
                if ($authKey)  { $authArgs['APIKey']   = $authKey }

                Request-GitLabAuth @authArgs
            }

            'ui'       = {
                switch ($Action) {
                    'Create' { New-AsciiGradient }
                    'Get'    { New-ColorConsole }
                    default  { New-AsciiGradient }
                }
            }

            'search'   = {
                [string]$searchTitle = if ($Action -and $Action -ne 'Get') { $Action } elseif ($TargetId) { $TargetId } elseif ($boundParams['Title']) { $boundParams['Title'] } else { "" }
                [string]$searchType  = if ($boundParams['Type']) { $boundParams['Type'] } else { 'projects' }
                [bool]$searchGlobal  = [bool]($boundParams['Global'] -or $boundParams['g'])
                $res = Search-GitLab -Title $searchTitle -Type $searchType -Raw -Global:$searchGlobal
                & $renderOutput $res "Search Results: '$searchTitle' ($searchType)" 'table'
            }

            'github'   = {
                $isGlobal = [bool]($boundParams['Global'] -or $boundParams['g'])
                switch ($Action) {
                    'Get'    { Get-GithubRepositories -User $TargetId -Global:$isGlobal }
                    'Create' { Register-GithubRepository -Name $TargetId }
                    'Update' { Update-GithubRepository -Name $TargetId }
                    'Delete' { Remove-GithubRepositories -Id $TargetId }
                    'List'   { Get-GithubRepositories -Global:$isGlobal }
                    default  { Get-GithubRepositories -Global:$isGlobal }
                }
            }

            'gitea'    = {
                $isGlobal = [bool]($boundParams['Global'] -or $boundParams['g'])
                switch ($Action) {
                    'Get'    { Get-GiteaRepositories -User $TargetId -Global:$isGlobal }
                    'Create' { Register-GiteaRepository -Name $TargetId }
                    'Update' { Update-GiteaRepository -Name $TargetId }
                    'Delete' { Remove-GiteaRepositories -Name $TargetId }
                    'List'   { Get-GiteaRepositories -Global:$isGlobal }
                    default  { Get-GiteaRepositories -Global:$isGlobal }
                }
            }

            'help'     = {
                $topic = if ($Action -and $Action -ne 'help') { $Action } elseif ($TargetId) { $TargetId } elseif ($RemainingArgs -and $RemainingArgs.Count -gt 0) { $RemainingArgs[0] } else { $null }
                if ($topic) {
                    Get-GLVHelp -CmdletName $topic
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
