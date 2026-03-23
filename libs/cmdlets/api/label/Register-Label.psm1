using module ..\..\..\securestring\undo-securestring.psm1
using module ..\..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\private\Confirm-GitLabAuth.psm1
<#
.SYNOPSIS
@SYNOPSIS
Creates a new label via the Gitlab API.

.DESCRIPTION
This script is used to request the creation of a new Gitlub label via the Gitlab REST API.

.PARAMETER ProjectID
The ID of the project to create the label in.

.PARAMETER name
The name of the label to create.

.PARAMETER color
The color of the label to create.

.PARAMETER description
Optional description of the label.

.EXAMPLE
# Create a new label
Register-Label -ProjectID 1 -name "my-label" -color "#ff0000" -description "My new label"

.NOTES
Requires a Gitlab personal access token with appropriate label creation permissions.
#>

function Register-Label {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('glvrl')]
    param (
        [Parameter(Mandatory = $true)]
        [int]$ProjectID,
        [Parameter(Mandatory = $true)]
        [string]$name,
        [Parameter(Mandatory = $true)]
        [string]$color,
        [Parameter(Mandatory = $false)]
        [string]$description,
        [Parameter(Mandatory = $false)]
        [switch]$Raw
    )

    process {
        try {


            [console]::write("$($global:_glvigor.log) $($global:_glvigor.logcmds.run) $(csole -s 'api-label-creation-post-request' -c $global:__glvigor.colorpallet.yellow)...`n")

            #=== AUTH AND PIPELINE DATA ===
            # call auth check
            confirm-GitLabAuth
            #=== AUTH AND PIPELINE DATA ===

            [console]::write("$($global:_glvigor.logsub) create label '$(csole -s "$name" -c $global:__glvigor.colorpallet.magenta)'`n")

            [hashtable]$requestBody = @{
                name           = $name
                color          = $color
            }

            if ($description) { $requestBody.description = $description }

            $_gitlab_apikey = $global:_glvigor.auth.apikey | undo-securestring
            $http_header = @{
                'Content-Type'         = 'application/json'
                'Authorization'        = "Bearer $_gitlab_apikey"
            }

            [console]::write("$($global:_glvigor.logsub) $($global:_glvigor.logcmds.api_post) $($global:_glvigor.auth.apipath)/projects/$ProjectID/labels`n")
            $response = Invoke-RestMethod -Uri "$($global:_glvigor.auth.apipath)/projects/$ProjectID/labels" -Method Post -Headers $http_header -Body ($requestBody | ConvertTo-Json)

            [console]::write("$($global:_glvigor.logsub) label $(csole -s "$name" -c $global:__glvigor.colorpallet.magenta) created`n")
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
            [console]::write("`n$($global:_glvigor.logsub) $(csole -s '■─error:' -c $global:__glvigor.colorpallet.red) $($_.Exception.Message)`n")
            return $response
        }
    }

}

$cmdlet_config = @{
    function = @('Register-Label')
    alias    = @('glvrl')
}

Export-ModuleMember @cmdlet_config