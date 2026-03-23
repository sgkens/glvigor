
<#
.SYNOPSIS
Sends a request to the GitLab API to create and issue for a project.

.DESCRIPTION 
Sends a request to the GitLab API to create and issue for a project.

.PARAMETER ProjectID [int]
The ID of the project for which to create the issue.

.PARAMETER ParentIssueID [int]
The ID of the project for which to set the parent issue.

.PARAMETER Description [string]
The description of the issue.

.PARAMETER Title [string]
The title of the issue.

.PARAMETER Type [string]
The type of the issue.

.PARAMETER MilestoneID [int]
The ID of the milestone you would like to assign the issue to.

.PARAMETER AssigneeIDs [int[]]
The Ids of the users you would like to assign the issue to, not for gitlab.com or not CE or EE you require a premium account to use this.
see https://docs.gitlab.com/ee/user/project/issue_assignees.html

.PARAMETER AssigneeID [int]
The Id of the user you would like to assign the issue to.

.PARAMETER labels [string[]]
The labels you would like to assign to the issue.

.PARAMETER Confidential [switch]
Makes the issue confidential.

.PARAMETER DiscussioniD [int]
The discussionID you would like to set for the issue, 

.PARAMETER Raw
if set, returns the raw object instead of the parsed object.

.EXAMPLE
Register-Issue -ProjectID 67 -Title 'my title' -Description 'my description' -Type 'issue' -AssigneeID 56

.EXAMPLE
Register-Issue -ProjectID 67 -Title 'My Issue title'


.NOTES
Requires authentication via `Request-GitLabAuth`.
#>

using module ..\..\..\securestring\undo-securestring.psm1
using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\private\Confirm-GitlabAuth.psm1

function Register-Issue {

    [CmdletBinding()]
    [Alias('glvri')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$Data,
        [Parameter(Mandatory = $false)]
        [int]$ProjectID,
        [Parameter(Mandatory = $false)]
        [string]$Description,
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [Parameter(Mandatory = $false)]
        [validateset('issue', 'incident', 'task', IgnoreCase = $true)]
        [string]$Type,
        [Parameter(Mandatory = $false)]
        [int]$MilestoneID,
        [Parameter(Mandatory = $false)]
        [int[]]$AssigneeIDs,
        [Parameter(Mandatory = $false)]
        [string]$AssigneeID,
        [Parameter(Mandatory = $false)]
        [string[]]$labels,
        [Parameter(Mandatory = $false)]
        [switch]$Confidential = $false,
        [Parameter(Mandatory = $false)]
        [int]$DiscussionID,
        [Parameter(Mandatory = $false)]
        [switch]$Raw
    )

    process {

        #=== AUTH AND PIPELINE DATA ===
        # change logtype and newline depending on if data is coming from pipeline
        # helps with readability
        [string]$initlogType = ''
        [string]$pipedCmdlet = ''
        if($data){ 
            $initlogType='logsub'
            $pipedCmdlet = "($(csole -s "Register-Issue" -c $global:__glvigor.colorpallet.blue))"
        }else{ 
            $initlogType = 'log';
            $pipedCmdlet = ''
        }
        # final logtype message
        [console]::write("$($global:_glvigor.log)$($global:_glvigor.logcmds.run) $(csole -s 'api-issue-creation-request' -c $global:__glvigor.colorpallet.yellow) $pipedCmdlet...`n")
        
        # call auth check
        confirm-GitLabAuth
        #=== AUTH AND PIPELINE DATA ===
        
        if ($Data -and !$projectid) { $projectid = $data.id}

        if(!$ProjectID -and !$Data){
            [console]::write("$($global:_glvigor.logSub) $(csole -s 'glv response: missing project id' -c $global:__glvigor.colorpallet.red)`n")
            [console]::write("$($global:_glvigor.logsub) $(csole -s 'specify by -projectid or -data @{} or from search-gitlab pipeline' -c $global:__glvigor.colorpallet.yellow)")
            break;
        }

        [pscustomobject]$_payload = @{}

        # Set default type to issue ommit -type if creating a issue not a incident or task
        if(!$type){
            $Type = 'issue'
            $_payload.psobject.properties.add([psnoteproperty]::new('issue_type', 'issue'))
        } #! unsure if the api supports issue type on creation from the api
        else{
            $_payload.psobject.properties.add([psnoteproperty]::new('issue_type', $Type))
        }
        [console]::write("$($global:_glvigor.logSub) Issue new request to project $(csole -s $ProjectID -c $global:__glvigor.colorpallet.magenta) type $(csole -s $Type -c $global:__glvigor.colorpallet.magenta)`n")
        
        # api payload required fields
        [console]::write("$($global:_glvigor.logSub) Initializing post data payload`n")
        # New issue require param specified in the url https://docs.gitlab.com/ee/api/issues.html

        # Add required
        $_payload.psobject.properties.add([psnoteproperty]::new('title', $Title))

        if($Description){
            [console]::write("$($global:_glvigor.logSub) Adding «$(csole -s prop -c $global:__glvigor.colorpallet.white -bg $global:__glvigor.colorpallet.blue)»─•description: $(csole -s $Description.tostring() -c $global:__glvigor.colorpallet.gray)`n")
            $_payload.psobject.properties.add([psnoteproperty]::new('description', $Description))
        }
        if($MilestoneID){
            [console]::write("$($global:_glvigor.logSub) Adding «$(csole -s prop -c $global:__glvigor.colorpallet.white -bg $global:__glvigor.colorpallet.blue)»─•milestone: $(csole -s $MilestoneID.tostring() -c $global:__glvigor.colorpallet.gray)`n")
            $_payload.psobject.properties.add([psnoteproperty]::new('milestone_id', $MilestoneID))
        }
        if($AssigneeID){
            [console]::write("$($global:_glvigor.logSub) Adding «$(csole -s prop -c $global:__glvigor.colorpallet.white -bg $global:__glvigor.colorpallet.blue)»─•assignee by id: $(csole -s "$($AssigneeID -join ', ')" -c $global:__glvigor.colorpallet.gray)`n")
            $_payload.psobject.properties.add([psnoteproperty]::new('assignee_id', $AssigneeID))
        }
        if ($AssigneeIDs) {
            [console]::write("$($global:_glvigor.logSub) Adding «$(csole -s prop -c $global:__glvigor.colorpallet.white -bg $global:__glvigor.colorpallet.blue)»─•assignee's by id: $(csole -s "$($AssigneeIDs -join ', ')" -c $global:__glvigor.colorpallet.gray)`n")
            $_payload.psobject.properties.add([psnoteproperty]::new('assignee_ids', $AssigneeIDs))
        }
        if($labels){
            [console]::write("$($global:_glvigor.logSub) Adding «$(csole -s prop -c $global:__glvigor.colorpallet.white -bg $global:__glvigor.colorpallet.blue)»─•labels: $(csole -s "$($labels -join ', ')" -c $global:__glvigor.colorpallet.gray)`n")
            $_payload.psobject.properties.add([psnoteproperty]::new('labels', $labels))
        }
        # if($Type){
        #     [console]::write("$($global:_glvigor.logSub) adding «$(csole -s prop -c white -bg blue)»─•type: $(csole -s $Type -c gray)`n")
        #     $_payload += "&type=$([System.Web.HttpUtility]::UrlEncode($Type))"
        # }
        if($Confidential){
            [console]::write("$($global:_glvigor.logSub) Adding «$(csole -s prop -c $global:__glvigor.colorpallet.white -bg $global:__glvigor.colorpallet.blue)»─•confidential: $(csole -s $Confidential -c $global:__glvigor.colorpallet.gray)`n")
            $_payload.psobject.properties.add([psnoteproperty]::new('confidential', [bool]$Confidential))
        }
        if($DiscussionID){
            [console]::write("$($global:_glvigor.logSub) Adding «$(csole -s prop -c $global:__glvigor.colorpallet.white -bg $global:__glvigor.colorpallet.blue)»─•discussion_to_resolve: $(csole -s $DiscussioniD -c $global:__glvigor.colorpallet.gray)`n")
            $_payload.psobject.properties.add([psnoteproperty]::new('discussion_to_resolve', $DiscussionID))
        }

        #-----------
        try {
            [console]::write("$($global:_glvigor.logSub) Sending new payload to project $(csole -s $ProjectID -c $global:__glvigor.colorpallet.magenta) issues`n")
            # undo securestring
            $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", "Bearer $_gitlab_apikey")
            $headers.Add("Content-Type", "application/json")
            [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_post)::$($global:_glvigor.auth.apipath)/projects/$(csole -s $ProjectID -c $global:__glvigor.colorpallet.magenta)/issues`n")
            $_payload | ConvertTo-Json # output of payload
            $issue_reqister = Invoke-RestMethod -Method 'POST' `
                                                -Uri "$($global:_glvigor.auth.apipath)/projects/$($projectid)/issues" `
                                                -Headers $headers `
                                                -body "$($_payload | ConvertTo-Json)"
            [console]::write("$($global:_glvigor.logsub) Successfully created new issue $(csole -s $($issue_reqister.id) -c $global:__glvigor.colorpallet.magenta) for project $(csole -s $ProjectID -c $global:__glvigor.colorpallet.magenta)`n")
            [console]::write("$($global:_glvigor.logSubLast) $(csole -s "Parsing response object..." -c $global:__glvigor.colorpallet.green)`n")
        }
        catch [system.exception] {
            [console]::write("$($global:_glvigor.logsublast) $(csole -s $_.Exception.Message -c $global:__glvigor.colorpallet.red)`n")
        }
        if (!$Raw) { return $issue_reqister | select-object created_at, id, project_id, title, state, labels, description, issue_type, confidential, assignee, author, assignees, web_url }
        else { return $issue_reqister }
        
    }
}

$cmdletconfig = @{
    function = @("Register-Issue")
    alias    = @("glvri")
}

Export-ModuleMember @cmdletconfig