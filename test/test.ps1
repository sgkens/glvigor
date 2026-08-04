Import-Module ..\

Send-GitLabMirrorConfig -Hostname 'gitlab.com' `
    -ProjectID 183 `
    -Gituser 'powershell' `
    -APIKey $ENV:GITLAB_API_KEY `
    -MirrorHost 'gitea.com' `
    -MirrorUser 'sgkens' `
    -MirrorAPIKey $ENV:GITEA_API_KEY

Request-GitLabMirrorConfig -Hostname 'gitlab.com' `
    -Name 'nupsforge' `
    -ProjectID 183 `
    -Gituser 'powershell' `
    -APIKey $ENV:GITLAB_API_KEY
