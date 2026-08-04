---
layout: default
title: Complete Public Cmdlet Reference Catalog
permalink: /cmdlets/
---

# Complete Public Cmdlet Reference Catalog

This index lists **every public cmdlet** exported by the GLVigor module categorized by endpoint type.

---

## Category Directory Index

- [Projects & Repositories (`/cmdlets/projects/`)](#projects--repositories)
- [Issues & Tasks (`/cmdlets/issues/`)](#issues--tasks)
- [Merge Requests (`/cmdlets/mergerequests/`)](#merge-requests)
- [Pipelines & CI/CD (`/cmdlets/pipelines/`)](#pipelines--cicd)
- [Mirroring & Remote Config (`/cmdlets/mirrors/`)](#mirroring--remote-config)
- [Other Git Providers (OGP) (`/cmdlets/ogp/`)](#other-git-providers-ogp)

---

## Projects & Repositories

### `Request-Project` (`glvrp`)
Fetches project details by ID, URL-encoded path, or local `.git/config` context.

```powershell
Request-Project -ProjectID 12345
Request-Project
Request-Project -ProjectID 'group/subgroup/myproject'
```

### `Register-Project` (`glvrgp`)
Creates a new GitLab project repository.

```powershell
Register-Project -Name 'my-new-app' -Visibility 'private'
Register-Project -Name 'lib-common' -Description 'Shared core module' -NamespaceId 99
```

### `Update-Project` (`glvupp`)
Updates settings of an existing GitLab project.

```powershell
Update-Project -ProjectID 12345 -Name 'new-project-name' -Description 'Updated description'
```

### `Unregister-Project` (`glvrmp`)
Deletes a GitLab project repository.

```powershell
Unregister-Project -ProjectID 12345
```

### `Search-GitLab` (`glvs`)
Searches GitLab resources (projects, issues, merge requests, milestones, blobs, users, groups).

```powershell
Search-GitLab -Title 'vigor' -Type projects
Search-GitLab -Title 'authentication' -Type issues -Global
Search-GitLab -Type groups -Raw
```

---

## Issues & Tasks

### `Request-Issue`
Retrieves issue details or project issues.

```powershell
Request-Issue -ProjectID 12345 -IssueID 42
Request-Issue -ProjectID 12345 -Raw
```

### `Register-Issue`
Creates a new issue in a GitLab project.

```powershell
Register-Issue -ProjectID 12345 -Title 'Fix login bug' -Description 'Details...'
```

### `Update-Issue`
Updates an issue's title, description, or state.

```powershell
Update-Issue -ProjectID 12345 -IssueID 42 -state_event 'close'
```

### `Unregister-Issue`
Deletes an issue from a project.

```powershell
Unregister-Issue -ProjectID 12345 -IssueID 42
```

### `Request-Gitlabissuessync`
Synchronizes GitLab issues with local state.

```powershell
Request-Gitlabissuessync -ProjectID 12345
```

---

## Merge Requests

### `Request-MergeRequest`
Retrieves merge request details or lists MRs.

```powershell
Request-MergeRequest -ProjectID 12345 -MergeRequestIID 10
```

### `Register-MergeRequest`
Creates a new merge request.

```powershell
Register-MergeRequest -ProjectID 12345 -SourceBranch 'feature-x' -TargetBranch 'main' -Title 'Add Feature X'
```

### `Update-MergeRequest`
Updates an existing merge request.

```powershell
Update-MergeRequest -ProjectID 12345 -MergeRequestIID 10 -Title 'Updated Title'
```

### `Approve-MergeRequest` (`glvapmr`)
Approves a merge request.

```powershell
Approve-MergeRequest -ProjectID 12345 -MergeRequestIID 10
```

### `Unregister-MergeRequest`
Deletes a merge request.

```powershell
Unregister-MergeRequest -ProjectID 12345 -MergeRequestIID 10
```

---

## Pipelines & CI/CD

### `Get-GLVPipeline` (`glvpipe`)
Retrieves and visualizes GitLab pipeline status or local `.gitlab-ci.yml` flowgraphs.

```powershell
Get-GLVPipeline -Local
Get-GLVPipeline -Live
```

### `Request-GLVJobTrace` (`glvrqtrace`)
Retrieves job execution trace logs.

```powershell
Request-GLVJobTrace -JobID 98765
```

### `Request-GLVJobArtifact` (`glvrqart`)
Downloads CI/CD job artifacts.

```powershell
Request-GLVJobArtifact -ProjectID 12345 -JobID 98765 -OutFile './artifacts.zip'
```

---

## Groups & Labels

### `Request-Group`, `Register-Group`, `Update-Group`, `Unregister-Group`, `Search-GitLabGroups`
Manages GitLab groups and organization hierarchy.

```powershell
Request-Group -GroupID 99
Register-Group -Name 'my-org-group' -Path 'my-org-group'
Search-GitLabGroups
```

### `Request-Label`, `Register-Label`, `Update-Label`, `Unregister-Label`
Manages project and group labels.

```powershell
Request-Label -ProjectID 12345
Register-Label -ProjectID 12345 -Name 'bug' -Color '#FF0000'
```

---

## Branches & Tags

### `Request-GitBranch` (`glvrqbr`), `Register-GitBranch` (`glvrgbr`), `Unregister-GitBranch` (`glvrmbr`)
Manages repository git branches.

```powershell
Request-GitBranch -ProjectID 12345
Register-GitBranch -ProjectID 12345 -BranchName 'feature-new' -Ref 'main'
Unregister-GitBranch -ProjectID 12345 -BranchName 'feature-old'
```

### `Request-GitTag`, `Register-GitTag`
Manages repository tags and release notes.

```powershell
Request-GitTag -ProjectID 12345
Register-GitTag -ProjectID 12345 -TagName 'v1.0.0' -Ref 'main'
```

---

## Mirroring & Remote Configuration

### `Register-MirrorConfig` (`glvrm`), `Request-MirrorConfig`, `Update-MirrorConfig`, `Unregister-MirrorConfig`
Manages push/pull remote mirrors on GitLab, GitHub, and Gitea.

```powershell
Register-MirrorConfig -Endpoint 'github' -Namespace 'myuser' -APIKey 'ghp_xxx'
Get-LocalMirrors
Add-LocalMirror -Name 'github' -Url 'https://github.com/user/repo.git'
```

---

## Packages & Artifacts

### `Publish-GenericPackage`
Publishes generic package artifacts to GitLab Package Registry.

```powershell
Publish-GenericPackage -PackageName 'my-tool' -PackageVersion '1.0.0' -FileName 'app.zip'
```

---

## Authentication & Terminal UI

### `Invoke-GLVigor` (`glv`), `Start-GLVTui`, `Get-GLVHelp` (`glvhelp`), `Request-GitLabAuth`

```powershell
glv repo list
Start-GLVTui
Get-GLVHelp -Catalog
Request-GitLabAuth -ApiKey 'glpat-xxx'
```

---

## Other Git Providers (OGP)

### GitHub Cmdlets
`Get-GithubRepositories` (`glvghls`), `Register-GithubRepository` (`glvrgr`), `Update-GithubRepository` (`glvghup`), `Remove-GithubRepositories` (`glvghrm`).

```powershell
Get-GithubRepositories -User 'octocat' -Global
Remove-GithubRepositories -Id 'octocat/repo' -SkillConfirm:$false
```

### Gitea / Forgejo / Cogs / Codeberg Cmdlets
`Get-GiteaRepositories`, `Register-GiteaRepository`, `Update-GiteaRepository`, `Remove-GiteaRepositories` (and corresponding Cogs/Forgejo/Codeberg cmdlets).

```powershell
Get-GiteaRepositories -User 'giteauser' -Hostname 'gitea.local'
Get-CodebergRepositories -User 'codeberguser'
```
