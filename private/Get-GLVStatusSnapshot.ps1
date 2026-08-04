# ==============================================================================
# File: Private/Get-GLVStatusSnapshot.ps1
# ==============================================================================
<#
.SYNOPSIS
    Builds a normalized owner-space status snapshot from a bounded API plan.
.DESCRIPTION
    Uses the authenticated session identity, then fetches owner-access projects,
    owner-access groups, and one capped page of assigned issues. Assigned issues
    are filtered against the owned project set before they enter the snapshot.
#>
function Get-GLVStatusSnapshot {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [int]$TaskLimit = 100
    )

    if (-not $global:_glvigor -or -not $global:_glvigor.auth -or
        -not $global:_glvigor.auth.apipath -or -not $global:_glvigor.auth.apikey) {
        throw [InvalidOperationException]::new(
            'GitLab authentication is required to update status. Run Request-GitLabAuth first.'
        )
    }

    [string]$apiPath = $global:_glvigor.auth.apipath.TrimEnd('/')
    [string]$plainToken = $global:_glvigor.auth.apikey | Undo-SecureString
    $headers = @{
        Authorization = "Bearer $plainToken"
        'Content-Type' = 'application/json'
    }

    $user = $global:_glvigor.auth
    $sourceProjects = @(Get-GLVScopedProjects -Detailed)
    $sourceGroups = @(Get-GLVOwnedGroups)
    $sourceIssues = @(
        Invoke-RestMethod -Uri "$apiPath/issues?scope=assigned_to_me&state=opened&order_by=updated_at&sort=desc&per_page=$TaskLimit&page=1" -Method Get -Headers $headers
    )

    $projectIds = [Collections.Generic.HashSet[long]]::new()
    $projectPaths = [Collections.Generic.Dictionary[long, string]]::new()
    foreach ($project in $sourceProjects) {
        [long]$projectId = $project.id
        [void]$projectIds.Add($projectId)
        $projectPaths[$projectId] = [string]$project.path_with_namespace
    }

    [Collections.Generic.List[pscustomobject]]$projects = [Collections.Generic.List[pscustomobject]]::new()
    foreach ($project in $sourceProjects) {
        $namespace = if ($project.PSObject.Properties['namespace']) { $project.namespace } else { $null }
        [string]$namespacePath = if ($namespace -and $namespace.PSObject.Properties['full_path']) {
            $namespace.full_path
        } elseif ($project.path_with_namespace -match '/') {
            $project.path_with_namespace.Substring(0, $project.path_with_namespace.LastIndexOf('/'))
        } else {
            [string]$user.username
        }
        [string]$namespaceKind = if ($namespace -and $namespace.PSObject.Properties['kind']) {
            $namespace.kind
        } elseif ($namespacePath -eq $user.username) {
            'user'
        } else {
            'group'
        }

        $projects.Add([pscustomobject]@{
            Id                = [long]$project.id
            Name              = [string]$project.name
            Path              = [string]$project.path_with_namespace
            Namespace         = $namespacePath
            NamespaceKind     = $namespaceKind
            Ownership         = if ($namespaceKind -eq 'user') { 'Personal' } else { 'Owned group' }
            Visibility        = [string]$project.visibility
            DefaultBranch     = [string]$project.default_branch
            OpenIssues        = if ($project.PSObject.Properties['open_issues_count']) { [int]$project.open_issues_count } else { 0 }
            LastActivityAtUtc = [string]$project.last_activity_at
            Archived          = [bool]$project.archived
            WebUrl            = [string]$project.web_url
        })
    }

    [Collections.Generic.List[pscustomobject]]$groups = [Collections.Generic.List[pscustomobject]]::new()
    foreach ($group in $sourceGroups) {
        $groups.Add([pscustomobject]@{
            Id         = [long]$group.id
            Name       = [string]$group.name
            Path       = [string]$group.full_path
            Visibility = [string]$group.visibility
            ParentId   = if ($group.PSObject.Properties['parent_id'] -and $null -ne $group.parent_id) { [long]$group.parent_id } else { $null }
            WebUrl     = [string]$group.web_url
        })
    }

    [Collections.Generic.List[pscustomobject]]$tasks = [Collections.Generic.List[pscustomobject]]::new()
    foreach ($issue in $sourceIssues) {
        [long]$issueProjectId = if ($issue.PSObject.Properties['project_id']) { $issue.project_id } else { 0 }
        if (-not $projectIds.Contains($issueProjectId)) { continue }

        $tasks.Add([pscustomobject]@{
            Id             = [long]$issue.id
            Iid            = [int]$issue.iid
            ProjectId      = $issueProjectId
            Project        = $projectPaths[$issueProjectId]
            Title          = [string]$issue.title
            State          = [string]$issue.state
            UpdatedAtUtc   = [string]$issue.updated_at
            DueDate        = if ($issue.PSObject.Properties['due_date']) { [string]$issue.due_date } else { '' }
            Labels         = if ($issue.PSObject.Properties['labels']) { @($issue.labels) } else { @() }
            WebUrl         = [string]$issue.web_url
        })
    }

    $namespaceRows = foreach ($namespaceGroup in ($projects | Group-Object Namespace)) {
        $namespaceProjects = @($namespaceGroup.Group)
        [pscustomobject]@{
            Namespace    = $namespaceGroup.Name
            Kind         = [string]$namespaceProjects[0].Ownership
            Projects     = $namespaceProjects.Count
            OpenIssues   = [int](($namespaceProjects | Measure-Object OpenIssues -Sum).Sum)
            LastActivity = [string](($namespaceProjects | Sort-Object LastActivityAtUtc -Descending | Select-Object -First 1).LastActivityAtUtc)
        }
    }

    [datetime]$recentThreshold = [datetime]::UtcNow.AddDays(-30)
    [int]$recentProjectCount = @($projects | Where-Object {
        $_.LastActivityAtUtc -and ([datetime]$_.LastActivityAtUtc).ToUniversalTime() -ge $recentThreshold
    }).Count
    [int]$openIssueCount = [int](($projects | Measure-Object OpenIssues -Sum).Sum)

    return [pscustomobject]@{
        SchemaVersion  = 1
        GeneratedAtUtc = [datetime]::UtcNow.ToString('o')
        Source          = 'GitLab API'
        Host            = if ($global:_glvigor.auth.PSObject.Properties['hostname']) {
            [string]$global:_glvigor.auth.hostname
        } else {
            ([uri]$apiPath).Host
        }
        User = [pscustomobject]@{
            Id       = [long]$user.id
            Username = [string]$user.username
            Name     = [string]$user.name
            State    = if ($user.httpstatus -eq 200) { 'active' } else { 'unknown' }
            WebUrl   = "$($global:_glvigor.auth.hostname.TrimEnd('/'))/$($user.username)"
        }
        Summary = [pscustomobject]@{
            Projects          = $projects.Count
            PersonalProjects  = @($projects | Where-Object Ownership -eq 'Personal').Count
            GroupProjects     = @($projects | Where-Object Ownership -eq 'Owned group').Count
            OwnedGroups       = $groups.Count
            OpenIssues        = $openIssueCount
            AssignedTasks     = $tasks.Count
            RecentlyActive    = $recentProjectCount
            PrivateProjects   = @($projects | Where-Object Visibility -eq 'private').Count
            InternalProjects  = @($projects | Where-Object Visibility -eq 'internal').Count
            PublicProjects    = @($projects | Where-Object Visibility -eq 'public').Count
            ArchivedProjects  = @($projects | Where-Object Archived).Count
        }
        ApiPlan = [pscustomobject]@{
            Strategy       = 'session identity + paginated owner indexes + one capped assigned-issue query'
            TaskLimit      = $TaskLimit
            TasksMayBeMore = ($sourceIssues.Count -eq $TaskLimit)
        }
        Namespaces     = @($namespaceRows | Sort-Object @{ Expression = 'Projects'; Descending = $true }, Namespace)
        RecentProjects = @($projects | Sort-Object LastActivityAtUtc -Descending | Select-Object -First 12)
        Projects       = @($projects | Sort-Object Path)
        Groups         = @($groups | Sort-Object Path)
        Tasks          = @($tasks | Sort-Object UpdatedAtUtc -Descending | Select-Object -First 20)
    }
}
