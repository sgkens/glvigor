---
layout: default
title: Other Git Providers (OGP) Concepts & CRUD
permalink: /concepts/ogp-providers/
---

# Other Git Providers (OGP) Concepts & CRUD

GLVigor provides repository management for **GitHub**, **Gitea**, **Cogs**, **Forgejo**, and **Codeberg** under `public/ogp/`.

---

## Supported Provider Matrix

| Provider | Folder Path | Get Cmdlet | Register Cmdlet | Update Cmdlet | Remove Cmdlet |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **GitHub** | `public/ogp/github/` | `Get-GithubRepositories` | `Register-GithubRepository` | `Update-GithubRepository` | `Remove-GithubRepositories` |
| **Gitea** | `public/ogp/gitea/` | `Get-GiteaRepositories` | `Register-GiteaRepository` | `Update-GiteaRepository` | `Remove-GiteaRepositories` |
| **Cogs** | `public/ogp/cogs/` | `Get-CogsRepositories` | `Register-CogsRepository` | `Update-CogsRepository` | `Remove-CogsRepositories` |
| **Forgejo** | `public/ogp/forgejo/` | `Get-ForgejoRepositories` | `Register-ForgejoRepository` | `Update-ForgejoRepository` | `Remove-ForgejoRepositories` |
| **Codeberg** | `public/ogp/codeberg/` | `Get-CodebergRepositories` | `Register-CodebergRepository` | `Update-CodebergRepository` | `Remove-CodebergRepositories` |

---

## Safety & Deletion Controls (`-SkillConfirm:$false`)

Deletion cmdlets in OGP (such as `Remove-GithubRepositories` and `Remove-GiteaRepositories`) implement high-impact confirmation safety controls.

By default, executing deletion cmdlets prompts interactively:

```powershell
Remove-GithubRepositories -Id "octocat/test-repo"
# Output: [CONFIRMATION REQUIRED] Pass -SkillConfirm:$false for non-interactive execution.
# Prompt: Are you sure you want to delete repository 'octocat/test-repo'? [y/N]
```

For non-interactive CI/CD execution, explicitly pass `-SkillConfirm:$false`:

```powershell
# Pipeline execution / Non-interactive deletion
Get-GithubRepositories -User "octocat" | Remove-GithubRepositories -SkillConfirm:$false
```

---

## Ownership Scoping (`-Global`)

All `Get-*` listing cmdlets for git providers automatically filter output to items owned by the authenticated user or managed organization space.

To query all public/global repositories on the server, append `-Global`:

```powershell
# Default (User & Org owned space)
Get-GithubRepositories

# Global (All public & accessible repositories)
Get-GithubRepositories -Global
```
