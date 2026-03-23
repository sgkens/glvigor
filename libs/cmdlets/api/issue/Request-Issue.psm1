<#
.SYNOPSIS
Sends a request to the GitLab API to retrieve issues for a project, this can be futher filtered by passing in -IssueID.

.DESCRIPTION
Sends a request to the GitLab API to retrieve issues for a project, this can be futher filtered by passing in -IssueID.

.PARAMETER ProjectID
The ID of the project for which to retrieve issues.

.PARAMETER IssueID
The ID of the project for which to retrieve issues.

.EXAMPLE
Request-Issue -ProjectID 1 -issueid 2

.Sends a request to retrieve the issues for the  with ID 2 in the project with ID 1.

.EXAMPLE
Request-Issue -ProjectID 1

.Sends a request to retrieve all issues in the project with ID 1.

.EXAMPLE
Search-gitlab -type project -title myrepo | Request-Issue

.Sends a request to retrieve all issues in the project with ID 1.

.EXAMPLE
Search-gitlab -type project -title myrepo | Request-Issue -issueid 2 -raw

.Sends a request to retrieve all issues in the project with ID 1, but only the issue with ID 2 and returns the raw data

.NOTES
Requires authentication via `Request-GitLabAuth`.
#>

using module ..\..\..\securestring\undo-securestring.psm1
using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\private\Confirm-GitlabAuth.psm1

function Request-Issue {

    [CmdletBinding()]
    [Alias('glvrqi')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$Data,
        [Parameter(Mandatory = $false)]
        [int]$IssueID,
        [Parameter(Mandatory = $false)]
        [int]$ProjectID,
        [Parameter(Mandatory = $false)]
        [validateset('opened', 'closed', 'active', 'all', IgnoreCase = $true)]
        [string]$State,
        [Parameter(Mandatory = $false)]
        [string[]]$labels,
        [Parameter(Mandatory = $false)]
        [string]$Milestone,
        [Parameter(Mandatory = $false)]
        [switch]$Raw
    )

    process {

        # manage opensate covers all logic
        [string]$issue_state
        switch ($State){
            'opened' { $issue_state = '&state=opened' }
            'closed' { $issue_state = '&state=closed' }
            'Active' { $issue_state = '&state=active' }
            'all' { $issue_state = '' }
        }
        # encode labels if not null
        if($labels){
            $labels = $labels -join ','
            $labels = "&labels=$labels".replace(" ","+")
        }else {$labels = ''}

        # encode milestone if not null
        if($Milestone){
            $Milestone = [System.Web.HttpUtility]::UrlEncode($Milestone)
        }
        
        #-----------
        try {
            #=== AUTH AND PIPELINE DATA ===
            # change logtype and newline depending on if data is coming from pipeline
            # helps with readability
            $currentLine = [Console]::CursorTop
            [string]$initlogType = ''
            [string]$pipedCmdlet = ''
            if ($data) {
                $projectid = $data.id
                $initlogType = 'logsubrun'
                [string]$pipedCmdlet = "($(csole -s "request-issue" -c $global:__glvigor.colorpallet.blue))"
                [Console]::SetCursorPosition(0, $currentLine - 1) # move up one line if from pipeline removes space from log                
                [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-issue-get-request' -c $global:__glvigor.colorpallet.yellow) $pipedCmdlet...`n")
            }
            else {
                $projectid = $ProjectID
                $initlogType = 'log';
                [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-issue-get-request' -c $global:__glvigor.colorpallet.yellow)...`n")
            }
            # call auth check
            confirm-GitLabAuth
            #=== AUTH AND PIPELINE DATA ===

            $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
            #! Note Headers can use a simple hash table or a PSObject as value 
            # !     it does need a System.Collections.Generic.Dictionary[[String],[String]]
            # ?     Unsure what the down sides are to this, will continue to use Generics
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", "Bearer $_gitlab_apikey")
            $headers.Add("Content-Type", "application/json")
            
            # coming from pipeline
            if($data){
                $inputsource =  "{$(csole -s 'pipe' -c $global:__glvigor.colorpallet.gray)}"
                # if comming from search-gitlab with type milestones set projectid to project_id
                if($data.project_id){
                    $projectid = $data.project_id
                   
                }
                # object.iid either milestone or issueid
                # return issues from milestone
                if ($data.iid -and $data.type -eq 'MILESTONE') {
                    $log_request_path = csole -s "$($global:_glvigor.auth.apipath)/projects/$($data.id)/issues?milestone=$Milestone$issue_state$labels"
                    [console]::write("$($global:_glvigor.logsub) fetching issues for milestone: $(csole -s "$($data.iid)" -c $global:__glvigor.colorpallet.magenta) for project: $(csole -s $data.id -c $global:__glvigor.colorpallet.magenta)`n")
                    [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_get)::$inputsource::$log_request_path`n")
                    $request_issue = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$projectid/issues?milestone=$($data.iid)$issue_state$labels" `
                        -Headers $headers `
                        -Method 'GET'
                }
                # return single Issue for that project of id specified from piped-object
                # ? can be pipped from Request-Project
                if ($data.id -and $data.type -eq 'ISSUE') {
                    $log_request_path = csole -s "$($global:_glvigor.auth.apipath)/projects/$($data.id)/issues/$issueid"
                    [console]::write("$($global:_glvigor.logsub) fetching issue id: $(csole -s "$IssueID" -c $global:__glvigor.colorpallet.magenta) for project: $(csole -s $data.id -c $global:__glvigor.colorpallet.magenta)`n")
                    [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_get)::$inputsource::$log_request_path`n")
                    $request_issue = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$projectid/issues/$issueid?$issue_state$labels" `
                        -Headers $headers `
                        -Method 'GET'
                }
                # retrieve all Issues for that project from piped-data, returns all Issues for that project
                if (!$issueid -and !$Milestone) {
                    $log_request_path = csole -s "$($global:_glvigor.auth.apipath)/projects/$($data.id)/issues$issue_state$labels"
                    [console]::write("$($global:_glvigor.logsub) fetching issues for project: $(csole -s "$projectid" -c $global:__glvigor.colorpallet.magenta)`n")
                    [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_get)::$inputsource::$log_request_path`n")
                    $request_issue = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$projectid/issues?$issue_state$labels" `
                        -Headers $headers `
                        -Method 'GET'
                }
            }
            # coming from param
            elseif($projectid){
                $inputsource =  "[$(csole -s 'param' -c $global:__glvigor.colorpallet.gray)]"
                # returns single Issue for that project from -param ProjectID and -param IssueID
                if ($IssueID) {
                    $log_request_path = $(csole -s "$($global:_glvigor.auth.apipath)/projects/$projectid/issues/$issueid")
                    [console]::write("$($global:_glvigor.logsub) fetching issue id: $(csole -s "$IssueID" -c $global:__glvigor.colorpallet.magenta) for project: $(csole -s "$ProjectID" -c $global:__glvigor.colorpallet.magenta)`n")
                    [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_get)::$inputsource::$log_request_path`n")
                    $request_issue = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$projectid/issues/$issueid" `
                        -Headers $headers `
                        -Method 'GET'
                }
                # returns all Issues for that project from -param ProjectID
                if (!$issueid -and !$Milestone) {
                    $log_request_path = $(csole -s "$($global:_glvigor.auth.apipath)/projects/$projectid/issues?$issue_state$labels")
                    [console]::write("$($global:_glvigor.logsub) fetching issues for project: $(csole -s "$projectid" -c $global:__glvigor.colorpallet.magenta)`n")
                    [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_get)::$inputsource::$log_request_path`n")
                    $request_issue = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$projectid/issues?$issue_state$labels" `
                        -Headers $headers `
                        -Method 'GET'
                }
                # return all Issues for that project and Milestone specified
                if (!$issueid -and $Milestone) {
                    $log_request_path = csole -s "$($global:_glvigor.auth.apipath)/projects/$($projectid)/issues?milestone=$Milestone$issue_state$labels"
                    [console]::write("$($global:_glvigor.logsub) extracting project id from piped-object`n")
                    [console]::write("$($global:_glvigor.logsub) fetching issue id: $(csole -s "$IssueID" -c $global:__glvigor.colorpallet.magenta) for project: $(csole -s "$projectid" -c $global:__glvigor.colorpallet.magenta)`n")
                    [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_get)::$inputsource::$log_request_path `n")
                    $request_issue = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$($projectid)/issues?milestone=$Milestone$issue_state$labels" `
                        -Headers $headers `
                        -Method 'GET'
                }

            }
            else{
                throw "$($global:_glvigor.log) error: $(csole -s 'invalid parameters - requires -ProjectId parameter or pipped with pscustomobject.id' -c $global:__glvigor.colorpallet.red)`n"
            }

            # returns single Issue for that project from -param ProjectID and -param IssueID
            # if ($ProjectID -and $IssueID -and !$data -and !$Milestone) {
            #     $inputsource = csole -s '[param]' -c $global:__glvigor.colorpallet.gray -bg $global:__glvigor.colorpallet.darkcyan
            #     $log_request_path = $(csole -s "$($global:_glvigor.auth.apipath)/projects/$projectid/issues/$issueid")
            [console]::write("$($global:_glvigor.logsub) fetching issue id: $(csole -s "$IssueID" -c $global:__glvigor.colorpallet.magenta) for project: $(csole -s $data.id -c $global:__glvigor.colorpallet.magenta)`n")
            #     [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_get)::$inputsource::$log_request_path`n")
            #     $request_issue = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$projectid/issues/$issueid" `
            #         -Headers $headers `
            #         -Method 'GET'
            # }
            # returns all Issues for that project from -param ProjectID
            # elseif (!$issueid -and $projectid -and !$data -and !$Milestone) {
            #     $inputsource = csole -s '[param]' -c $global:__glvigor.colorpallet.gray -bg $global:__glvigor.colorpallet.darkcyan
            #     $log_request_path = $(csole -s "$($global:_glvigor.auth.apipath)/projects/$projectid/issues?$issue_state$labels")
            [console]::write("$($global:_glvigor.logsub) fetching issues for project: $(csole -s "$projectid" -c $global:__glvigor.colorpallet.magenta)`n")
            #     [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_get)::$inputsource::$log_request_path`n")
            #     $request_issue = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$projectid/issues?$issue_state$labels" `
            #         -Headers $headers `
            #         -Method 'GET'
            # }
            # # return single Issue for that project of id specified from piped-object
            # # ? can be pipped from Request-Project
            # elseif (!$projectid -and $issueid -and $data -and !$Milestone) {
            #     $inputsource = csole -s '[pipe]' -c $global:__glvigor.colorpallet.gray -bg $global:__glvigor.colorpallet.darkyellow
            #     $log_request_path = csole -s "$($global:_glvigor.auth.apipath)/projects/$($data.id)/issues/$issueid"
            #     [console]::write("$($global:_glvigor.logsub) extracting project id from piped-object`n")
            [console]::write("$($global:_glvigor.logsub) fetching issue id: $(csole -s "$IssueID" -c $global:__glvigor.colorpallet.magenta) for project: $(csole -s $data.id -c $global:__glvigor.colorpallet.magenta)`n")
            #     [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_get)::$inputsource::$log_request_path`n")
            #     $request_issue = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$($data.id)/issues/$issueid" `
            #         -Headers $headers `
            #         -Method 'GET'
            # }
            # return all Issues for that project and Milestone specified from piped-data
            # elseif (!$projectid -and !$issueid -and $data -and $Milestone) {
            #     $inputsource = csole -s '[pipe]' -c $global:__glvigor.colorpallet.gray -bg $global:__glvigor.colorpallet.darkyellow
            #     $log_request_path = csole -s "$($global:_glvigor.auth.apipath)/projects/$($data.id)/issues?milestone=$Milestone$issue_state$labels"
            #     [console]::write("$($global:_glvigor.logsub) extracting project id from piped-object`n")
            [console]::write("$($global:_glvigor.logsub) fetching issues for milestone: $(csole -s "$($data.iid)" -c $global:__glvigor.colorpallet.magenta) for project: $(csole -s $data.id -c $global:__glvigor.colorpallet.magenta)`n")
            #     [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_get)::$inputsource::$log_request_path`n")
            #     $request_issue = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$($data.id)/issues?milestone=$Milestone$issue_state$labels" `
            #         -Headers $headers `
            #         -Method 'GET'
            # }
            # retrieve all Issues for that project and Milestone specified
            # elseif ($projectid -and !$issueid -and !$data -and $Milestone) {
            #     $inputsource = csole -s '[param]' -c $global:__glvigor.colorpallet.gray -bg $global:__glvigor.colorpallet.darkyellow
            #     $log_request_path = csole -s "$($global:_glvigor.auth.apipath)/projects/$($projectid)/issues?milestone=$Milestone$issue_state$labels"
            #     [console]::write("$($global:_glvigor.logsub) extracting project id from piped-object`n")
            [console]::write("$($global:_glvigor.logsub) fetching issue id: $(csole -s "$IssueID" -c $global:__glvigor.colorpallet.magenta) for project: $(csole -s $data.id -c $global:__glvigor.colorpallet.magenta)`n")
            #     [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_get)::$inputsource::$log_request_path `n")
            #     $request_issue = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$($projectid)/issues?milestone=$Milestone$issue_state$labels" `
            #         -Headers $headers `
            #         -Method 'GET'
            # }
            # retrieve all Issues for that project from piped-data, returns all Issues for that project
            # elseif (!$projectid -and !$issueid -and $data -and !$Milestone) {
            #     $inputsource = csole -s '[pipe]' -c $global:__glvigor.colorpallet.gray -bg $global:__glvigor.colorpallet.darkyellow
            #     $log_request_path = csole -s "$($global:_glvigor.auth.apipath)/projects/$($data.id)/issues$issue_state$labels"
            #     [console]::write("$($global:_glvigor.logsub) extracting project id from piped-object`n")
            [console]::write("$($global:_glvigor.logsub) fetching issues for project: $(csole -s "$projectid" -c $global:__glvigor.colorpallet.magenta)`n")
            #     [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_get)::$inputsource::$log_request_path`n")
            #     $request_issue = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$($data.id)/issues?$issue_state$labels" `
            #         -Headers $headers `
            #         -Method 'GET'
            # }
            # else {
            #     [console]::write("`n$($global:_glvigor.log) error: $(csole -s 'invalid parameters' -c $global:__glvigor.colorpallet.red)`n")
            # }

            [console]::write("$($global:_glvigor.logsub) $(csole -s 'parsing object...' -c $global:__glvigor.colorpallet.green)`n")
            if ($request_issue.count -eq 0) {
                return [PSCustomObject]@{Message = "$(csole -s "no issues found for project" -c $global:__glvigor.colorpallet.red)"}
            }
            else {
                if (!$raw) {
                    #TODO: use cofoge to manipulate psobject and colorconsone or colorizer to format and color
                    return $request_issue | select-object iid, title, state, labels, web_url
                }
                else {
                    return $request_issue
                }
            }
        }
        catch [System.Exception] {
            [console]::write("$($global:_glvigor.logSub)$(csole -s ■ -c $global:__glvigor.colorpallet.red)-error $(csole -s $_.Exception.Message -c $global:__glvigor.colorpallet.red)`n")
        }
    }
}


$cmdletconfig = @{
    function = @("Request-Issue")
    alias    = @("glvrqi")
}

Export-Modulemember @cmdletconfig