using module ..\..\colorconsole\libs\cmdlets\New-ColorConsole.psm1
using module ..\..\SecureString\New-SecureString.psm1

<# 
.SYNOPSIS
Request-GetLabAuth Sends a request to the specified GitLab API endpoint to retrieves specified user data, if authenticated set $global:_glvigor.auth object.

.DESCRIPTION
Request-GetLabAuth Sends a request to the specified GitLab API endpoint to retrieves specified user data, if authenticated set $global:_glvigor.auth object.

.PARAMETER Hostname
The hostname of the GitLab instance without protocol, $ENV:GITLAB_HOST is used by default.

.PARAMETER APIKey
The apikey of the GitLab instance, $ENV:GITLAB_API_KEY is used by default.

.EXAMPLE
Request-GitLabAuth

.EXAMPLE
Request-GitLabAuth -Hostname 'https://gitlab.com' -APIKey 'key'

.LINK
#>
function Request-GitLabAuth {
    [cmdletbinding()]
    [alias('rgla')]
    [OutputType('void')]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Hostname,
        [Parameter(Mandatory = $false, Position = 1)]
        [string]$APIKey
    )

    process {
        [console]::write("$($global:_glvigor.log)$($global:_glvigor.logcmds.run) gitlab authentication...`n")

        # Allows for the use of $ENV:GITLAB_HOST
        if(!$Hostname){$Hostname = $ENV:GITLAB_HOST}
        else{$Hostname = $Hostname}
        # Allows for the use of $ENV:GITLAB_API_KEY
        if (!$APIKey) { $APIKey = $ENV:GITLAB_API_KEY; $APIKey_plain = $ENV:GITLAB_API_KEY}
        else{$APIKey = $APIKey; $APIKey_plain = $APIKey}

        try{
            # secure API key using SecureString
            [console]::write("$($global:_glvigor.logsub) securing 🔐-[$(csole -s apikey -c 5)] as secure string`n")
            [SecureString] $secureString = [SecureString]::new()
            $apiKey.ToCharArray() | ForEach-Object { $secureString.AppendChar($_) }
            $secureString.MakeReadOnly()
        } catch [Exception] {
            [console]::write("$($global:_glvigor.logsub)$(csole -s ■ -c 1)-error $(csole -s $_.Exception.Message -c 1)`n")
        }
        # Set Headers
        $headers = New-Object 'System.Collections.Generic.Dictionary[[String],[String]]'
        $headers.Add('Authorization', "Bearer $APIKey_plain")
        $headers.Add('Content-Type', 'application/json')
        $headers.Add('token', $APIKey_plain) # Incase some use this

        $api_path = "https://$Hostname/api/v4"
        
        $userdata = [hashtable]::new()
        $userdata.add('hostname', $Hostname)
        $userdata.add('apikey', $secureString) # secure string use undo-securestring
        $userdata.add('apipath', $api_path)
        
        try{
            [console]::write("$($global:_glvigor.logsub) checking http connection status`n")
            [console]::write("$($global:_glvigor.logsubrun)$($global:_glvigor.logcmds.api_get) $(csole -s "https://$hostname" -c 6)`n")
            $http_status = (Invoke-WebRequest -Uri "https://$hostname").StatusCode

            [console]::write("$($global:_glvigor.logsub) http connection status: $(csole -s $http_status -c 2)`n")
            # Add http_status to userdata
            $userdata.add('httpstatus', $http_status)

            # Get user data simplest way to check if authorized
            [console]::write("$($global:_glvigor.logsub) Fetching user data`n")
            [console]::write("$($global:_glvigor.logsubrun)$($global:_glvigor.logcmds.api_get) $(csole -s $api_path/user -c 6)`n")
            
            # make request
            $RequestUserData = Invoke-RestMethod "$api_path/user" -Method 'GET' -Headers $headers
            [console]::write("$($global:_glvigor.logsub) authentication successful using $(csole -s '[apikey]' -Color 5) as 👤 $(csole -s "($($RequestUserData.id))-$($RequestUserData.username)" -c 3)`n")
            
            # if authorized userdata will be returned
            # extract user data: id, username
            $userdata.add('id', $RequestUserData.id) 
            $userdata.add('user', $RequestUserData.username)
            
            # handdle if user doesnt exist
            if ($null -ne $RequestUserData.Message) {
                throw "connection failure - response: $($RequestUserData.Message)"
            }
            # if authorized return hashtable with connection status and config to use
            elseif($RequestUserData.id.Length -gt 0) {
                [console]::write("$($global:_glvigor.logsub) generating $(csole -s '[global]' -Color 5) auth object`n")
            }
            $global:_glvigor.auth = $userdata
            [console]::write("$($global:_glvigor.logsublast) 🔓 Login successful as $(csole -s "($(csole -s $RequestUserData.id -c 5))-$($RequestUserData.username)" -c 2)`n")
        } catch [Exception] {
            [console]::write("$($global:_glvigor.logsublast)$(csole -s ■ -c 1)-Error > $($_.Exception.Message)`n")
        }
    }
}

$cmdletconfig = @{
    function = @('Request-GitLabAuth')
    alias = @('glvauth')
}

Export-ModuleMember @cmdletconfig