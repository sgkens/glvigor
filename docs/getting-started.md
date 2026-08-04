---
title: Installation and authentication
description: Clone GLVigor, import its manifest, configure GitLab credentials, and verify the command surface.
permalink: /getting-started/
---

# Installation and authentication

Install GLVigor from its GitLab repository, import the module manifest, and authenticate the current PowerShell session against a GitLab API v4 endpoint.

## Prerequisites

- PowerShell `7.4.5` or later.
- Git for repository installation.
- A GitLab personal access token with scopes appropriate to the operations you plan to run.

## Clone and import

Run the following from PowerShell. The commands import the development checkout directly; no files are copied into `$Env:PSModulePath`.

```powershell
# PowerShell 7.4
git clone https://gitlab.com/phellams/glvigor.git
Set-Location ./glvigor
Import-Module ./glvigor.psd1 -Force
```

Verify the module and router alias:

```powershell
# PowerShell 7.4
Get-Module glvigor
Get-Command -Module glvigor
Get-Alias glv
```

## Configure GitLab credentials

Environment variables avoid placing a token in command history. Set them for the current process before calling `Request-GitLabAuth` or `glv auth`.

```powershell
# PowerShell 7.4
$Env:GITLAB_HOST = 'gitlab.com'
$Env:GITLAB_API_KEY = 'replace-with-your-token'

Request-GitLabAuth
# Equivalent router command:
glv auth
```

You can also provide both values explicitly:

```powershell
# PowerShell 7.4
Request-GitLabAuth -Hostname 'gitlab.example.com' -APIKey 'replace-with-your-token'
```

<div class="callout warn">
  <div class="callout-bar">Credential handling</div>
  <div class="callout-body"><p>Do not commit tokens to scripts, configuration files, examples, or Git remote URLs. GLVigor converts the GitLab token to a read-only <code>SecureString</code> after authentication, but the original environment variable remains available to the current process.</p></div>
</div>

## Run the first commands

```powershell
# PowerShell 7.4
# Render project results for an operator.
glv repo list

# Return complete project objects to PowerShell.
$projects = glv repo list -Raw
$projects | Select-Object id, name, path_with_namespace

# View command help extracted from module source.
glv help Invoke-GLVigor
```

## Update a development checkout

```powershell
# PowerShell 7.4
Set-Location ./glvigor
git pull --ff-only
Remove-Module glvigor -ErrorAction SilentlyContinue
Import-Module ./glvigor.psd1 -Force
```

## Installation reference

| Requirement | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| PowerShell | Version | Yes | `7.4.5` | Minimum version declared in `glvigor.psd1`. |
| GitLab host | String | No | `gitlab.com` | Set with `-Hostname` or `$Env:GITLAB_HOST`. |
| GitLab token | String | Yes | None | Set with `-APIKey` or `$Env:GITLAB_API_KEY`. |
| Module path | Path | Yes | `./glvigor.psd1` | Manifest imported into the current session. |
| Router alias | String | No | `glv` | Alias for `Invoke-GLVigor`. |
