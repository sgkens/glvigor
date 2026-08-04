



<#
.SYNOPSIS
Unregister-MergeRequest removes a merge request from GitLab.

.DESCRIPTION
Unregister-MergeRequest removes a merge request from GitLab.

.PARAMETER ProjectID
The ID of the project to remove the merge request from.

.PARAMETER MergeRequestIID
The IID of the merge request to remove.

.PARAMETER Data
Data to be passed in via the pipeline.

.PARAMETER NoConfirmation
If specified, NoConfirmation:$true will be passed to the function. bypassing repository deletion confirmation name prompt

.EXAMPLE
Unregister-MergeRequest -ProjectID 1 -MergeRequestIID 1

.NOTES
Requires authentication via `Request-GitLabAuth`.
#>

function Unregister-MergeRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [pscustomobject]$data,
        [Parameter(Mandatory=$false)]
        [int]$ProjectID,
        [Parameter(Mandatory=$false)]
        [int]$MergeRequestIID
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
            [string]$pipedCmdlet = "($(csole -s "unregister-mergerequest" -c $global:__glvigor.colorpallet.blue))"
            [Console]::SetCursorPosition(0, $currentLine - 1) # move up one line if from pipeline removes space from log
            [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-mergerequest-unregister-request' -c $global:__glvigor.colorpallet.yellow) $pipedCmdlet...`n")
        }
        else {
            $initlogType = 'log';
            [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-mergerequest-unregister-request' -c $global:__glvigor.colorpallet.yellow)...`n")
        }
        # call auth check
        Confirm-GitLabAuth
        #=== AUTH AND PIPELINE DATA ===

        try {
            if(!$data.id -and !$MergeRequestIID){
                throw "No data from pipe or -mergerequestiid param specified"
                return
            }elseif($data.id){
                $MergeRequestIID = $data.iid
                $mergerequest_title = $data.title
                $inputsource = "{$(csole -s 'pipped' -c $global:__glvigor.colorpallet.gray)}"
            }else{
                $mergerequest_title = (Request-MergeRequest -ProjectID $ProjectID -MergeRequestIID $MergeRequestIID).title
                $MergeRequestIID = $MergeRequestIID
                $inputsource = csole -s '[param]' -c $global:__glvigor.colorpallet.gray
            }

            if($null -eq $mergerequest_title){
                throw "Merge Request with IID: $MergeRequestIID not found in project $ProjectID"
                return
            }

            $log_request_path = csole -s "$($global:_glvigor.auth.apipath)/projects/$ProjectID/merge_requests/$MergeRequestIID"

            [console]::write("$($global:_glvigor.logsub) removing merge request iid: $(csole -s "$MergeRequestIID" -c $global:__glvigor.colorpallet.magenta)`n")
            [console]::write("$($global:_glvigor.logsubrun)$($global:_glvigor.logcmds.api_delete)::$inputsource::$log_request_path`n")

            $_gitlab_apikey = $global:_glvigor.auth.apikey | Undo-SecureString
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", "bearer $_gitlab_apikey")
            $headers.Add("Content-Type", "application/json")

            [console]::write("$($global:_glvigor.logsub) deleting merge request {$(csole -s "$MergeRequestIID`:$mergerequest_title" -c $global:__glvigor.colorpallet.red)} this is a permanent action`n")
            [console]::write("$($global:_glvigor.logsub) please type the merge request title '$(csole -s "$($mergerequest_title)" -c $global:__glvigor.colorpallet.red)' to confirm the deletion:")

            $confirm = Read-Host
            if($confirm -notmatch $mergerequest_title){
                [console]::write("$($global:_glvigor.logsub) $(csole -s "deletion cancelled $confirm does not match $mergerequest_title" -c $global:__glvigor.colorpallet.red)`n")
                return
            }
            else {
                $request_mergerequest = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$ProjectID/merge_requests/$MergeRequestIID" `
                    -Headers $headers `
                    -Method 'DELETE'

                [console]::write("$($global:_glvigor.logsublast) 🔥 deleted merge request $(csole -s "$MergeRequestIID|$mergerequest_title" -c $global:__glvigor.colorpallet.yellow)`n")

                return $request_mergerequest
            }
        }
        catch [system.exception]{
            [console]::write("$($global:_glvigor.logsublast) $(csole -s $_.Exception.Message -c $global:__glvigor.colorpallet.red)`n")
        }
    }
}
$cmdlet_config = @{
    function = @('Unregister-MergeRequest')
    alias    = @('glvumr')
}

Export-Modulemember @cmdlet_config
