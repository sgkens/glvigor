<# ? Correct format test working
.SYNOPSIS
Sends a request to the GitLab API to retrieve mirror configuration for a project. You can filter the results by passing in the -MirrorID parameter.

.DESCRIPTION
The `Request-MirrorConfig` function sends a request to the GitLab API to retrieve the mirror configuration for a specified project. Optionally, you can filter the results by providing the -MirrorID parameter.

.PARAMETER Data
Data to be passed in via the pipeline. If not specified, -ProjectID and -MirrorID are required.

.PARAMETER ProjectID
The ID of the project for which to retrieve the mirror configuration.

.PARAMETER MirrorID
The ID of the specific mirror to retrieve.

.PARAMETER Raw
If specified, returns the raw data from the API call as an unfiltered PSCustomObject.

.EXAMPLE
Request-MirrorConfig -ProjectID 1 -MirrorID 2
Sends a request to retrieve the configuration for the mirror with ID 2 in the project with ID 1.

.EXAMPLE
Request-MirrorConfig -ProjectID 1 -MirrorID 2 -Raw
Sends a request to retrieve the raw configuration data for the mirror with ID 2 in the project with ID 1.

.EXAMPLE
Search-Gitlab -type projects -title 'test' -raw | Request-MirrorConfig
Pipes the result of a project search into `Request-MirrorConfig` to retrieve the mirror configuration.

.EXAMPLE
[pscustomobject]@{id=1} | Request-MirrorConfig
Pipes a PSCustomObject representing a project ID into `Request-MirrorConfig` to retrieve the mirror configuration.

.NOTES
Requires authentication via `Request-GitLabAuth`.
#>






function Request-MirrorConfig {

    [CmdletBinding()]
    [Alias('glvrqm')]
    [OutputType([PSCustomObject])]

    param(
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [pscustomobject]$data,
        [Parameter(Mandatory = $false)]
        [int]$ProjectID,
        [Parameter(Mandatory = $false)]
        [int]$MirrorID,
        [Parameter(Mandatory = $false)]
        [switch]$raw
    )

    process {

        try{

            #=== AUTH AND PIPELINE DATA ===
            # change logtype and newline depending on if data is coming from pipeline
            # helps with readability
            $currentLine = [Console]::CursorTop
            [string]$initlogType = ''
            [string]$pipedCmdlet = ''
            if($data){ 
                $initlogType='logsubrun'
                [string]$pipedCmdlet = "($(csole -s "Request-MirrorConfig" -c $global:__glvigor.colorpallet.blue))"
                [Console]::SetCursorPosition(0, $currentLine - 1) # move up one line if from pipeline removes space from log
                [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-mirror-config-request' -c $global:__glvigor.colorpallet.yellow) $pipedCmdlet...`n")
            }else{
                $initlogType = 'log';
                [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-mirror-config-request' -c $global:__glvigor.colorpallet.yellow)...`n")
            }
            # call auth check
            Confirm-GitLabAuth
            #=== AUTH AND PIPELINE DATA ===

            # [console]::write("$($global:_glvigor.log) fetching mirror id: $(csole -s $mirrorid -c $global:__glvigor.colorpallet.magenta) for project: $(csole -s $projectid -c $global:__glvigor.colorpallet.magenta)`n")
            $_gitlab_apikey = $global:_glvigor.auth.apikey | Undo-SecureString
            #! Note Headers can use a simple hash table or a PSObject as value 
            # !     it does need a System.Collections.Generic.Dictionary[[String],[String]]
            # ?     Unsure what the down sides are to this, will continue to use Generics
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", "Bearer $_gitlab_apikey")
            $headers.Add("Content-Type", "application/json")

            # if param ProjectID and MirrorID are specified and not comming from pipe 
            # return single mirror for that project of id specified
            if($ProjectID -and $MirrorID -and !$data) {
                $inputsource = csole -s '[param]' -c $global:__glvigor.colorpallet.gray -bg $global:__glvigor.colorpallet.darkcyan
                $log_request_path = "$(csole -s $global:_glvigor.auth.apipath -c $global:__glvigor.colorpallet.cyan)/projects/$projectid/remote_mirrors/$mirrorid"
                [console]::write("$($global:_glvigor.logsub) Fetching mirror(🆔): $(csole -s "$MirrorID" -c $global:__glvigor.colorpallet.magenta) for project(🆔): $(csole -s "$ProjectID" -c $global:__glvigor.colorpallet.magenta)`n")
                [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_get)::$inputsource::$log_request_path `n")
                $request_mirror = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$projectid/remote_mirrors/$mirrorid" `
                                                    -Headers $headers `
                                                    -Method 'GET'
                # append pscustomobject psnoteproperty to $request_mirror to allow piped unregister-mirrorconfig
                $request_mirror.psobject.properties.add([psnoteproperty]::new('project_id', $projectid))
            }
            # if param -ProjectID but no other specified and not comming from pipe - return all mirrors for that project
            elseif(!$mirrorid -and $projectid -and !$data) {
                $inputsource = csole -s '[param]' -c $global:__glvigor.colorpallet.gray -bg $global:__glvigor.colorpallet.darkcyan
                $log_request_path = "$(csole -s $global:_glvigor.auth.apipath -c $global:__glvigor.colorpallet.cyan)/projects/$projectid/remote_mirrors"
                [console]::write("$($global:_glvigor.logsub) Fetching mirrors for project 🆔: $(csole -s "$projectid" -c $global:__glvigor.colorpallet.magenta)`n")
                [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_get)::$inputsource::$log_request_path `n")
                $request_mirror = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$projectid/remote_mirrors" `
                                                    -Headers $headers `
                                                    -Method 'GET'
                # append pscustomobject psnoteproperty to $request_mirror to allow piped unregister-mirrorconfig
                $request_mirror.psobject.properties.add([psnoteproperty]::new('project_id', $projectid))
            }
            # if param -ProjectID and -MirrorID is not specified and data is not comming from pipe or specified
            # return all mirrors for that project base of piped.data.project_id
            # ? can be pipped from Request-Project
            elseif(!$projectid -and $mirrorid -and $data) {
                $inputsource = csole -s '[pipped]' -c $global:__glvigor.colorpallet.gray -bg $global:__glvigor.colorpallet.darkyellow
                $log_request_path = "$(csole -s $global:_glvigor.auth.apipath -c $global:__glvigor.colorpallet.cyan)/projects/$($data.id)/remote_mirrors/$mirrorid"
                [console]::write("$($global:_glvigor.logsub) Extracting project id from $inputsource-object`n")
                [console]::write("$($global:_glvigor.logsub) Fetching mirrors for project:($($data.Name))-$(csole -s "🆔:$($data.id)" -c $global:__glvigor.colorpallet.magenta)`n")
                [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_get)::$inputsource::$log_request_path `n")
                $request_mirror = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$($data.id)/remote_mirrors/$MirrorID" `
                                                    -Headers $headers `
                                                    -Method 'GET'
                [console]::write("$($global:_glvigor.logsub) Extracting mirror-id $(csole -s $mirrorid -c $global:__glvigor.colorpallet.magenta) for project: $(csole -s id:"$($data.id)" -c $global:__glvigor.colorpallet.magenta)`n")
                # append pscustomobject psnoteproperty to $request_mirror to allow piped unregister-mirrorconfig
                $request_mirror.psobject.properties.add([psnoteproperty]::new('project_id', $data.id))
            }
            # if no params specified and not comming from pipe - return all mirrors for all projects
            elseif(!$projectid -and !$mirrorid -and $data) {
                $inputsource = csole -s '[pipped]' -c $global:__glvigor.colorpallet.gray -bg $global:__glvigor.colorpallet.darkyellow
                $log_request_path = "$(csole -s $global:_glvigor.auth.apipath -c $global:__glvigor.colorpallet.cyan)/projects/$($data.id)/remote_mirrors"
                [console]::write("$($global:_glvigor.logsub) Extracting project-id from $inputsource-object`n")
                [console]::write("$($global:_glvigor.logsub) Fetching mirrors for project: ($($data.Name))-$(csole -s "🆔:$($data.id)" -c $global:__glvigor.colorpallet.magenta)`n")
                [console]::write("$($global:_glvigor.logsub) $($global:_glvigor.logcmds.api_get)::$inputsource::$log_request_path `n")
                $request_mirror = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$($data.id)/remote_mirrors" `
                                                    -Headers $headers `
                                                    -Method 'GET'
                # append pscustomobject psnoteproperty to $request_mirror to allow piped unregister-mirrorconfig
                $request_mirror.psobject.properties.add([psnoteproperty]::new('project_id', $data.id))
            }else{
                [console]::write("$($global:_glvigor.logsublast)$(csole -s ■ -c $global:__glvigor.colorpallet.red)-Error $(csole -s $_.Exception.Message -c $global:__glvigor.colorpallet.red)`n")
            }

            [console]::writeline("$($global:_glvigor.logsublast) $(csole -s 'Parsing response objects...' -c $global:__glvigor.colorpallet.green)")
            if ($request_mirror.count -eq 0){
                return [PSCustomObject]@{  Message = "$(csole -s "no mirrors found for project" -c $global:__glvigor.colorpallet.red)" }
            }else{
                if(!$raw){
                    #TODO: use cofoge to manipulate psobject and colorconsone or colorizer to format and color
                    return $request_mirror | select-object id,enabled,url
                }else{
                    return $request_mirror
                }
            }
        }catch [System.Exception] {
            [console]::write("$($global:_glvigor.logsublast)$(csole -s ■ -c $global:__glvigor.colorpallet.red)-Error $(csole -s $_.Exception.Message -c $global:__glvigor.colorpallet.red)`n")
        }
    }
}

$cmdletconfig = @{
    function = @("Request-MirrorConfig")
    alias    = @("glvrmc")
}

Export-Modulemember @cmdletconfig
