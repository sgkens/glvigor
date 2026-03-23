using module ..\..\..\securestring\undo-securestring.psm1
using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\private\Confirm-GitLabAuth.psm1

<#
.SYNOPSIS
Unregister-Project removes a project from GitLab.

.DESCRIPTION    
Unregister-Project removes a project from GitLab.

.PARAMETER ProjectID
The ID of the project to remove.

.PARAMETER Data
Data to be passed in via the pipeline.

.PARAMETER NoConfirmation
If specified, NoConfirmation:$true will be passed to the function. bypassing repository deletion confirmation name prompt

.EXAMPLE
Unregister-Project -ProjectID 1

.EXAMPLE
Search-gitlab -type project -title myrepo -match | Unregister-Project

.EXAMPLE
Request-Project -ProjectID 1 | Unregister-Project

.EXAMPLE
Request-Project -ProjectID 1 | Unregister-Project -NoConfirmation:$true

.NOTES
Requires authentication via `Request-GitLabAuth`.
#>

function Unregister-Project {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [pscustomobject]$data,
        [Parameter(Mandatory=$false)]
        [int]$ProjectID
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
            [string]$pipedCmdlet = "($(csole -s "unregister-project" -c $global:__glvigor.colorpallet.blue))"
            [Console]::SetCursorPosition(0, $currentLine - 1) # move up one line if from pipeline removes space from log
            [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-project-unregister-request' -c $global:__glvigor.colorpallet.yellow) $pipedCmdlet...`n")
        }
        else {
            $initlogType = 'log';
            [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-project-unregister-request' -c $global:__glvigor.colorpallet.yellow)...`n")
        }
        # call auth check
        confirm-GitLabAuth
        #=== AUTH AND PIPELINE DATA ===

        try {
            if(!$data.id -and !$ProjectID){
                throw "No data from pipe or -projectid param specified"
                return
            }elseif($data.id){
                $ProjectID = $data.id
                $project_name = $data.name
                $inputsource = "{$(csole -s 'pipped' -c $global:__glvigor.colorpallet.gray)}"
            }else{
                $project_name = (Request-Project -ProjectID $ProjectID).name
                $ProjectID = $ProjectID
                $inputsource = csole -s '[param]' -c $global:__glvigor.colorpallet.gray
            }
            
            if($null -eq $project_name){
                throw "Project with ID: $ProjectID not found"
                return
            }

            $log_request_path = csole -s "$($global:_glvigor.auth.apipath)/projects/$ProjectID"
            
            [console]::write("$($global:_glvigor.logsub) removing project id: $(csole -s "$ProjectID" -c $global:__glvigor.colorpallet.magenta)`n")
            [console]::write("$($global:_glvigor.logsubrun)$($global:_glvigor.logcmds.api_delete)::$inputsource::$log_request_path`n")
        
            $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", "bearer $_gitlab_apikey")
            $headers.Add("Content-Type", "application/json")
            
            [console]::write("$($global:_glvigor.logsub) deleting project {$(csole -s "$ProjectID`:$project_name" -c $global:__glvigor.colorpallet.red)} this is a permanent action`n")
            [console]::write("$($global:_glvigor.logsub) please type the project name '$(csole -s "$($Project_name)" -c $global:__glvigor.colorpallet.red)' to confirm the deletion:")
            
            $confirm = Read-Host
            if($confirm -notmatch $project_name){
                [console]::write("$($global:_glvigor.logsub) $(csole -s "deletion cancelled $confirm does not match $project_name" -c $global:__glvigor.colorpallet.red)`n")
                return
            }
            else {
                $request_project = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$ProjectID" `
                    -Headers $headers `
                    -Method 'DELETE'
                
                [console]::write("$($global:_glvigor.logsublast) 🔥 deleted project $(csole -s "$ProjectID|$project_name" -c $global:__glvigor.colorpallet.yellow)`n")
            
                return $request_project
            }
        }
        catch [system.exception]{
            [console]::write("$($global:_glvigor.logsublast) $(csole -s $_.Exception.Message -c $global:__glvigor.colorpallet.red)`n")
        }    
    }
}
$cmdlet_config = @{
    function = @('Unregister-Project')
    alias    = @('glvurp')
}

Export-Modulemember @cmdlet_config