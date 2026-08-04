<#
.SYNOPSIS
Deletes GitHub repositories by ID or Owner/Repo name string with confirmation safety controls.

.DESCRIPTION
Remove-GithubRepositories deletes one or multiple GitHub repositories via the GitHub REST API.
It accepts an array of integer IDs or full repository names (e.g. 'owner/repo').
Requires -SkillConfirm:$false to run in yolo / non-interactive execution mode.

.PARAMETER Id
An array of GitHub repository IDs or array of repository objects (piped from Get-GithubRepositories or GitLab/GitHub listing).

.PARAMETER Owner
Optional owner name if repository full name or ID is resolved with owner context.

.PARAMETER ApiKey
The GitHub personal access token used for authentication.

.PARAMETER SkillConfirm
Confirmation safety parameter. Defaults to $true. Must pass -SkillConfirm:$false to bypass interactive deletion confirmation prompt.

.EXAMPLE
Get-GithubRepositories -User "octocat" | Remove-GithubRepositories -SkillConfirm:$false

.EXAMPLE
Remove-GithubRepositories -Id 12345678, 87654321 -SkillConfirm:$false

.NOTES
Requires a GitHub token with delete_repo permissions.
#>

function Remove-GithubRepositories {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([pscustomobject[]])]
    [Alias('glvghrm')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [psobject[]]$Id,
        [Parameter(Mandatory = $false)]
        [string]$Owner,
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        [Parameter(Mandatory = $false)]
        [bool]$SkillConfirm = $true
    )

    begin {
        [System.Collections.Generic.List[pscustomobject]]$deletedResults = [System.Collections.Generic.List[pscustomobject]]::new()
    }

    process {
        # Resolve token
        if (-not $ApiKey -or $ApiKey -eq "") {
            if ($env:GITHUB_API_KEY) {
                $ApiKey = $env:GITHUB_API_KEY
            }
            elseif ($global:_glvigor -and $global:_glvigor.github_apikey) {
                $ApiKey = $global:_glvigor.github_apikey
            }
        }

        if (-not $ApiKey) {
            throw "No GitHub API key provided. Set -ApiKey or \$env:GITHUB_API_KEY."
        }

        foreach ($target in $Id) {
            [string]$repoIdentifier = ""
            [string]$repoOwner = $Owner

            if ($target -is [pscustomobject] -or $target -is [hashtable]) {
                if ($target.full_name) {
                    $repoIdentifier = $target.full_name
                }
                elseif ($target.name -and $target.owner) {
                    $repoIdentifier = "$($target.owner)/$($target.name)"
                }
                elseif ($target.id) {
                    $repoIdentifier = $target.id
                }
            }
            else {
                $repoIdentifier = [string]$target
            }

            if (-not $repoIdentifier) { continue }

            [console]::write("$($global:_glvigor.log) github repository deletion target: $(csole -s "$repoIdentifier" -c $global:__glvigor.colorpallet.red)`n")

            # Check SkillConfirm parameter for yolo mode
            if ($SkillConfirm -eq $true) {
                [console]::write("$($global:_glvigor.logsub) $(csole -s "CONFIRMATION REQUIRED:" -c $global:__glvigor.colorpallet.yellow) Pass -SkillConfirm:\$false to run in yolo mode without prompt.`n")
                $userInput = Read-Host -Prompt "Are you sure you want to delete repository '$repoIdentifier'? [y/N]"
                if ($userInput -notmatch '^(y|yes)$') {
                    [console]::write("$($global:_glvigor.logsub) Deletion of '$repoIdentifier' cancelled by user.`n")
                    continue
                }
            }
            else {
                [console]::write("$($global:_glvigor.logsub) [YOLO MODE] Bypassing confirmation prompt (-SkillConfirm:\$false)...`n")
            }

            try {
                # Determine endpoint
                [string]$github_api_url = ""
                if ($repoIdentifier -match '^[^/]+/[^/]+$') {
                    $github_api_url = "https://api.github.com/repos/$repoIdentifier"
                }
                else {
                    # If ID is passed directly, fetch repo info first to find owner/name
                    $fetchUrl = "https://api.github.com/repositories/$repoIdentifier"
                    $http_header_fetch = @{
                        'Accept'               = 'application/vnd.github+json'
                        'Authorization'        = "Bearer $ApiKey"
                        'X-GitHub-Api-Version' = '2022-11-28'
                    }
                    $repoInfo = Invoke-RestMethod -Uri $fetchUrl -Method Get -Headers $http_header_fetch
                    $github_api_url = "https://api.github.com/repos/$($repoInfo.full_name)"
                }

                $http_header = @{
                    'Accept'               = 'application/vnd.github+json'
                    'Authorization'        = "Bearer $ApiKey"
                    'X-GitHub-Api-Version' = '2022-11-28'
                }

                [console]::write("$($global:_glvigor.logsub) sending DELETE request to $(csole -s "$github_api_url" -c $global:__glvigor.colorpallet.magenta)`n")
                $response = Invoke-RestMethod -Uri $github_api_url -Method Delete -Headers $http_header

                [pscustomobject]$res = [pscustomobject]@{
                    target     = $repoIdentifier
                    status     = 'Deleted'
                    timestamp  = (Get-Date).ToString("o")
                }
                $deletedResults.Add($res)
                [console]::write("$($global:_glvigor.logsub) repository $(csole -s "$repoIdentifier" -c $global:__glvigor.colorpallet.green) deleted successfully.`n")
            }
            catch {
                [console]::write("$($global:_glvigor.logsub) Error deleting repository '$repoIdentifier': $($_.Exception.Message)`n")
                throw
            }
        }
    }

    end {
        return $deletedResults.ToArray()
    }
}

$cmdlet_config = @{
    function = @('Remove-GithubRepositories')
    alias    = @('glvghrm')
}

Export-ModuleMember @cmdlet_config
