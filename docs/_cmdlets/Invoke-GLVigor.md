---
title: Invoke-GLVigor
alias: glv
module: GLVigor Core
synopsis: Routes GLVigor domains and actions to public commands, interactive forms, help, and TUI views.
description: Parameter and pipeline reference for Invoke-GLVigor and its glv alias.
---

# `Invoke-GLVigor` (`glv`)

`Invoke-GLVigor` is the module router. It accepts pipeline objects through `InputObject`, emits complete API objects with `Raw`, and forwards unmatched trailing arguments to the selected domain command.

## Syntax

```powershell
# PowerShell syntax
Invoke-GLVigor [[-Mode] <String>] [[-Action] <String>] [[-TargetId] <String>]
    [-InputObject <PSCustomObject>] [-Raw] [-Update] [-BorderStyle <String>]
    [<RemainingArgs>]
```

## Parameters

| Parameter | Type | Required | Pipeline | Default | Description |
| --- | --- | --- | --- | --- | --- |
| `Mode` | String | No | No | Help route | Selects a command domain such as `status`, `repo`, `task`, `merge`, `search`, or `tui`. |
| `Action` | String | No | No | `Get` for resource routes | Selects an action such as `Get`, `Create`, `Update`, `Delete`, `List`, `Sync`, or `Upload`. |
| `TargetId` | String | No | No | None | Supplies a resource ID, IID, branch name, tag, or other route target. |
| `InputObject` | `PSCustomObject` | No | Yes | None | Receives an object from the PowerShell pipeline and forwards it as `Data`. |
| `Raw` | Switch | No | No | `false` | Returns complete objects instead of rendering a TUI table or panel. |
| `Update` | Switch | No | No | `false` | Refreshes the owner-space metadata cache when used with `status`. |
| `BorderStyle` | String | No | No | User configuration or `Rounded` | Accepts `Thin`, `Double`, `Rounded`, or `None`. |
| `RemainingArgs` | String array | No | No | Empty | Captures route-specific parameters such as `-Type`, `-Title`, `-Global`, and `-it`. |

`glv repo list`, `glv task list`, and `glv merge list` are scoped to projects where the authenticated user has GitLab Owner access, including ownership inherited through groups and subgroups. `-Global` broadens list/search discovery but never bypasses the owner guard applied by management cmdlets.

## Rendered output

```powershell
# PowerShell 7.4
glv status
glv status -Update
glv repo list
glv task get 42
glv repo create -it
glv tui
```

## Raw pipeline output

```powershell
# PowerShell 7.4
$projects = @(glv repo list -Raw)
$projects | Select-Object id, name, path_with_namespace

glv search 'old issue title' -Type issues -Raw |
    glv task update -Title 'Updated issue title'
```

See [Pipeline output and Raw mode]({{ '/concepts/pipeline-output/' | relative_url }}) for object-property requirements and mutation safeguards.

## Route reference

| Mode | Common actions | Primary command family |
| --- | --- | --- |
| `status` | `-Update`, `-Raw` | Cache-first owner-space dashboard |
| `repo` | `Get`, `Create`, `Update`, `Delete`, `List` | Project and search commands |
| `task` | `Get`, `Create`, `Update`, `Delete`, `List`, `Sync` | Issue commands |
| `merge` | `Get`, `Create`, `Update`, `Delete`, `List` | Merge request commands |
| `branch` | `Get`, `Create`, `Delete`, `List` | Branch commands |
| `group`, `label`, `tag` | Resource-dependent CRUD actions | Group, label, and tag commands |
| `mirror`, `git` | Resource-dependent actions | Mirror and local Git commands |
| `pipeline`, `package` | Status or upload actions | CI/CD and package commands |
| `github`, `gitea` | `Get`, `Create`, `Update`, `Delete`, `List` | Repository-provider commands |
| `auth`, `search`, `help`, `ui`, `tui` | Mode-specific | Operator and interface commands |

See [Owner-space status dashboard]({{ '/concepts/status-dashboard/' | relative_url }}) for cache behavior, API bounds, and snapshot fields.
