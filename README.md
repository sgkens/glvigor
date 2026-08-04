GLVigor is an enterprise-grade PowerShell automation module designed for resource management, mirroring orchestration, and interactive TUI execution across GitLab instances.

## ARCHITECTURE TOPOLOGY

```mermaid
graph TD
    A[GLVigor Loader glvigor.psm1] --> B[Master Router Invoke-GLVigor / glv]
    B --> C[Interactive TUI Mode]
    B --> D[Domain Sub-Routers]
    D --> E[Repo / Project Engine]
    D --> F[Task / Issue Engine]
    D --> G[Merge Request Engine]
    D --> H[Group & Label Engine]
    D --> I[Mirror & Git Remote Engine]
    D --> J[Tag, Provider & Package Engine]
    D --> K[Pipeline, Auth & UI Engine]
    A --> L[Direct Public Cmdlets /public]
    A --> M[Helper Frameworks /helpers]
    M --> N[FlowGraph Engine]
    M --> O[UHWriter Router Engine]
```

## CORE FEATURES

- 100% Comprehensive Master Router CLI (`Invoke-GLVigor` / `glv`): Centralized dispatcher mapping all 52 public cmdlets into logical domain routes and CRUD actions.
- REST API Management: Full CRUD operations for projects, issues, merge requests, groups, labels, and mirror configurations.
- Git Remote Mirroring Integration: Automated configuration of local and remote repository mirrors for GitHub, GitLab, and Gitea.
- Interactive Terminal UI: Native ANSI/ASCII styled TUI framework powered by `uhwriter` with zero layout tearing via pre-computed string length padding.
- High Performance Pipeline: Built on .NET Framework primitives (`System.IO`, `System.Text.StringBuilder`) to ensure fast data processing.

## INSTALLATION & IMPORT

Execute the following PowerShell commands to clone and load GLVigor into your session:

```powershell
# Clone module repository
git clone https://gitlab.com/phellams/glvigor.git

# Import module root
Import-Module -Name "/path/to/glvigor/glvigor.psd1" -Force
```

## MASTER ROUTER DISPATCHER (`Invoke-GLVigor` / `glv`)

The master router `Invoke-GLVigor` (aliased as `glv`) provides 100% coverage over all module functionality across 14 modes.

```powershell
# Launch interactive TUI terminal interface
glv -Mode tui

# Display interactive uhwriter command catalog
glv help

# View specific cmdlet help with AST metadata extraction
glv help Request-Project

# View help in full-screen alt-buffer TUI scroller pager
glv help Request-Project -Pager

# Project / Repository operations
glv -Mode repo -Action List
glv -Mode repo -Action Get -TargetId "1024"
glv -Mode repo -Action Create

# Issue / Task tracking & synchronization
glv -Mode task -Action List
glv -Mode task -Action Get -TargetId "42"
glv -Mode task -Action Sync

# Merge request operations
glv -Mode merge -Action List
glv -Mode merge -Action Get -TargetId "12"

# Group & Label management
glv -Mode group -Action List
glv -Mode label -Action Get -TargetId "1024"

# Mirroring & Git local configuration
glv -Mode mirror -Action List
glv -Mode mirror -Action Sync
glv -Mode git -Action Get
glv -Mode git -Action List

# Provider provisioning & Packages
glv -Mode provider -Action Create
glv -Mode package -Action Upload

# Tagging, CI/CD Pipelines, & Auth
glv -Mode tag -Action List
glv -Mode pipeline
glv -Mode auth
```

## AUTHENTICATION SETUP

Authenticate against the GitLab REST API using `Request-GitLabAuth`. Parameters can be supplied directly or read from environment variables (`$env:GITLAB_HOST`, `$env:GITLAB_API_KEY`).

```powershell
# Authentication using explicit credentials
Request-GitLabAuth -Hostname "gitlab.example.com" -APIKey "glpat-xxxxxxxxxxxxxxxxxxxx"

# Authentication using environment variables
$env:GITLAB_HOST = "gitlab.example.com"
$env:GITLAB_API_KEY = "glpat-xxxxxxxxxxxxxxxxxxxx"
Request-GitLabAuth
```

## DIRECT CMDLET USAGE EXAMPLES

### Search GitLab Resources

```powershell
# Search for projects by title
Search-GitLab -Type "projects" -Title "glvigor"

# Search for issues within a specific group
Search-GitLab -Type "issues" -Group "automation" -Title "deployment"
```

### Issue Management

```powershell
# Register a new issue directly
Register-Issue -ProjectID "1024" -Title "Pipeline Failure in CI/CD" -Description "Build failing due to missing environment variable."

# Retrieve issue details directly
Request-Issue -ProjectID "1024" -IssueIID "42"
```

### Local Remote Mirror Configuration

```powershell
# Add local git mirror directly
Add-LocalMirror -Name "github-backup" -Url "git@github.com:org/repo.git"

# Retrieve all configured local mirrors
Get-LocalMirrors
```

## ROUTER COVERAGE MAP (100% COMPLETE)

| Router Mode | Actions Supported | Internal Cmdlets Dispatched |
|---|---|---|
| `repo` | Get, Create, Update, Delete, List | `Request-Project`, `Register-Project`, `Update-Project`, `Unregister-Project`, `Search-GitLab` |
| `task` | Get, Create, Update, Delete, List, Sync | `Request-Issue`, `Register-Issue`, `Update-Issue`, `Unregister-Issue`, `Search-GitLab`, `Request-GitLabIssuesSync` |
| `merge` | Get, Create, Update, Delete, List | `Request-MergeRequest`, `Register-MergeRequest`, `Update-MergeRequest`, `Unregister-MergeRequest`, `Search-GitLab` |
| `group` | Get, Create, Update, Delete, List | `Request-Group`, `Register-Group`, `Update-Group`, `Unregister-Group`, `Search-GitLabGroups` |
| `label` | Get, Create, Update, Delete, List | `Request-Label`, `Register-Label`, `Update-Label`, `Unregister-Label` |
| `mirror` | Get, Create, Update, Delete, List, Sync | `Request-MirrorConfig`, `Register-MirrorConfig`, `Update-MirrorConfig`, `Unregister-MirrorConfig`, `Remove-Localmirrorconfig`, `Get-LocalMirrors`, `Send-GitLabMirrorConfig` |
| `git` | Get, Create, Update, Delete, List | `Get-GitOrigin`, `Get-LocalRemoteConfig`, `Add-LocalMirror`, `Set-GitOrigin`, `Remove-LocalMirror`, `Get-GitLog` |
| `tag` | Get, Create, List | `Request-GitTag`, `Register-GitTag` |
| `provider` | Get, Create, List | `Register-GithubRepository`, `Register-GiteaRepository`, `Request-License`, `Request-Blob` |
| `package` | Upload | `Publish-GenericPackage` |
| `pipeline` | Get | `Get-GLVPipeline` |
| `auth` | Get | `Request-GitLabAuth` |
| `ui` | Get, Create | `New-AsciiGradient`, `New-ColorConsole` |
| `search` | Get | `Search-GitLab` |
| `tui` / `default` | Get | `Start-GLVTui` |
| `help` | Get | `Get-GLVHelp` |

## API REFERENCE

| Cmdlet | Type | Synopsis | Default |
|---|---|---|---|
| `Add-LocalMirror` | Function | Adds a local git remote mirror configuration. | N/A |
| `Get-GitLog` | Function | Fetches git log commits formatted as objects. | N/A |
| `Get-GitOrigin` | Function | Returns current git remote origin configuration. | N/A |
| `Get-GLVHelp` | Function | Displays CLI interactive help documentation. | N/A |
| `Get-GLVPipeline` | Function | Retrieves GitLab CI/CD pipeline statuses. | N/A |
| `Get-LocalMirrors` | Function | Lists all locally configured remote mirrors. | N/A |
| `Get-LocalRemoteConfig` | Function | Parsed git config remote configuration object. | N/A |
| `Invoke-GLVigor` | Function | Master Router and dispatcher for GLVigor commands and interactive TUI modules. | N/A |
| `New-AsciiGradient` | Function | Generates ANSI color gradient strings for TUI rendering. | N/A |
| `New-ColorConsole` | Function | Writes ANSI formatted output to standard console stream. | N/A |
| `Publish-GenericPackage` | Function | Publishes packages to GitLab Generic Package Registry. | N/A |
| `Register-GiteaRepository` | Function | Provisions and links repository to Gitea instance. | N/A |
| `Register-GithubRepository` | Function | Provisions and links repository to GitHub instance. | N/A |
| `Register-GitTag` | Function | Creates and pushes tag to remote repository. | N/A |
| `Register-Group` | Function | Provisions new group on GitLab instance. | N/A |
| `Register-Issue` | Function | Provisions new issue on target GitLab project. | N/A |
| `Register-Label` | Function | Provisions label on project or group. | N/A |
| `Register-MergeRequest` | Function | Creates merge request between branches. | N/A |
| `Register-MirrorConfig` | Function | Provisions remote push mirror on GitLab project. | N/A |
| `Register-Project` | Function | Provisions new project on GitLab instance. | N/A |
| `Remove-LocalMirror` | Function | Deletes local git remote mirror reference. | N/A |
| `Remove-Localmirrorconfig` | Function | Internal cleanup helper for mirror configurations. | N/A |
| `Request-Blob` | Function | Downloads repository raw blob file contents. | N/A |
| `Request-GitLabAuth` | Function | Authenticates user session with GitLab API v4. | N/A |
| `Request-GitLabIssuesSync` | Function | Synchronizes issue states with local tracking store. | N/A |
| `Request-GitTag` | Function | Fetches tags for specified repository. | N/A |
| `Request-Group` | Function | Retrieves group details from GitLab API. | N/A |
| `Request-Issue` | Function | Fetches issue or list of issues from project. | N/A |
| `Request-Label` | Function | Retrieves labels configured on project or group. | N/A |
| `Request-License` | Function | Downloads repository license template/content. | N/A |
| `Request-MergeRequest` | Function | Retrieves details of specified merge request. | N/A |
| `Request-MirrorConfig` | Function | Fetches mirror settings for GitLab project. | N/A |
| `Request-Project` | Function | Fetches project metadata by ID or path. | N/A |
| `Search-GitLab` | Function | Query endpoint for GitLab resources. | N/A |
| `Search-GitLabGroups` | Function | Query endpoint specifically for group resources. | N/A |
| `Send-GitLabMirrorConfig` | Function | Pushes mirror configuration payload to endpoint. | N/A |
| `Set-GitOrigin` | Function | Sets remote origin URL for current git workspace. | N/A |
| `Start-GLVTui` | Function | Launches interactive TUI terminal interface. | N/A |
| `Unregister-Group` | Function | Deletes specified group from GitLab. | N/A |
| `Unregister-Issue` | Function | Deletes specified issue from project. | N/A |
| `Unregister-Label` | Function | Removes label from project or group. | N/A |
| `Unregister-MergeRequest` | Function | Closes or removes merge request. | N/A |
| `Unregister-MirrorConfig` | Function | Deletes push mirror configuration from project. | N/A |
| `Unregister-Project` | Function | Deletes project from GitLab instance. | N/A |
| `Update-Group` | Function | Modifies attributes of existing group. | N/A |
| `Update-Issue` | Function | Modifies attributes of existing issue. | N/A |
| `Update-Label` | Function | Modifies attributes of existing label. | N/A |
| `Update-MergeRequest` | Function | Updates target branch or state of merge request. | N/A |
| `Update-MirrorConfig` | Function | Updates parameters on active push mirror. | N/A |
| `Update-Project` | Function | Modifies settings of existing project. | N/A |
