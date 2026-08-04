


 
<#
.SYNOPSIS
Sends a request to the GitLab API to retrieve a group.

.DESCRIPTION
Sends a request to the GitLab API to retrieve a group.

.PARAMETER GroupID
The ID of the group for which to retrieve.

.EXAMPLE
Request-Group -GroupID 1
Sends a request to retrieve the configuration for the group with ID 1.

.NOTES
Requires authentication via `Request-GitLabAuth`.
#>

function Request-Group {

    [CmdletBinding()]
    [Alias('glvrg')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
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
            [string]$pipedCmdlet = "($(csole -s "request-group" -c $global:__glvigor.colorpallet.blue))"
            [Console]::SetCursorPosition(0, $currentLine -1) # move up one line if from pipeline removes space from log
            [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-group-get-request' -c $global:__glvigor.colorpallet.yellow) $pipedCmdlet...`n")
        }
        else {
            $initlogType = 'log';
            [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-group-get-request' -c $global:__glvigor.colorpallet.yellow)...`n")
        }
        # call auth check
        Confirm-GitLabAuth
        #=== AUTH AND PIPELINE DATA ===

        try{

            [console]::write("$($global:_glvigor.logsub) fetching group id: $(csole -s $groupid -c $global:__glvigor.colorpallet.magenta)`n")
            [console]::write("$($global:_glvigor.logsub) Generating request...`n")
            [console]::write("$($global:_glvigor.logsub) $($global:_glvigor.logcmds.api_get)::$($global:_glvigor.auth.apipath)/groups/$(csole -s "$GroupID" -c $global:__glvigor.colorpallet.magenta)`n")
            
            $_gitlab_apikey = $global:_glvigor.auth.apikey | Undo-SecureString
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", "Bearer $_gitlab_apikey")
            $headers.Add("Content-Type", "application/json")          
            $request_group = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/groups/$GroupID"
            [console]::write("$($global:_glvigor.logsub) $(csole -s "group fetched" -c $global:__glvigor.colorpallet.green)`n")
        
        }catch [system.exception]{
           
            [console]::write("$($global:_glvigor.logsub) $(csole -s $_.Exception.Message -c $global:__glvigor.colorpallet.red)`n")

        }

        return $request_group
    }
}

