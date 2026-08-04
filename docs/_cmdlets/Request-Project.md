---
title: Request-Project
alias: glvrp
module: GitLab Projects
synopsis: Retrieves a GitLab project by numeric ID, encoded path, or local Git context.
description: Parameter and usage reference for Request-Project.
---

# `Request-Project` (`glvrp`)

`Request-Project` retrieves one GitLab project and returns the API response object to the success pipeline.

## Syntax

```powershell
# PowerShell syntax
Request-Project [[-ProjectID] <Object>]
```

## Parameters

| Parameter | Type | Required | Pipeline | Default | Description |
| --- | --- | --- | --- | --- | --- |
| `ProjectID` | Object | No | Yes | Local Git context | Numeric project ID or project path. If omitted, GLVigor resolves the project path from the current repository remote. |

## Examples

```powershell
# PowerShell 7.4
Request-Project -ProjectID 12345
Request-Project -ProjectID 'group/subgroup/project'

Set-Location ./existing-project
Request-Project
```

## Output reference

| Stream | Type | Cardinality | Description |
| --- | --- | --- | --- |
| Success | `PSCustomObject` | Zero or one | GitLab project response. |
| Console/log | Text | Multiple messages | Request status and error diagnostics. |
