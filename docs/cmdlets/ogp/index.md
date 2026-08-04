---
layout: default
title: Other Git Providers (OGP)
permalink: /cmdlets/ogp/
---

# Other Git Providers (OGP) Cmdlets

Standardized repository CRUD cmdlets for **GitHub**, **Gitea**, **Cogs**, **Forgejo**, and **Codeberg**.

## GitHub Cmdlets
- `Get-GithubRepositories` (`glvghls`): List repositories.
- `Register-GithubRepository` (`glvrgr`): Create repository.
- `Update-GithubRepository` (`glvghup`): Update repository.
- `Remove-GithubRepositories` (`glvghrm`): Delete repository (`-SkillConfirm:$false`).

```powershell
Get-GithubRepositories -User 'octocat' -Global
Remove-GithubRepositories -Id 'octocat/repo' -SkillConfirm:$false
```

## Gitea Cmdlets
- `Get-GiteaRepositories` (`glvgtls`): List repositories.
- `Register-GiteaRepository` (`glvrgtr`): Create repository.
- `Update-GiteaRepository` (`glvgtup`): Update repository.
- `Remove-GiteaRepositories` (`glvgtrm`): Delete repository (`-SkillConfirm:$false`).

```powershell
Get-GiteaRepositories -User 'giteauser' -Hostname 'gitea.local'
Remove-GiteaRepositories -Name 'giteauser/repo' -Hostname 'gitea.local' -SkillConfirm:$false
```

## Cogs Cmdlets
- `Get-CogsRepositories` (`glvcgls`), `Register-CogsRepository` (`glvrcgr`), `Update-CogsRepository` (`glvcgup`), `Remove-CogsRepositories` (`glvcgrm`).

## Forgejo Cmdlets
- `Get-ForgejoRepositories` (`glvfjls`), `Register-ForgejoRepository` (`glvrfjr`), `Update-ForgejoRepository` (`glvfjup`), `Remove-ForgejoRepositories` (`glvfjrm`).

## Codeberg Cmdlets
- `Get-CodebergRepositories` (`glvcbls`), `Register-CodebergRepository` (`glvrcbr`), `Update-CodebergRepository` (`glvcbup`), `Remove-CodebergRepositories` (`glvcbrm`).
