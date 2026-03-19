<#
.SYNOPSIS
Gets the git log with filtering options.

.DESCRIPTION
Gets the git log with filtering options.

.PARAMETER Branch
The branch to filter the log by.

.PARAMETER CommitID
The commit ID to filter the log by.

.PARAMETER CommitIDShort
The short commit ID to filter the log by.

.PARAMETER CommitTitle
The commit title to filter the log by.

.EXAMPLE
Get-GitLog -Branch "main"

.NOTES
#>

using module ..\..\ColorConsole\libs\cmdlets\New-ColorConsole.psm1

function Get-GitLog {
    [cmdletbinding()]
    [OutputType([pscustomobject])]
    [Alias('glvgl')]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Branch,
        [Parameter(Mandatory=$false)]
        [string]$CommitID,
        [Parameter(Mandatory=$false)]
        [string]$CommitIDShort,
        [Parameter(Mandatory=$false)]
        [string]$CommitTitle
    )
    process {
        [console]::write("$($global:_glvigor.log) getting git log`n")
        $gitlog = git log --pretty=format:'%H|%h|%an|%ar|%s'
        $logobjects = @()
        foreach($log in $gitlog){
            $logparts = $log.Split('|')
            $logobject = [pscustomobject]@{
                CommitID = $logparts[0]
                CommitIDShort = $logparts[1]
                Author = $logparts[2]
                Date = $logparts[3]
                Title = $logparts[4]
            }
            $logobjects += $logobject
        }

        if($Branch){
            $logobjects = $logobjects | Where-Object { (git branch --contains $_.CommitID) -like "* $Branch" }
        }
        if($CommitID){
            $logobjects = $logobjects | Where-Object { $_.CommitID -eq $CommitID }
        }
        if($CommitIDShort){
            $logobjects = $logobjects | Where-Object { $_.CommitIDShort -eq $CommitIDShort }
        }
        if($CommitTitle){
            $logobjects = $logobjects | Where-Object { $_.Title -like "*$CommitTitle*" }
        }

        return $logobjects
    }
}

$cmdletconfig = @{
    function = @("Get-GitLog")
    alias    = @("glvgl")
}

Export-Modulemember @cmdletconfig