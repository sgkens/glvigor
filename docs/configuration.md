---
title: Configuration
description: Configure GLVigor theme settings, GitLab authentication, provider credentials, namespace filters, and mirror defaults.
permalink: /configuration/
---

# Configuration

GLVigor reads display settings from a per-user JSON file and resolves API credentials and namespace defaults from parameters or environment variables.

## User configuration file

At module import, GLVigor checks `$HOME/.phellams/glvigor/config.json`. Missing files and invalid JSON leave the built-in theme values unchanged.

`$HOME/.phellams/glvigor/config.json`

```json
{
  "BorderStyle": "Rounded",
  "PrimaryHex": "#00FFAA",
  "SecondaryHex": "#0088FF"
}
```

The current loader recognizes only these three properties.

| Property | Type | Required | Default | Allowed values |
| --- | --- | --- | --- | --- |
| `BorderStyle` | String | No | `Rounded` | `Thin`, `Double`, `Rounded`, `None` |
| `PrimaryHex` | String | No | `#00FFAA` | CSS-style six-digit hexadecimal color |
| `SecondaryHex` | String | No | `#0088FF` | CSS-style six-digit hexadecimal color |

## Status metadata cache

The owner-space dashboard stores normalized metadata in <code>$HOME/.phellams/glvigor/status-cache.json</code>. <code>glv status</code> reads that file without contacting GitLab. <code>glv status -Update</code> refreshes it, and a missing or incompatible cache triggers one initial refresh.

The cache is written atomically and never contains the API token. Snapshots older than 24 hours are shown as stale but remain cache-first until the user explicitly supplies <code>-Update</code>.

## GitLab authentication

`Request-GitLabAuth` gives explicit parameters precedence over environment variables. If no host is supplied, it uses `gitlab.com`.

```powershell
# PowerShell 7.4
$Env:GITLAB_HOST = 'gitlab.com'
$Env:GITLAB_API_KEY = 'replace-with-your-token'
$Env:GITLAB_USER = 'your-user-name'
$Env:GITLAB_ORG = 'your-group-path'

Request-GitLabAuth
```

## Repository provider credentials

GitHub cmdlets use GitHub-specific variables. Gitea-compatible providers currently share the Gitea token and hostname variables, except Codeberg, which can override its hostname.

```powershell
# PowerShell 7.4
$Env:GITHUB_API_KEY = 'replace-with-your-token'
$Env:GITHUB_USER = 'your-user-name'
$Env:GITHUB_ORG = 'your-organization'

$Env:GITEA_API_KEY = 'replace-with-your-token'
$Env:GITEA_HOSTNAME = 'gitea.example.com'
$Env:CODEBERG_HOSTNAME = 'codeberg.org'
```

## Owner scope

GLVigor manages only projects where GitLab reports the authenticated user at Owner access level (`min_access_level=50`). This includes personal projects and projects inherited from groups or subgroups the user owns. Project, issue, and merge-request discovery uses the owner collection and per-project endpoints directly. Every direct project cmdlet validates its `ProjectID` or `path_with_namespace` against the same owner collection before sending a resource request.

`-Global` broadens discovery only. It does not bypass owner validation on create, request, update, delete, branch, tag, issue, merge-request, label, package, pipeline, job, or mirror operations. Piping a globally discovered object into a management cmdlet still triggers the owner guard.

```powershell
# PowerShell 7.4
Get-GithubRepositories
Get-GithubRepositories -Global

Search-GitLab -Type projects -Global -Raw
glv task list -Global

# Rejected unless project 12345 is in the authenticated user's Owner scope.
Request-Project -ProjectID 12345
```

## Mirror environment variables

Mirror commands use separate defaults because a source GitLab endpoint and a destination provider may both require credentials.

```powershell
# PowerShell 7.4
$Env:GLV_MIRROR_USER = 'destination-user'
$Env:GLV_MIRROR_APIKEY = 'replace-with-destination-token'
$Env:GLV_MIRROR_NAMESPACE = 'destination-namespace'
$Env:GMM_HOSTNAME = 'gitlab.com'
$Env:GMM_USER = 'source-user'
$Env:GMM_APIKEY = 'replace-with-source-token'
```

## Environment variable reference

| Variable | Consumer | Required | Default | Purpose |
| --- | --- | --- | --- | --- |
| `GITLAB_HOST` | GitLab authentication and mirror commands | No | `gitlab.com` for authentication | GitLab hostname or URL. |
| `GITLAB_API_KEY` | GitLab authentication and issue sync | Yes for GitLab API calls | None | GitLab personal access token. |
| `GITLAB_USER` | Namespace filter | No | Authenticated user | Personal namespace. |
| `GITLAB_ORG` | Namespace filter | No | None | Managed GitLab group namespace. |
| `GITHUB_API_KEY` | GitHub commands and issue sync | Yes for authenticated mutations | None | GitHub token. |
| `GITHUB_USER` | Namespace filter | No | Authenticated provider user | GitHub personal namespace. |
| `GITHUB_ORG` | Namespace filter | No | None | GitHub organization namespace. |
| `GITEA_API_KEY` | Gitea, Forgejo, Cogs, and Codeberg commands | Depends on operation | None | Gitea-compatible API token. |
| `GITEA_HOSTNAME` | Gitea, Forgejo, and Cogs commands | Yes unless passed explicitly | None | Gitea-compatible service host. |
| `CODEBERG_HOSTNAME` | Codeberg commands | No | `codeberg.org` | Codeberg-compatible host override. |
| `GLV_MIRROR_USER` | Local mirror commands | Depends on endpoint | None | Destination account. |
| `GLV_MIRROR_APIKEY` | Mirror registration | Depends on endpoint | None | Destination token. |
| `GLV_MIRROR_NAMESPACE` | Mirror registration | Depends on endpoint | None | Destination namespace. |
| `GMM_HOSTNAME` | Mirror synchronization | No | None | Source GitLab host. |
| `GMM_USER` | Mirror synchronization | No | None | Source GitLab user. |
| `GMM_APIKEY` | Mirror synchronization | Yes when not passed | None | Source GitLab token. |
