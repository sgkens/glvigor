<#
.SYNOPSIS
Unregister-MirrorConfig removes a mirror from a project.

.DESCRIPTION
Unregister-MirrorConfig removes a mirror from a project.

.PARAMETER Data
Data to be passed in via the pipeline. If not specified, -ProjectID and -MirrorID are required.

.PARAMETER ProjectID
The ID of the project to remove the mirror from.

.PARAMETER MirrorID
The ID of the mirror to remove.

.EXAMPLE
Unregister-MirrorConfig -ProjectID 1 -MirrorID 2

.NOTES
Requires Authentication through Request-GitLabAuth
    
.LINK
#>

using module ..\..\..\securestring\undo-securestring.psm1
using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\private\confirm-GitLabAuth.psm1

function Unregister-MirrorConfig {

    [CmdletBinding()]
    [OutputType('void')]
    [Alias('glvurm')]

    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [pscustomobject]$Data,
        [Parameter(Mandatory = $false)]
        [int]$ProjectID,
        [Parameter(Mandatory = $false)]
        [int]$MirrorID
    )

    process {

        try {

            #=== AUTH AND PIPELINE DATA ===
            # change logtype and newline depending on if data is coming from pipeline
            # helps with readability
            $currentLine = [Console]::CursorTop
            [string]$initlogType = ''
            [string]$pipedCmdlet = ''
            if ($data) { 
                $initlogType = 'logsubrun'
                [string]$pipedCmdlet = "($(csole -s "Unregister-MirrorConfig" -c $global:__glvigor.colorpallet.blue))"
                [Console]::SetCursorPosition(0, $currentLine - 1) # move up one line if from pipeline removes space from log
                [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'mirror-config-unregistration' -c $global:__glvigor.colorpallet.yellow) $pipedCmdlet...`n")
            }
            else {
                $initlogType = 'log';
                [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'mirror-config-unregistration' -c $global:__glvigor.colorpallet.yellow)...`n")
            }
            # call auth check
            confirm-GitLabAuth
            #=== AUTH AND PIPELINE DATA ===


            if(!$data -and !$ProjectID){
                throw "No data from pipe or -projectid param specified"
            }elseif($data){
                $ProjectID = $data.project_id
                $MirrorID = $data.id
            }else{
                $ProjectID = $ProjectID
                $MirrorID = $MirrorID
            }

            [console]::write("$($global:_glvigor.logsub) running mirror configuration unregistration`n")
            $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", "Bearer $_gitlab_apikey")
            $headers.Add("Content-Type", "application/json")
            [console]::write("$($global:_glvigor.logsub)$($global:_glvigor.logcmds.api_delete)::$($global:_glvigor.auth.apipath)/projects/$ProjectID/remote_mirrors/$MirrorID`n")
            Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$ProjectID/remote_mirrors/$MirrorID" `
                              -Headers $headers `
                              -Method 'DELETE'
            [console]::write("$($global:_glvigor.logsub)$(csole -s " ✅ Mirror configuration unregistered" -c $global:__glvigor.colorpallet.green)`n")
        }catch [System.Exception] {
            [console]::write("$($global:_glvigor.logsub)$(csole -s ■ -c $global:__glvigor.colorpallet.red)-Error $(csole -s $_.Exception.Message -c $global:__glvigor.colorpallet.red)`n")
        }
    }
}

$cmdletconfig = @{
    function = @("Unregister-MirrorConfig")
    alias    = @("glvurm")
}

Export-Modulemember @cmdletconfig