# ==============================================================================
# File: Private/Show-GLVStatus.ps1
# ==============================================================================
function ConvertTo-GLVRelativeAge {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory = $false)][string]$Date)

    if (-not $Date) { return 'never' }
    try {
        [timespan]$age = [datetime]::UtcNow - ([datetime]$Date).ToUniversalTime()
        if ($age.TotalMinutes -lt 1) { return 'just now' }
        if ($age.TotalHours -lt 1) { return "$([math]::Floor($age.TotalMinutes))m ago" }
        if ($age.TotalDays -lt 1) { return "$([math]::Floor($age.TotalHours))h ago" }
        return "$([math]::Floor($age.TotalDays))d ago"
    } catch {
        return $Date
    }
}

function Show-GLVStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Status,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Thin', 'Double', 'Rounded', 'None')]
        [string]$BorderStyle = 'Rounded'
    )

    [void]$BorderStyle
    [string]$identity = if ($Status.User.Name) {
        "$($Status.User.Name) (@$($Status.User.Username))"
    } else {
        "@$($Status.User.Username)"
    }
    [string]$cacheState = if ($Status.Cache.Refreshed) { 'refreshed from GitLab' } elseif ($Status.Cache.IsStale) { 'cached / stale' } else { 'cached / ready' }

    [Console]::WriteLine()
    [Console]::WriteLine((New-AsciiGradient -Type fg -Steps @(208, 166, 130, 74, 39, 33) -Format bold -String '  GLVIGOR  /  OWNER SPACE STATUS'))
    [Console]::WriteLine()

    Write-GLVPanel -Title 'Identity, scope & cache' -Data @{
        'Account'       = $identity
        'GitLab host'   = $Status.Host
        'Scope'         = 'Owner access only (personal + owned groups)'
        'Snapshot'      = "$(ConvertTo-GLVRelativeAge $Status.GeneratedAtUtc) · $cacheState"
        'Cache file'    = $Status.Cache.Path
        'Refresh'       = 'glv status -Update'
        'API strategy'  = $Status.ApiPlan.Strategy
    }

    Write-GLVPanel -Title 'Owner-space summary' -Data @{
        'Repositories'    = "$($Status.Summary.Projects) total · $($Status.Summary.PersonalProjects) personal · $($Status.Summary.GroupProjects) group"
        'Namespaces'      = "$(@($Status.Namespaces).Count) active · $($Status.Summary.OwnedGroups) owned GitLab groups"
        'Open issues'     = $Status.Summary.OpenIssues
        'Assigned tasks'  = "$($Status.Summary.AssignedTasks) cached$(if ($Status.ApiPlan.TasksMayBeMore) { '+' } else { '' })"
        'Recently active' = "$($Status.Summary.RecentlyActive) repositories in the last 30 days"
        'Visibility'      = "$($Status.Summary.PrivateProjects) private · $($Status.Summary.InternalProjects) internal · $($Status.Summary.PublicProjects) public"
        'Archived'        = $Status.Summary.ArchivedProjects
    }

    $namespaceRows = @($Status.Namespaces | Select-Object -First 12 | ForEach-Object {
        [pscustomobject]@{
            Namespace = $_.Namespace
            Kind      = $_.Kind
            Repos     = $_.Projects
            Issues    = $_.OpenIssues
            Updated   = ConvertTo-GLVRelativeAge $_.LastActivity
        }
    })
    if ($namespaceRows.Count) {
        Write-GLVTable -Title 'Owned namespace activity' -Rows $namespaceRows -Columns @('Namespace', 'Kind', 'Repos', 'Issues', 'Updated')
    }

    $groupRows = @($Status.Groups | Select-Object -First 12 | ForEach-Object {
        [pscustomobject]@{
            Group      = $_.Path
            Visibility = $_.Visibility
            Parent     = if ($_.ParentId) { $_.ParentId } else { 'root' }
        }
    })
    if ($groupRows.Count) {
        Write-GLVTable -Title 'Owned GitLab groups and subgroups' -Rows $groupRows -Columns @('Group', 'Visibility', 'Parent')
    }

    $recentRows = @($Status.RecentProjects | ForEach-Object {
        [pscustomobject]@{
            Repository = $_.Path
            Space      = $_.Ownership
            Issues     = $_.OpenIssues
            Visibility = $_.Visibility
            Updated    = ConvertTo-GLVRelativeAge $_.LastActivityAtUtc
        }
    })
    if ($recentRows.Count) {
        Write-GLVTable -Title 'Recently updated owner repositories' -Rows $recentRows -Columns @('Repository', 'Space', 'Issues', 'Visibility', 'Updated')
    }

    $taskRows = @($Status.Tasks | Select-Object -First 12 | ForEach-Object {
        [pscustomobject]@{
            Task    = "#$($_.Iid) $($_.Title)"
            Project = $_.Project
            Updated = ConvertTo-GLVRelativeAge $_.UpdatedAtUtc
            Due     = if ($_.DueDate) { $_.DueDate } else { '—' }
            Labels  = (@($_.Labels) -join ', ')
        }
    })
    if ($taskRows.Count) {
        Write-GLVTable -Title 'Assigned open tasks in owner space' -Rows $taskRows -Columns @('Task', 'Project', 'Updated', 'Due', 'Labels')
    } else {
        Write-GLVPanel -Title 'Assigned open tasks' -Data @{
            'Status' = 'No assigned open issues were found in owner repositories.'
        }
    }

    [string]$taskNote = if ($Status.ApiPlan.TasksMayBeMore) {
        "Task scan reached its $($Status.ApiPlan.TaskLimit)-item cap; refresh remains a single task request."
    } else {
        "Task scan stayed within its $($Status.ApiPlan.TaskLimit)-item request cap."
    }
    [Console]::WriteLine("  $taskNote")
    [Console]::WriteLine('  Use glv status -Raw for the complete cached snapshot.')
    [Console]::WriteLine()
}
