---
layout: default
title: Issues & Tasks
permalink: /cmdlets/issues/
---

# Issues & Tasks Cmdlets

Cmdlets for managing GitLab issues, tasks, and issue sync.

The router command `glv task list` lists issues only from projects where the authenticated user has GitLab Owner access, including ownership inherited through groups and subgroups. `glv task list -Global` can discover issues in other accessible namespaces, but issue management cmdlets still reject projects outside Owner scope.

## `Request-Issue`
Retrieves issue details or project issues.

```powershell
Request-Issue -ProjectID 12345 -IssueID 42
Request-Issue -ProjectID 12345 -Raw
```

## `Register-Issue`
Creates a new issue in a GitLab project.

```powershell
Register-Issue -ProjectID 12345 -Title 'Fix login bug' -Description 'Details...'
```

## `Update-Issue`
Updates an issue's title, description, or state.

```powershell
Update-Issue -ProjectID 12345 -IssueID 42 -state_event 'close'
```

## `Unregister-Issue`
Deletes an issue from a project.

```powershell
Unregister-Issue -ProjectID 12345 -IssueID 42
```

## `Request-Gitlabissuessync`
Synchronizes GitLab issues with local state.

```powershell
Request-Gitlabissuessync -ProjectID 12345
```
