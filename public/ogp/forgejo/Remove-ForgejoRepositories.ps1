<#
.SYNOPSIS
Deletes Forgejo repositories by Owner/Repo name or object pipeline with confirmation safety controls.

.DESCRIPTION
Remove-ForgejoRepositories deletes Forgejo repositories via the Forgejo REST API.
Requires -SkillConfirm:$false to run in yolo / non-interactive mode.

.PARAMETER Owner
The Forgejo username or organization owning the repository.

.PARAMETER Name
The repository name. Can also accept full object pipeline input.

.PARAMETER Hostname
The Forgejo server hostname.

.PARAMETER ApiKey
The Forgejo personal access token.

.PARAMETER SkillConfirm
Confirmation safety parameter. Defaults to $true. Must pass -SkillConfirm:$false to bypass interactive prompt.

.EXAMPLE
Get-ForgejoRepositories -User "myuser" -Hostname "forgejo.local" | Remove-ForgejoRepositories -SkillConfirm:$false

.NOTES
Requires Forgejo delete permissions.
#>

function Remove-ForgejoRepositories {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([pscustomobject[]])]
    [Alias('glvfjrm')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [psobject[]]$Name,
        [Parameter(Mandatory = $false)]
        [string]$Owner,
        [Parameter(Mandatory = $false)]
        [string]$Hostname,
        [Parameter(Mandatory = $false)]
        [string]$ApiKey,
        [Parameter(Mandatory = $false)]
        [bool]$SkillConfirm = $true
    )

    begin {
        [System.Collections.Generic.List[pscustomobject]]$deletedResults = [System.Collections.Generic.List[pscustomobject]]::new()
    }

    process {
        if (-not $ApiKey -or $ApiKey -eq "") {
            if ($env:GITEA_API_KEY) { $ApiKey = $env:GITEA_API_KEY }
        }
        if (-not $Hostname -or $Hostname -eq "") {
            if ($env:GITEA_HOSTNAME) { $Hostname = $env:GITEA_HOSTNAME }
        }
        if (-not $Hostname -or -not $ApiKey) {
            throw "Forgejo Hostname and ApiKey are required for deletion."
        }

        foreach ($target in $Name) {
            [string]$targetOwner = $Owner
            [string]$targetRepo = ""

            if ($target -is [pscustomobject] -or $target -is [hashtable]) {
                if ($target.owner -and $target.name) {
                    $targetOwner = $target.owner
                    $targetRepo = $target.name
                }
                elseif ($target.full_name) {
                    $parts = $target.full_name -split '/'
                    $targetOwner = $parts[0]
                    $targetRepo = $parts[1]
                }
            }
            else {
                [string]$strTarget = [string]$target
                if ($strTarget -match '^[^/]+/[^/]+$') {
                    $parts = $strTarget -split '/'
                    $targetOwner = $parts[0]
                    $targetRepo = $parts[1]
                }
                else {
                    $targetRepo = $strTarget
                }
            }

            if (-not $targetOwner -or -not $targetRepo) { continue }

            [string]$fullIdentifier = "$targetOwner/$targetRepo"
            [console]::write("$($global:_glvigor.log) forgejo repository deletion target: $(csole -s "$fullIdentifier" -c $global:__glvigor.colorpallet.red)`n")

            if ($SkillConfirm -eq $true) {
                [console]::write("$($global:_glvigor.logsub) $(csole -s "CONFIRMATION REQUIRED:" -c $global:__glvigor.colorpallet.yellow) Pass -SkillConfirm:\$false to run in yolo mode.`n")
                $userInput = Read-Host -Prompt "Are you sure you want to delete Forgejo repository '$fullIdentifier'? [y/N]"
                if ($userInput -notmatch '^(y|yes)$') {
                    [console]::write("$($global:_glvigor.logsub) Deletion of '$fullIdentifier' cancelled by user.`n")
                    continue
                }
            }

            try {
                [string]$forgejo_api_url = "https://$Hostname/api/v1/repos/$targetOwner/$targetRepo"
                $http_header = @{
                    'Authorization' = "token $ApiKey"
                }

                $response = Invoke-RestMethod -Uri $forgejo_api_url -Method Delete -Headers $http_header

                [pscustomobject]$res = [pscustomobject]@{
                    target    = $fullIdentifier
                    status    = 'Deleted'
                    timestamp = (Get-Date).ToString("o")
                }
                $deletedResults.Add($res)
                [console]::write("$($global:_glvigor.logsub) Forgejo repository $(csole -s "$fullIdentifier" -c $global:__glvigor.colorpallet.green) deleted successfully.`n")
            }
            catch {
                [console]::write("$($global:_glvigor.logsub) Error deleting Forgejo repository '$fullIdentifier': $($_.Exception.Message)`n")
                throw
            }
        }
    }

    end {
        return $deletedResults.ToArray()
    }
}

$cmdlet_config = @{
    function = @('Remove-ForgejoRepositories')
    alias    = @('glvfjrm')
}

Export-ModuleMember @cmdlet_config
