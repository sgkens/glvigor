using module ..\..\..\securestring\undo-securestring.psm1
using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\private\Confirm-GitLabAuth.psm1
<#
.SYNOPSIS
@SYNOPSIS
Updates a new label via the Gitlab API.

.DESCRIPTION
This script is used to request the update of a new Gitlub label via the Gitlab REST API.

.PARAMETER ProjectID
The ID of the project to update the label in.

.PARAMETER LabelID
The ID of the label to update.

.PARAMETER name
The new name of the label.

.PARAMETER color
The new color of the label.

.PARAMETER description
Optional new description of the label.

.EXAMPLE
# Update a label
Update-Label -ProjectID 1 -LabelID 1 -name "my-label" -color "#ff0000" -description "My new label"

.NOTES
Requires a Gitlab personal access token with appropriate label creation permissions.
#>

function Update-Label {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('glvul')]
    param (
        [Parameter(Mandatory = $true)]
        [int]$ProjectID,
        [Parameter(Mandatory = $true)]
        [int]$LabelID,
        [Parameter(Mandatory = $false)]
        [string]$name,
        [Parameter(Mandatory = $false)]
        [string]$color,
        [Parameter(Mandatory = $false)]
        [string]$description,
        [Parameter(Mandatory = $false)]
        [switch]$Raw
    )

    process {
        try {


            [console]::write("$($global:_glvigor.log) $($global:_glvigor.logcmds.run) $(csole -s 'api-label-update-put-request' -c yellow)...`n")

            #=== AUTH AND PIPELINE DATA ===
            # call auth check
            confirm-GitLabAuth
            #=== AUTH AND PIPELINE DATA ===

            [console]::write("$($global:_glvigor.logsub) update label '$(csole -s "$LabelID" -c magenta)'`n")

            [hashtable]$requestBody = @{}

            if ($name) { $requestBody.new_name = $name }
            if ($color) { $requestBody.color = $color }
            if ($description) { $requestBody.description = $description }


            $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
            $http_header = @{
                'Content-Type'         = 'application/json'
                'Authorization'        = "Bearer $_gitlab_apikey"
            }

            [console]::write("$($global:_glvigor.logsub) $($global:_glvigor.logcmds.api_put) $($global:_glvigor.auth.apipath)/projects/$ProjectID/labels/$LabelID`n")
            $response = Invoke-RestMethod -Uri "$($global:_glvigor.auth.apipath)/projects/$ProjectID/labels/$LabelID" -Method Put -Headers $http_header -Body ($requestBody | ConvertTo-Json)

            [console]::write("$($global:_glvigor.logsub) label $(csole -s "$name" -c magenta) updated`n")
            [console]::write("$($global:_glvigor.logsublast)`n")

            if($raw){
                return $response
            }else{
                $filtered_response = [PSCustomObject]@{
                    name = $response.name
                    id = $response.id
                    description = $response.description
                    color = $response.color
                }
                return $filtered_response
            }

        }
        catch {
            [console]::write("`n$($global:_glvigor.logsub) $(csole -s '■─error:' -c red) $($_.Exception.Message)`n")
            return $response
        }
    }

}

$cmdlet_config = @{
    function = @('Update-Label')
    alias    = @('glvul')
}

Export-ModuleMember @cmdlet_config