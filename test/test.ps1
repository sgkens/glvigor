import-module ..\


Send-GitLabMirrorConfig -Hostname 'gitlab.kenscloud.online' `
                        -ProjectID 183 `
                        -Gituser 'powershell' `
                        -APIKey $ENV:GITLAB_API_KEY `
                        -MirrorHost 'gitea.kenscloud.online' `
                        -MirrorUser 'sgkens' `
                        -MirrorAPIKey $ENV:GITEA_API_KEY

Request-GitLabMirrorConfig -Hostname 'gitlab.kenscloud.online' `
                           -Name 'nupsforge' `
                           -ProjectID 183 `
                           -Gituser 'powershell' `
                           -APIKey $ENV:GITLAB_API_KEY