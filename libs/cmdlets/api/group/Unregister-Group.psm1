using module ..\..\..\securestring\undo-securestring.psm1
using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\private\Confirm-GitLabAuth.psm1

<#
.SYNOPSIS
Unregister-Group removes a group from GitLab.

.DESCRIPTION
Unregister-Group removes a group from GitLab.

.PARAMETER GroupID
The ID of the group to remove.

.PARAMETER Data
Data to be passed in via the pipeline.

.PARAMETER NoConfirmation
If specified, NoConfirmation:$true will be passed to the function. bypassing repository deletion confirmation name prompt

.EXAMPLE
Unregister-Group -GroupID 1

.EXAMPLE
Search-gitlab -type group -title mygroup -match | Unregister-Group

.EXAMPLE
Request-Group -GroupID 1 | Unregister-Group

.EXAMPLE
Request-Group -GroupID 1 | Unregister-Group -NoConfirmation:$true

.NOTES
Requires authentication via `Request-GitLabAuth`.
#>

function Unregister-Group {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [pscustomobject]$data,
        [Parameter(Mandatory=$false)]
        [int]$GroupID
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
            [string]$pipedCmdlet = "($(csole -s "unregister-group" -c $global:__glvigor.colorpallet.blue))"
            [Console]::SetCursorPosition(0, $currentLine - 1) # move up one line if from pipeline removes space from log
            [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-group-unregister-request' -c $global:__glvigor.colorpallet.yellow) $pipedCmdlet...`n")
        }
        else {
            $initlogType = 'log';
            [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-group-unregister-request' -c $global:__glvigor.colorpallet.yellow)...`n")
        }
        # call auth check
        confirm-GitLabAuth
        #=== AUTH AND PIPELINE DATA ===

        try {
            if(!$data.id -and !$GroupID){
                throw "No data from pipe or -groupid param specified"
                return
            }elseif($data.id){
                $GroupID = $data.id
                $group_name = $data.name
                $inputsource = "{$(csole -s 'pipped' -c $global:__glvigor.colorpallet.gray)}"
            }else{
                $group_name = (Request-Group -GroupID $GroupID).name
                $GroupID = $GroupID
                $inputsource = csole -s '[param]' -c $global:__glvigor.colorpallet.gray
            }

            if($null -eq $group_name){
                throw "Group with ID: $GroupID not found"
                return
            }

            $log_request_path = csole -s "$($global:_glvigor.auth.apipath)/groups/$GroupID"

            [console]::write("$($global:_glvigor.logsub) removing group id: $(csole -s "$GroupID" -c $global:__glvigor.colorpallet.magenta)`n")
            [console]::write("$($global:_glvigor.logsubrun)$($global:_glvigor.logcmds.api_delete)::$inputsource::$log_request_path`n")

            $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", "bearer $_gitlab_apikey")
            $headers.Add("Content-Type", "application/json")

            [console]::write("$($global:_glvigor.logsub) deleting group {$(csole -s "$GroupID`:$group_name" -c $global:__glvigor.colorpallet.red)} this is a permanent action`n")
            [console]::write("$($global:_glvigor.logsub) please type the group name '$(csole -s "$($group_name)" -c $global:__glvigor.colorpallet.red)' to confirm the deletion:")

            $confirm = Read-Host
            if($confirm -notmatch $group_name){
                [console]::write("$($global:_glvigor.logsub) $(csole -s "deletion cancelled $confirm does not match $group_name" -c $global:__glvigor.colorpallet.red)`n")
                return
            }
            else {
                $request_group = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/groups/$GroupID" `
                    -Headers $headers `
                    -Method 'DELETE'

                [console]::write("$($global:_glvigor.logsublast) 🔥 deleted group $(csole -s "$GroupID|$group_name" -c $global:__glvigor.colorpallet.yellow)`n")

                return $request_group
            }
        }
        catch [system.exception]{
            [console]::write("$($global:_glvigor.logsublast) $(csole -s $_.Exception.Message -c $global:__glvigor.colorpallet.red)`n")
        }
    }
}
$cmdlet_config = @{
    function = @('Unregister-Group')
    alias    = @('glvurg')
}

Export-Modulemember @cmdlet_config