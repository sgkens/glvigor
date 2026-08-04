---
layout: default
title: Merge Requests
permalink: /cmdlets/mergerequests/
---

# Merge Requests Cmdlets

Cmdlets for managing and approving GitLab merge requests.

## `Request-MergeRequest`
Retrieves merge request details or lists MRs.

```powershell
Request-MergeRequest -ProjectID 12345 -MergeRequestIID 10
```

## `Register-MergeRequest`
Creates a new merge request.

```powershell
Register-MergeRequest -ProjectID 12345 -SourceBranch 'feature-x' -TargetBranch 'main' -Title 'Add Feature X'
```

## `Update-MergeRequest`
Updates an existing merge request.

```powershell
Update-MergeRequest -ProjectID 12345 -MergeRequestIID 10 -Title 'Updated Title'
```

## `Approve-MergeRequest` (`glvapmr`)
Approves a merge request.

```powershell
Approve-MergeRequest -ProjectID 12345 -MergeRequestIID 10
```

## `Unregister-MergeRequest`
Deletes a merge request.

```powershell
Unregister-MergeRequest -ProjectID 12345 -MergeRequestIID 10
```
