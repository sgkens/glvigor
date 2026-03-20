using module ..\..\..\securestring\undo-securestring.psm1
using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\private\Confirm-GitLabAuth.psm1

<#
.SYNOPSIS
Unregister-Issue removes an issue from GitLab.

.DESCRIPTION
Unregister-Issue removes an issue from GitLab.

.PARAMETER ProjectID
The ID of the project to remove the issue from.

.PARAMETER IssueIID
The IID of the issue to remove.

.PARAMETER Data
Data to be passed in via the pipeline.

.PARAMETER NoConfirmation
If specified, NoConfirmation:$true will be passed to the function. bypassing issue deletion confirmation name prompt

.EXAMPLE
Unregister-Issue -ProjectID 1 -IssueIID 1

.NOTES
Requires authentication via `Request-GitLabAuth`.
#>

function Unregister-Issue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [pscustomobject]$data,
        [Parameter(Mandatory=$false)]
        [int]$ProjectID,
        [Parameter(Mandatory=$false)]
        [int]$IssueIID
    )

    process {

        #=== AUTH AND PIPELINE DATA ===
        # change logtype and newline depending on if data is coming from pipeline
        # helps with readability
        $currentLine = [Console]::CursorTop
        [string]$initlogType = ''
        [string]$pipedCmdlet = ''
        if ($data) {
            $initlogType = 'logsubrun'
            [string]$pipedCmdlet = "($(csole -s "unregister-issue" -c blue))"
            [Console]::SetCursorPosition(0, $currentLine - 1) # move up one line if from pipeline removes space from log
            [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-issue-unregister-request' -c yellow) $pipedCmdlet...`n")
        }
        else {
            $initlogType = 'log';
            [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-issue-unregister-request' -c yellow)...`n")
        }
        # call auth check
        confirm-GitLabAuth
        #=== AUTH AND PIPELINE DATA ===

        try {
            if(!$data.id -and !$IssueIID){
                throw "No data from pipe or -issueiid param specified"
                return
            }elseif($data.id){
                $IssueIID = $data.iid
                $issue_title = $data.title
                $inputsource = "{$(csole -s 'pipped' -c gray)}"
            }else{
                $issue_title = (Request-Issue -ProjectID $ProjectID -IssueIID $IssueIID).title
                $IssueIID = $IssueIID
                $inputsource = csole -s '[param]' -c gray
            }

            if($null -eq $issue_title){
                throw "Issue with IID: $IssueIID not found in project $ProjectID"
                return
            }

            $log_request_path = csole -s "$($global:_glvigor.auth.apipath)/projects/$ProjectID/issues/$IssueIID"

            [console]::write("$($global:_glvigor.logsub) removing issue iid: $(csole -s "$IssueIID" -c magenta)`n")
            [console]::write("$($global:_glvigor.logsubrun)$($global:_glvigor.logcmds.api_delete)::$inputsource::$log_request_path`n")

            $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", "bearer $_gitlab_apikey")
            $headers.Add("Content-Type", "application/json")

            [console]::write("$($global:_glvigor.logsub) deleting issue {$(csole -s "$IssueIID`:$issue_title" -c red)} this is a permanent action`n")
            [console]::write("$($global:_glvigor.logsub) please type the issue title '$(csole -s "$($issue_title)" -c red)' to confirm the deletion:")

            $confirm = Read-Host
            if($confirm -notmatch $issue_title){
                [console]::write("$($global:_glvigor.logsub) $(csole -s "deletion cancelled $confirm does not match $issue_title" -c red)`n")
                return
            }
            else {
                $request_issue = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$ProjectID/issues/$IssueIID" `
                    -Headers $headers `
                    -Method 'DELETE'

                [console]::write("$($global:_glvigor.logsublast) 🔥 deleted issue $(csole -s "$IssueIID|$issue_title" -c yellow)`n")

                return $request_issue
            }
        }
        catch [system.exception]{
            [console]::write("$($global:_glvigor.logsublast) $(csole -s $_.Exception.Message -c red)`n")
        }
    }
}
$cmdlet_config = @{
    function = @('Unregister-Issue')
    alias    = @('glvui')
}

Export-ModuleMember @cmdlet_config