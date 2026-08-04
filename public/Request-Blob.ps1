



<#
.SYNOPSIS
Sends a request to the GitLab API to retrieve a blob.

.DESCRIPTION
Sends a request to the GitLab API to retrieve a blob.

.PARAMETER ProjectID
The ID of the project for which to retrieve.

.PARAMETER BlobSHA
The SHA of the blob for which to retrieve.

.EXAMPLE
Request-Blob -ProjectID 1 -BlobSHA "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391"
Sends a request to retrieve the blob with sha "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391" in project 1.

.NOTES
Requires authentication via `Request-GitLabAuth`.
#>

function Request-Blob {

    [CmdletBinding()]
    [Alias('glvrb')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [int]$ProjectID,
        [Parameter(Mandatory = $true)]
        [string]$BlobSHA
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
            [string]$pipedCmdlet = "($(csole -s "request-blob" -c $global:__glvigor.colorpallet.blue))"
            [Console]::SetCursorPosition(0, $currentLine -1) # move up one line if from pipeline removes space from log
            [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-blob-get-request' -c $global:__glvigor.colorpallet.yellow) $pipedCmdlet...`n")
        }
        else {
            $initlogType = 'log';
            [console]::write("$($global:_glvigor.$initlogType)$($global:_glvigor.logcmds.run) $(csole -s 'api-blob-get-request' -c $global:__glvigor.colorpallet.yellow)...`n")
        }
        # call auth check
        Confirm-GitLabAuth
        #=== AUTH AND PIPELINE DATA ===

        try{

            [console]::write("$($global:_glvigor.logsub) fetching blob sha: $(csole -s $blobsha -c $global:__glvigor.colorpallet.magenta)`n")
            [console]::write("$($global:_glvigor.logsub) Generating request...`n")
            [console]::write("$($global:_glvigor.logsub) $($global:_glvigor.logcmds.api_get)::$($global:_glvigor.auth.apipath)/projects/$ProjectID/repository/blobs/$(csole -s "$BlobSHA" -c $global:__glvigor.colorpallet.magenta)`n")

            $_gitlab_apikey = $global:_glvigor.auth.apikey | Undo-SecureString
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", "Bearer $_gitlab_apikey")
            $headers.Add("Content-Type", "application/json")
            $request_blob = Invoke-RestMethod -uri "$($global:_glvigor.auth.apipath)/projects/$ProjectID/repository/blobs/$BlobSHA"
            [console]::write("$($global:_glvigor.logsub) $(csole -s "blob fetched" -c $global:__glvigor.colorpallet.green)`n")

        }catch [system.exception]{

            [console]::write("$($global:_glvigor.logsub) $(csole -s $_.Exception.Message -c $global:__glvigor.colorpallet.red)`n")

        }

        return $request_blob
    }
}

