---
layout: default
title: Mirroring & Remote Configuration
permalink: /cmdlets/mirrors/
---

# Mirroring & Remote Configuration Cmdlets

Cmdlets for managing repository mirrors, remote git configs, and migration endpoints.

## `Register-MirrorConfig` (`glvrm`)
Registers a remote push/pull mirror configuration.

```powershell
Register-MirrorConfig -Endpoint 'github' -Namespace 'myuser' -APIKey 'ghp_xxx'
Register-MirrorConfig -Endpoint 'gitea' -Namespace 'myuser' -GiteaHost 'gitea.local' -Enabled
```

## `Request-MirrorConfig`
Retrieves remote mirror configurations for a project.

```powershell
Request-MirrorConfig -ProjectID 12345
```

## `Update-MirrorConfig`
Updates settings for a mirror configuration.

```powershell
Update-MirrorConfig -ProjectID 12345 -MirrorID 99 -Enabled $true
```

## `Unregister-MirrorConfig` & `Remove-Localmirrorconfig`
Removes a mirror configuration.

```powershell
Unregister-MirrorConfig -ProjectID 12345 -MirrorID 99
Remove-Localmirrorconfig
```

## `Get-LocalMirrors`, `Add-LocalMirror`, `Remove-LocalMirror`, `Send-GitLabMirrorConfig`
Manages local git remotes and synchronizes mirror configs.

```powershell
Get-LocalMirrors
Add-LocalMirror -Name 'github' -Url 'https://github.com/user/repo.git'
Remove-LocalMirror -Name 'github'
Send-GitLabMirrorConfig
```
