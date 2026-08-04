


<#
.SYNOPSIS
Search-Gitlab sends a request to the GitLab API to retrieve a project.

.DESCRIPTION
Search-Gitlab sends a request to the GitLab API to retrieve a project.

.PARAMETER Title
The title of the project to retrieve.

.PARAMETER Type
The type of the project to retrieve.

.PARAMETER Raw
If specified, returns the raw data from the API call as an unfiltered PSCustomObject.

.PARAMETER Related
The related type to retrieve.

.PARAMETER Match
If specified, returns the raw data from the API call as an unfiltered PSCustomObject.

.EXAMPLE
Search-Gitlab -type projects -title 'test' -raw
#>

function Search-Gitlab {

    [cmdletbinding()]
    [OutputType('pscustomobject')]
    [Alias('glvs')]
    
    param(
        [Parameter(Mandatory = $false)]
        [string]$Title,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [validateSet('projects', 'issues', 'merge_requests', 'milestones', 'snippet_titles', 'users', 'blobs', 'commits', 'notes', 'groups', IgnoreCase = $true)]
        [string]$Type = 'projects',
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Namespace,
        [Parameter(Mandatory = $false)]
        [switch]$Raw = $false,
        [Parameter(Mandatory = $false)]
        [string]$Related,
        [Parameter(Mandatory = $false)]
        [switch]$Match = $false
    )

    process{

        #=== AUTH AND PIPELINE DATA ===
        # change logtype and newline depending on if data is coming from pipeline
        # helps with readability

        [console]::write("$($global:_glvigor.log)$($global:_glvigor.logcmds.run) => $(csole -s $type -c $global:__glvigor.colorpallet.cyan) $(csole -s 'search-request' -c $global:__glvigor.colorpallet.yellow)...`n")
        
        # call auth check
        Confirm-GitLabAuth
        #=== AUTH AND PIPELINE DATA ===

        #if(!$title){$title = ' '}

        #! internal func to paginate search from api query
        #! limit is 100 pages at a time
        function Search-GitlabPages {
            
            param($Title, $Type)

            [pscustomobject[]]$pages = @()
            [int]$per_page = 100
            [int]$page = 1
            [string]$api_path = $global:_glvigor.auth.apipath
            [string]$logSubRun = "$($global:_glvigor.logSubRun)"
            [string]$api_sub = "$($global:_glvigor.logcmds.api_sub)"
            [string]$pg = "$($global:_glvigor.pg)"

            # Headers
            $apikey = $global:_glvigor.auth.apikey | Undo-SecureString
            $headers = New-Object "System.Collections.Generic.Dictionary[[string],[string]]"
            $headers.Add("Authorization", "Bearer $apikey")
            $headers.Add("Content-Type", "application/json")

            switch ($Type) {
                'projects'       { $api_path  += "/search?&scope=projects&search=$Title" }
                'issues'         { $api_path  += "/search?&scope=issues&search=$Title" }
                'merge_requests' { $api_path  += "/search?&scope=merge_requests&search=$Title" }
                'milestones'     { $api_path  += "/search?&scope=milestones&search=$Title" }
                'snippet_titles' { $api_path  += "/search?&scope=snippets&search=$Title" }
                'users'          { $api_path  += "/search?&scope=users&search=$Title" }
                'blobs'          { $api_path  += "/search?&scope=blobs&search=$Title" }
                'commits'        { $api_path  += "/search?&scope=commits&search=$Title" }
                'notes'          { $api_path  += "/search?&scope=notes&search=$Title" }
                'groups'         { $api_path  += "/groups?search&search=$Title" }
            }

            do {
                [console]::write("$api_sub $(csole -s paganation -c $global:__glvigor.colorpallet.cyan) $pg $api_path&page=$page&per_page=$per_page`n")
                $response = Invoke-RestMethod "$api_path&page=$page&per_page=$per_page" -Method 'GET' -Headers $headers
                $pages += $response
                $page++

            } while ($response.count -eq $per_page)
            
            return $pages
        }

        [string]$SearchAll = ""
        if ($null -eq $Title -or $Title -eq "" -or $Title.Length -eq 0) { $SearchAll = "ALL" }
        else{ $SearchAll = $Title }

        try {

            [console]::write("$($global:_glvigor.logsub) search $(csole -s 'type' -c $global:__glvigor.colorpallet.green) •-[$(csole -s "$type" -c $global:__glvigor.colorpallet.cyan)] $(csole -s 'title' -c $global:__glvigor.colorpallet.green) •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)]`n")
            [console]::write("$($global:_glvigor.logSubRun)$($global:_glvigor.logcmds.api_get) $(csole -s $global:_glvigor.auth.apipath -c $global:__glvigor.colorpallet.cyan)/search?&scope=$(csole -s $Type -c $global:__glvigor.colorpallet.magenta)&search=$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)`n")
            
            $response = Search-GitlabPages -Title $title -Type $type
            
            if($response.count -eq 0){
                # [console]::write("$($global:_glvigor.logsub) found ( $(csole -s $response.count -c $global:__glvigor.colorpallet.yellow) ) resources of Type •-[$(csole -s $type -c $global:__glvigor.colorpallet.magenta)] Title •-[$(csole -s "($SearchAll)" -c $global:__glvigor.colorpallet.cyan)]`n")
                throw [System.Exception]::New("$(csole -s "0 results found matching type •-[$(csole -s $type -c $global:__glvigor.colorpallet.magenta)] title •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.magenta)" -c $global:__glvigor.colorpallet.yellow)]`n")
            }
            
            [console]::write("$($global:_glvigor.logsub) parsing response objects...`n")
        }
        catch {
            [console]::write("$($global:_glvigor.logsub) $(csole -s $_.Exception.Message -c $global:__glvigor.colorpallet.yellow)`n")
        }

        if($null -eq $response -or $response.count -eq 0){
            return [PSCustomObject]@{
                glvigor = 'notification'
                Response = '201';  
                Message = "0 results found matcahing: $SearchAll";
            }
        }else{
            if($response.count -gt 0){
                switch ($Type){
                    # returns projects filter by name or name with namespace(group name)
                    # half the filtering is done with api other half is done here.
                    # can be piped to other cmdlets.
                    'projects' { 
                        if($match){
                            # Namespace is not required but output help text to console if not provided
                            if (!$namespace) { $namespace = "use $(csole -s '-namespace' -c $global:__glvigor.colorpallet.magenta)" }
                            else { $namespace = "$Namespace/$Title"}
                            [console]::write("$($global:_glvigor.logsub) attempting to match •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.yellow)] in •-[$(csole -s "$Type" -c $global:__glvigor.colorpallet.yellow)] with namespace •-[$(csole -s "$Namespace" -c $global:__glvigor.colorpallet.yellow)]`n")
                            $matched_filtered = $response | where-object { $_.name -eq $title -and $_.path_with_namespace -eq $Namespace }
                            if ($matched_filtered.count -gt 1){
                                [console]::write("$($global:_glvigor.logsub) 🥽 multiple matches found •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)]")
                                if(!$raw){ return $matched_filtered | select-object id, name, path_with_namespace, http_url_to_repo }
                                else{ return $matched_filtered }
                            }elseif($matched_filtered.count -eq 1){
                                [console]::write("$($global:_glvigor.logsub) 🥽 exact match found •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] with id  $(csole -s "$($matched_filtered.id)" -c $global:__glvigor.colorpallet.yellow)`n")
                                if(!$raw){ return $matched_filtered | select-object id, name, path_with_namespace, http_url_to_repo }
                                else{ return $matched_filtered }
                            }else{
                                [console]::write("$($global:_glvigor.logsub) 🥽 no matches found •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.yellow)]`n")
                                return
                            }
                        }else{
                            [console]::write("$($global:_glvigor.logsub) 🥽 filtering •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] in •-[$(csole -s $type -c $global:__glvigor.colorpallet.yellow)] object`n")
                            # if coming from pipe dont output response with a `n line
                            if(!$raw){ return $response | select-object id, name, path_with_namespace, http_url_to_repo }
                            else{ return $response }
                        }
                    }
                    # returns issues filter by name or if web_url contains title 
                    # and if no title provided returns all issues.
                    # can be piped to other cmdlets
                    'issues' { 
                        if($match){
                            [console]::write("$($global:_glvigor.logsub) 🥽 attempting to match •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] in •-[$(csole -s $Type -c $global:__glvigor.colorpallet.yellow)]`n")
                            $matched_filtered = $response | where-object { $_.title -eq $title -or $_.web_url -like "*$title*" }
                            if ($matched_filtered.count -gt 1){
                                [console]::write("$($global:_glvigor.logsub) 🥽 multiple matches found for •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)]`n")
                                if(!$raw){return $matched_filtered | select-object id, project_id, title, web_url }
                                else{ return $matched_filtered }
                            }else {
                                [console]::write("$($global:_glvigor.logsub) 🥽 Exact match found •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] with id •-[$(csole -s "$($matched_filtered.id)" -c $global:__glvigor.colorpallet.yellow)]`n")
                                if(!$raw){return $matched_filtered | select-object id, project_id, title, web_url}
                                else{ return $matched_filtered }
                            }
                        }else{
                            [console]::write("$($global:_glvigor.logsub) 🥽 filtering •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] in •-[$(csole -s $type -c $global:__glvigor.colorpallet.yellow)] object`n")    
                            if(!$raw){ return $response | select-object id, project_id, title, web_url }
                            else{ return $response }
                        }
                    }
                    'merge_requests' {
                        if($match){ 
                            [console]::write("$($global:_glvigor.logsub) 🥽 filtering •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] in •-[$(csole -s $type -c $global:__glvigor.colorpallet.yellow)] object`n")
                            $matched_filtered = $response | where-object { $_.web_url -like "*$Related*" -or $_.project_id -eq $Related } 
                            if ($matched_filtered.count -gt 1){
                                [console]::write("$($global:_glvigor.logsub) 🥽 multiple matches found for •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)]`n")
                                if(!$raw){return $matched_filtered | select-object id, project_id, title, web_url }
                                else{ return $matched_filtered }
                            }else {
                                [console]::write("$($global:_glvigor.logsub) 🥽 Exact match found •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] with id •-[$(csole -s "$($matched_filtered.id)" -c $global:__glvigor.colorpallet.yellow)]`n")
                                if(!$raw){return $matched_filtered | select-object id, project_id, title, web_url}
                                else{ return $matched_filtered }
                            }
                        }else{
                            [console]::write("$($global:_glvigor.logsub) 🥽 filtering •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] in •-[$(csole -s $type -c $global:__glvigor.colorpallet.yellow)] object`n")
                            if(!$raw){ return $response | select-object id, project_id, title, web_url }
                            else{ return $response }
                        }
                    }
                    'snippet_titles' {
                        if($matched){
                            [console]::write("$($global:_glvigor.logsub) 🥽 filtering •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] in •-[$(csole -s $type -c $global:__glvigor.colorpallet.yellow)] object`n")
                            $matched_filtered = $response | where-object { $_.web_url -like "*$Related*" -or $_.project_id -eq $Related } 
                            if ($matched_filtered.count -gt 1){
                                [console]::write("$($global:_glvigor.logsub) 🥽 multiple matches found for •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)]`n")
                                if(!$raw){return $matched_filtered | select-object id, title, web_url, raw_url, visibility}
                                else{ return $matched_filtered }
                            }else {
                                [console]::write("$($global:_glvigor.logsub) 🥽 Exact match found •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] with id •-[$(csole -s "$($matched_filtered.id)" -c $global:__glvigor.colorpallet.yellow)]`n")
                                if(!$raw){return $matched_filtered | select-object id, title, web_url, raw_url, visibility}
                                else{ return $matched_filtered }
                            }
                        }else{
                            [console]::write("$($global:_glvigor.logsub) 🥽 filtering •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] in •-[$(csole -s $type -c $global:__glvigor.colorpallet.yellow)] object`n")
                            if(!$raw){ return $response | select-object id, title, web_url, raw_url, visibility }
                            else{ return $response }
                        }
                    }
                    'milestones' { 
                        if($match){
                            [console]::write("$($global:_glvigor.logsub) 🥽 filtering •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] in •-[$(csole -s $type -c $global:__glvigor.colorpallet.yellow)] object`n")
                            $matched_filtered = $response | where-object { $_.title -eq $title -or $_.web_url -like "*$title*" }
                            if ($matched_filtered.count -gt 1){
                                [console]::write("$($global:_glvigor.logsub) 🥽 multiple matches found for •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)]`n")
                                if(!$raw){return $matched_filtered | select-object id, title, web_url }
                                else{ return $matched_filtered }
                            }else {
                                [console]::write("$($global:_glvigor.logsub) 🥽 Exact match found •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] with id •-[$(csole -s "$($matched_filtered.id)" -c $global:__glvigor.colorpallet.yellow)]`n")
                                if(!$raw){return $matched_filtered | select-object id, title, web_url}
                                else{ return $matched_filtered }
                            }
                        }else{
                            [console]::write("$($global:_glvigor.logsub) 🥽 filtering •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] in •-[$(csole -s $type -c $global:__glvigor.colorpallet.yellow)] object`n")
                            if(!$raw){ return $response | select-object id, title, web_url }
                            else{ return $response }
                        }
                    }
                    'users' { 
                        if($match){
                            [console]::write("$($global:_glvigor.logsub) 🥽 filtering •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] in •-[$(csole -s $type -c $global:__glvigor.colorpallet.yellow)] object`n")
                            $matched_filtered = $response | where-object { $_.name -eq $title -or $_.web_url -like "*$title*" }
                            if ($matched_filtered.count -gt 1){
                                [console]::write("$($global:_glvigor.logsub) 🥽 multiple matches found for •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)]`n")
                                if(!$raw){return $matched_filtered | select-object id, name, web_url}
                                else{ return $matched_filtered }
                            }else {
                                [console]::write("$($global:_glvigor.logsub) 🥽 Exact match found •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] with id •-[$(csole -s "$($matched_filtered.id)" -c $global:__glvigor.colorpallet.yellow)]`n")
                                if(!$raw){return $matched_filtered | select-object id, name, web_url}
                                else{ return $matched_filtered }
                            }
                        }else{
                            [console]::write("$($global:_glvigor.logsub) 🥽 filtering •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] in •-[$(csole -s $type -c $global:__glvigor.colorpallet.yellow)] object`n")
                            if(!$raw){ return $response | select-object id, name, web_url }
                            else{ return $response }
                        }
                    }
                    'groups' { 
                        if($match){
                            [console]::write("$($global:_glvigor.logsub) 🥽 filtering •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] in •-[$(csole -s $type -c $global:__glvigor.colorpallet.yellow)] object`n")
                            $matched_filtered = $response | where-object { $_.name -eq $title -or $_.web_url -like "*$title*" }
                            if ($matched_filtered.count -gt 1){
                                [console]::write("$($global:_glvigor.logsub) 🥽 multiple matches found for •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)]`n")
                                if(!$raw){return $matched_filtered | select-object id, name, web_url}
                                else{ return $matched_filtered }
                            }else{
                                [console]::write("$($global:_glvigor.logsub) 🥽 filtered matches found for •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)]`n")
                                if (!$raw) { return $matched_filtered | select-object id, name, web_url }
                                else { return $matched_filtered }   
                            }
                        }else{
                            [console]::write("$($global:_glvigor.logsub) 🥽 filtering •-[$(csole -s "$SearchAll" -c $global:__glvigor.colorpallet.cyan)] in •-[$(csole -s $type -c $global:__glvigor.colorpallet.yellow)] object`n")
                            if(!$raw){ return $response | select-object id, name, web_url }
                            else{ return $response }
                        }
                    }
                    default { throw [System.ArgumentOutOfRangeException]::new("type", $type, "type must be 'projects', 'issues', 'merge_requests', 'milestones', 'snippet_titles', 'blobs' ,'users' or 'groups") }
                }
            }else {
                [console]::write("$($global:_glvigor.logsublast) $(csole -s "reponse object count is 0" -c $global:__glvigor.colorpallet.yellow) no results found`n")
                return
            }
        }
    }
}

$cmdletconfig = @{
    function = @("Search-Gitlab")
    alias    = @("glvs")
}

Export-Modulemember @cmdletconfig
