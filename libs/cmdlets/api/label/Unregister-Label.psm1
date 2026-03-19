using module ..\..\..\securestring\undo-securestring.psm1
using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\private\Confirm-GitLabAuth.psm1

<#
.SYNOPSIS
Unregister-Label removes a label from GitLab.

.DESCRIPTION
Unregister-Label removes a label from GitLab.

.PARAMETER ProjectID
The ID of the project to remove the label from.

.PARAMETER LabelID
The ID of the label to remove.

.PARAMETER Data
Data to be passed in via the pipeline.

.PARAMETER NoConfirmation
If specified, NoConfirmation:$true will be passed to the function. bypassing repository deletion confirmation name prompt

.EXAMPLE
Unregister-Label -ProjectID 1 -LabelID 1

.NOTES
Requires authentication via `Request-GitLabAuth`.
#>

function Unregister-Label {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [pscustomobject]$data,
        [Parameter(Mandatory=$false)]
        [int]$ProjectID,
        [Parameter(Mandatory=$false)]
        [int]$LabelID
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
            [string]$pipedCmdlet = "($(csole -s "unregister-label" -c blue))"
            [Console]::SetCursorPosition(0, $currentLine - 1) # move up one line if from pipeline removes space from log
            [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-label-unregister-request' -c yellow) $pipedCmdlet...`n")
        }
        else {
            $initlogType = 'log';
            [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-label-unregister-request' -c yellow)...`n")
        }
        # call auth check
        confirm-GitLabAuth
        #=== AUTH AND PIPELINE DATA ===

        try {
            if(!$data.id -and !$LabelID){
                throw "No data from pipe or -labelid param specified"
                return
            }elseif($data.id){
                $LabelID = $data.id
                $label_name = $data.name
                $inputsource = "{$(csole -s 'pipped' -c gray)}"
            }else{
                $label_name = (Request-Label -ProjectID $ProjectID -LabelID $LabelID).name
                $LabelID = $LabelID
                $inputsource = csole -s '[param]' -c gray
            }

            if($null -eq $label_name){
                throw "Label with ID: $LabelID not found in project $ProjectID"
                return
            }

            $log_request_path = csole -s "$($global:_glvigor.auth.apipath)/projects/$ProjectID/labels/$LabelID"

            [console]::write("$($global:_glvigor.logsub) removing label id: $(csole -s "$LabelID" -c magenta)`n")
            [console]::write("$($global:_glvigor.logsubrun)$($global:_glvigor.logcmds.api_delete)::$inputsource::$log_request_path`n")

            $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", "bearer $_gitlab_apikey")
            $headers.Add("Content-Type", "application/json")

            [console]::write("$($global:_glvigor.logsub) deleting label {$(csole -s "$LabelID`:$label_name" -c red)} this is a permanent action`n")
            [console]::write("$($global:_glvigor.logsub) please type the label name '$(csole -s "$($label_name)" -c red)' to confirm the deletion:")

            $confirm = Read-Host
            if($confirm -notmatch $label_name){
                [console]::write("$($global:_glvigor.logsub) $(csole -s "deletion cancelled $confirm does not match $label_name" -c red)`n")
                return
            }
            else {
                $request_label = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$ProjectID/labels/$LabelID" `
                    -Headers $headers `
                    -Method 'DELETE'

                [console]::write("$($global:_glvigor.logsublast) 🔥 deleted label $(csole -s "$LabelID|$label_name" -c yellow)`n")

                return $request_label
            }
        }
        catch [system.exception]{
            [console]::write("$($global:_glvigor.logsublast) $(csole -s $_.Exception.Message -c red)`n")
        }
    }
}
$cmdlet_config = @{
    function = @('Unregister-Label')
    alias    = @('glvurl')
}

Export-Modulemember @cmdlet_config