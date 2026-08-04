# ==============================================================================
# File: Public/Get-GLVPipeline.ps1
# ==============================================================================
<#
.SYNOPSIS
    Visualizes GitLab CI/CD pipelines and local .gitlab-ci.yml configurations using Flowgraph.

.DESCRIPTION
    Queries the GitLab REST API for project pipelines/jobs or parses local `.gitlab-ci.yml` files,
    rendering an interactive ASCII stage flow graph or DAG dependency graph. Supports live-monitored execution via `-Live`.

.PARAMETER ProjectID
    The ID or path of the GitLab project.

.PARAMETER PipelineID
    The ID of a specific pipeline to visualize.

.PARAMETER Local
    Switch to parse and render local `.gitlab-ci.yml` stages instead of API pipelines.

.PARAMETER Live
    Switch to run in a continuous live-refresh loop (polling status every 3 seconds).

.PARAMETER MockStatus
    Optional mock state preset for testing ('default', 'half-complete', 'failure').

.EXAMPLE
    Get-GLVPipeline -Local -MockStatus half-complete
    Get-GLVPipeline -Local -MockStatus failure
#>

function Get-GLVPipeline {
    [CmdletBinding()]
    [Alias('glvpipe')]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [object]$ProjectID,

        [Parameter(Mandatory = $false)]
        [int]$PipelineID,

        [Parameter(Mandatory = $false)]
        [switch]$Local,

        [Parameter(Mandatory = $false)]
        [switch]$Live,

        [Parameter(Mandatory = $false)]
        [ValidateSet('default', 'half-complete', 'failure')]
        [string]$MockStatus = 'default',

        [Parameter(Mandatory = $false)]
        [int]$RefreshIntervalSeconds = 3
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
    }

    process {
        # Dot-source clap helper if needed
        $clapPath = Join-Path $global:_glvigor.rootpath 'helpers/clap.ps1'
        if (Test-Path $clapPath) { . $clapPath }

        if ($Local) {
            Write-GLVLog -Message "Parsing local .gitlab-ci.yml pipeline configuration..." -Level Info
            $ciFile = Join-Path (Get-Location).Path '.gitlab-ci.yml'

            if (-not (Test-Path -Path $ciFile)) {
                Write-GLVLog -Message "No .gitlab-ci.yml file found in current directory." -Level Error
                return
            }

            $content = Get-Content -Path $ciFile -Raw

            # Parse jobs & needs
            $flowNodes = [System.Collections.Generic.List[hashtable]]::new()
            $flowEdges = [System.Collections.Generic.List[hashtable]]::new()
            $jobs = [ordered]@{}

            # Regex match job blocks
            $blocks = $content -split '\n(?=[\w-]+:)'
            foreach ($block in $blocks) {
                if ($block -match '^([\w-]+):\s*\n') {
                    $jobName = $matches[1]
                    if ($jobName -eq 'stages') { continue }

                    $stageName = 'test'
                    if ($block -match 'stage:\s*([\w-]+)') { $stageName = $matches[1] }

                    [string[]]$needs = @()
                    if ($block -match 'needs:\s*\[([^\]]+)\]') {
                        $needs = $matches[1] -split ',' | ForEach-Object { $_.Trim().Trim('"').Trim("'") }
                    }

                    $jobs[$jobName] = @{
                        Stage = $stageName
                        Needs = $needs
                    }
                }
            }

            # Build Nodes & apply MockStatus styling if requested
            foreach ($jobName in $jobs.Keys) {
                $j = $jobs[$jobName]
                $statusType = 'Process'

                if ($MockStatus -eq 'half-complete') {
                    if ($j.Stage -eq 'build') { $statusType = 'Success' }
                    elseif ($j.Stage -eq 'test') { $statusType = 'Process' }
                    elseif ($j.Stage -eq 'security' -or $j.Stage -eq 'deploy') { $statusType = 'Default' }
                }
                elseif ($MockStatus -eq 'failure') {
                    if ($j.Stage -eq 'build') { $statusType = 'Success' }
                    elseif ($jobName -eq 'test_integration') { $statusType = 'Error' }
                    elseif ($j.Stage -eq 'test') { $statusType = 'Success' }
                    else { $statusType = 'Default' }
                }
                else {
                    if ($j.Stage -eq 'build') { $statusType = 'Start' }
                    elseif ($j.Stage -eq 'deploy') { $statusType = 'End' }
                }

                $flowNodes.Add((New-FlowNode -Id $jobName -Label $jobName -Type $statusType -Meta $j.Stage.ToUpper()))

                $needsList = @($j.Needs)
                if ($needsList.Length -gt 0) {
                    foreach ($parent in $needsList) {
                        if ($jobs.Contains($parent)) {
                            $flowEdges.Add((New-FlowEdge -From $parent -To $jobName))
                        }
                    }
                }
            }

            # Fallback if no needs edges defined
            if ($flowEdges.Count -eq 0) {
                $prevJob = $null
                foreach ($jobName in $jobs.Keys) {
                    if ($prevJob) { $flowEdges.Add((New-FlowEdge -From $prevJob -To $jobName)) }
                    $prevJob = $jobName
                }
            }

            Write-Host ""
            $layoutType = if ($flowEdges.Count -gt 0) { 'TopDown' } else { 'Pipeline' }
            New-FlowGraph -Nodes $flowNodes.ToArray() -Edges $flowEdges.ToArray() -Layout $layoutType -Title "GITLAB-CI 10-JOB DAG PIPELINE ($($MockStatus.ToUpper()))" | Show-FlowGraph
            Write-Host ""
            return
        }

        # API Pipeline mode
        $targetProj = $ProjectID
        if (-not $targetProj) {
            $gitCtx = Get-GitContext
            if ($gitCtx) { $targetProj = [System.Web.HttpUtility]::UrlEncode($gitCtx.ProjectPath) }
        }

        if (-not $targetProj) {
            Write-GLVLog -Message "Missing ProjectID parameter and no local .git context found." -Level Error
            return
        }

        if (-not $global:_glvigor.auth -or -not $global:_glvigor.auth.apipath) {
            Write-GLVLog -Message "GitLab authentication token missing. Please run Request-GitLabAuth." -Level Error
            return
        }

        Assert-GLVProjectOwnerScope -ProjectID $targetProj

        do {
            try {
                $plainToken = $global:_glvigor.auth.apikey | Undo-SecureString
                $headers = @{
                    "Authorization" = "Bearer $plainToken"
                    "Content-Type"  = "application/json"
                }

                $targetPipeId = $PipelineID
                if ($targetPipeId -le 0) {
                    $pipes = Invoke-RestMethod -Uri "$($global:_glvigor.auth.apipath)/projects/$targetProj/pipelines?per_page=1" -Headers $headers -Method Get
                    if ($pipes -and $pipes.Count -gt 0) { $targetPipeId = $pipes[0].id }
                }

                if (-not $targetPipeId -or $targetPipeId -le 0) {
                    Write-GLVLog -Message "No pipelines found for project $targetProj." -Level Warning
                    return
                }

                $jobs = Invoke-RestMethod -Uri "$($global:_glvigor.auth.apipath)/projects/$targetProj/pipelines/$targetPipeId/jobs" -Headers $headers -Method Get

                if (-not $jobs -or $jobs.Count -eq 0) {
                    Write-GLVLog -Message "No jobs found for Pipeline #$targetPipeId." -Level Warning
                    return
                }

                if ($Live) { [Console]::Clear() }

                $flowNodes = [System.Collections.Generic.List[hashtable]]::new()
                $flowEdges = [System.Collections.Generic.List[hashtable]]::new()
                $prevJobId = $null

                foreach ($job in $jobs) {
                    $statusType = switch ($job.status) {
                        'success'  { 'Success' }
                        'running'  { 'Process' }
                        'failed'   { 'Error' }
                        'pending'  { 'Warning' }
                        'canceled' { 'Default' }
                        default    { 'Info' }
                    }

                    $nodeId = "$($job.id)"
                    $label  = "$($job.name)"
                    $meta   = "$($job.stage): $($job.status.ToUpper())"

                    $flowNodes.Add((New-FlowNode -Id $nodeId -Label $label -Type $statusType -Meta $meta))

                    if ($prevJobId) {
                        $flowEdges.Add((New-FlowEdge -From $prevJobId -To $nodeId))
                    }
                    $prevJobId = $nodeId
                }

                Write-Host ""
                $graphTitle = "PIPELINE #$targetPipeId STATUS" + (if ($Live) { " (LIVE REFRESH - ESC/Ctrl+C to quit)" } else { "" })
                New-FlowGraph -Nodes $flowNodes.ToArray() -Edges $flowEdges.ToArray() -Layout Pipeline -Title $graphTitle | Show-FlowGraph
                Write-Host ""

                if (-not $Live) { break }
                Start-Sleep -Seconds $RefreshIntervalSeconds
            }
            catch {
                Write-GLVLog -Message "Pipeline query error: $($_.Exception.Message)" -Level Error
                break
            }
        } while ($Live)
    }
}
