# ==============================================================================
# File: Public/Request-Gitlabissuessync.ps1
# ==============================================================================
function Request-GitLabIssuesSync {
    <#
    .SYNOPSIS
    Synchronizes issues between GitLab and GitHub repositories.

    .DESCRIPTION
    Fetches issues from a specified GitLab project and mirrors them to a target GitHub repository using REST APIs.

    .PARAMETER projectid
    The GitLab project numeric ID.

    .PARAMETER projectname
    The target GitHub repository name.

    .PARAMETER gituser
    The target GitHub username or organization.

    .EXAMPLE
    Request-GitLabIssuesSync -projectid "1024" -projectname "my-repo" -gituser "my-org"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$projectid,

        [Parameter(Mandatory = $false)]
        [string]$projectname,

        [Parameter(Mandatory = $false)]
        [string]$gituser
    )

    process {
        if (-not $projectid) {
            Write-GLVLog -Message "Missing required projectid parameter." -Level Error
            return
        }

        Write-GLVLog -Message "Synchronizing issues for Project ID: $projectid" -Level Api

        if (-not $global:_glvigor.auth -or -not $global:_glvigor.auth.apipath) {
            Write-GLVLog -Message "GitLab authentication token missing. Please run Request-GitLabAuth." -Level Error
            return
        }

        Assert-GLVProjectOwnerScope -ProjectID $projectid

        $_gitlabApiUrl = "$($global:_glvigor.auth.apipath)/projects/$projectid/issues"
        $_githubApiUrl = "https://api.github.com/repos/$gituser/$projectname/issues"

        $headers = @{
            "Authorization" = "Bearer $($global:_glvigor.auth.apikey | Undo-SecureString)"
            "Content-Type"  = "application/json"
        }

        try {
            $gitlabIssues = Invoke-RestMethod -Uri $_gitlabApiUrl -Headers $headers -Method Get
            if (-not $gitlabIssues -or $gitlabIssues.Count -eq 0) {
                Write-GLVLog -Message "No issues found in GitLab project $projectid." -Level Warning
                return
            }

            foreach ($issue in $gitlabIssues) {
                $IssuePayload_github = @{
                    title     = [string]$issue.title
                    body      = [string]$issue.description
                    state     = [string[]]$issue.state
                    assignees = [string[]]$gituser
                    labels    = [string[]]$issue.labels
                }

                try {
                    Write-GLVLog -Message "Mirroring issue #$($issue.id): $($issue.title) to GitHub" -Level Info
                    $githubHeaders = @{
                        "Authorization" = "Bearer $ENV:GITHUB_API_KEY"
                        "Content-Type"  = "application/json"
                    }
                    $response = Invoke-RestMethod -Uri $_githubApiUrl -Method 'POST' -Headers $githubHeaders -Body ($IssuePayload_github | ConvertTo-Json -Depth 5)
                    Write-GLVLog -Message "Successfully mirrored issue #$($issue.id)" -Level Success
                }
                catch {
                    Write-GLVLog -Message "Failed to mirror issue: $($_.Exception.Message)" -Level Error
                }
            }
        }
        catch {
            Write-GLVLog -Message "Issue sync query error: $($_.Exception.Message)" -Level Error
        }
    }
}
