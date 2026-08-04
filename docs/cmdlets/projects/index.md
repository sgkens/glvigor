---
layout: default
title: Projects & Repositories
permalink: /cmdlets/projects/
---

# Projects & Repositories Cmdlets

Cmdlets for managing GitLab projects and repositories.

## `Request-Project` (`glvrp`)
Fetches project details by ID, URL-encoded path, or local `.git/config` context.

```powershell
Request-Project -ProjectID 12345
Request-Project
Request-Project -ProjectID 'group/subgroup/myproject'
```

## `Register-Project` (`glvrgp`)
Creates a new GitLab project repository.

```powershell
Register-Project -Name 'my-new-app' -Visibility 'private'
Register-Project -Name 'lib-common' -Description 'Shared core module' -NamespaceId 99
```

## `Update-Project` (`glvupp`)
Updates settings of an existing GitLab project.

```powershell
Update-Project -ProjectID 12345 -Name 'new-project-name' -Description 'Updated description'
```

## `Unregister-Project` (`glvrmp`)
Deletes a GitLab project repository.

```powershell
Unregister-Project -ProjectID 12345
```

## `Search-GitLab` (`glvs`)
Searches GitLab resources (projects, issues, merge requests, milestones, blobs, users, groups).

```powershell
Search-GitLab -Title 'vigor' -Type projects
Search-GitLab -Title 'authentication' -Type issues -Global
Search-GitLab -Type groups -Raw
```
