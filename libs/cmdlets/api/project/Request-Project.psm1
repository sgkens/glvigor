using module ..\..\..\securestring\undo-securestring.psm1
using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\private\Confirm-GitLabAuth.psm1
 
<#
.SYNOPSIS
Sends a request to the GitLab API to retrieve a project.

.DESCRIPTION
Sends a request to the GitLab API to retrieve a project.

.PARAMETER ProjectID
The ID of the project for which to retrieve.

.EXAMPLE
Request-Project -ProjectID 1
Sends a request to retrieve the configuration for the mirror with ID 2 in the project with ID 1.

.NOTES
Requires authentication via `Request-GitLabAuth`.
#>

function Request-Project {

    [CmdletBinding()]
    [Alias('glvrp')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
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
            [string]$pipedCmdlet = "($(csole -s "request-project" -c $global:__glvigor.colorpallet.blue))"
            [Console]::SetCursorPosition(0, $currentLine -1) # move up one line if from pipeline removes space from log
            [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-project-get-request' -c $global:__glvigor.colorpallet.yellow) $pipedCmdlet...`n")
        }
        else {
            $initlogType = 'log';
            [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-project-get-request' -c $global:__glvigor.colorpallet.yellow)...`n")
        }
        # call auth check
        confirm-GitLabAuth
        #=== AUTH AND PIPELINE DATA ===

        try{

            [console]::write("$($global:_glvigor.logsub) fetching project id: $(csole -s $projectid -c $global:__glvigor.colorpallet.magenta)`n")
            [console]::write("$($global:_glvigor.logsub) Generating request...`n")
            [console]::write("$($global:_glvigor.logsub) $($global:_glvigor.logcmds.api_get)::$($global:_glvigor.auth.apipath)/projects/$(csole -s "$ProjectID" -c $global:__glvigor.colorpallet.magenta)`n")
            
            $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", "Bearer $_gitlab_apikey")
            $headers.Add("Content-Type", "application/json")          
            $request_project = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$ProjectID"
            [console]::write("$($global:_glvigor.logsub) $(csole -s "project fetched" -c $global:__glvigor.colorpallet.green)`n")
        
        }catch [system.exception]{
           
            [console]::write("$($global:_glvigor.logsub) $(csole -s $_.Exception.Message -c $global:__glvigor.colorpallet.red)`n")

        }

        return $request_project
    }
}
