# ==============================================================================
# File: test/glvigor.Tests.ps1
# ==============================================================================
BeforeAll {
    Import-Module "$PSScriptRoot/../glvigor.psm1" -Force
}

Describe "GLVigor Core Module Tests" {
    Context "Module Import & Command Registration" {
        It "Should export master router alias 'glv'" {
            (Get-Alias -Name 'glv' -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        }

        It "Should export Request-Project cmdlet" {
            (Get-Command -Name 'Request-Project' -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        }

        It "Should export Request-Issue cmdlet" {
            (Get-Command -Name 'Request-Issue' -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        }

        It "Should export targeted expansion cmdlets and aliases" {
            (Get-Command -Name 'Approve-MergeRequest' -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
            (Get-Command -Name 'Request-GitBranch' -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
            (Get-Command -Name 'Register-GitBranch' -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
            (Get-Command -Name 'Unregister-GitBranch' -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
            (Get-Command -Name 'Request-GLVJobTrace' -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
            (Get-Command -Name 'Request-GLVJobArtifact' -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
            (Get-Alias -Name 'glvapmr' -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
            (Get-Alias -Name 'glvrqbr' -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
            (Get-Alias -Name 'glvrqtrace' -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        }

        It "Should initialize logging state required by public cmdlets" {
            $global:_glvigor.logsub | Should -Not -BeNullOrEmpty
            $global:_glvigor.logcmds.git_config | Should -Not -BeNullOrEmpty
            $global:__glvigor.colorpallet.red | Should -Be 1
        }
    }

    Context "Authentication & Token Security" {
        It "Should reject authentication without API token or ENV var" {
            $env:GITLAB_API_KEY = ""
            $result = Request-GitLabAuth -Hostname "gitlab.com"
            $result | Should -BeNullOrEmpty
        }
    }

    Context "Router Pipeline Output" {
        BeforeEach {
            Mock Search-GitLab -ModuleName glvigor {
                @(
                    [pscustomobject]@{ id = 101; iid = 7; project_id = 42; title = 'First issue' },
                    [pscustomobject]@{ id = 102; iid = 8; project_id = 42; title = 'Second issue' }
                )
            }
            Mock Write-GLVTable -ModuleName glvigor
        }

        It "Should emit complete objects and skip TUI rendering with Raw" {
            $result = @(Invoke-GLVigor -Mode search -Action issue -Raw)

            $result.Count | Should -Be 2
            $result[0].iid | Should -Be 7
            $result[0].project_id | Should -Be 42
            Should -Invoke Write-GLVTable -ModuleName glvigor -Times 0
        }

        It "Should retain TUI rendering by default" {
            $result = Invoke-GLVigor -Mode search -Action issue

            $result | Should -BeNullOrEmpty
            Should -Invoke Write-GLVTable -ModuleName glvigor -Times 1
        }
    }

    Context "Owner-Space Status Dashboard" {
        BeforeEach {
            $script:statusFixture = [pscustomobject]@{
                SchemaVersion  = 1
                GeneratedAtUtc = [datetime]::UtcNow.ToString('o')
                Host           = 'gitlab.example'
                User           = [pscustomobject]@{ Id = 100; Username = 'example-user'; Name = 'Example User'; State = 'active' }
                Summary        = [pscustomobject]@{ Projects = 1; AssignedTasks = 0 }
                ApiPlan        = [pscustomobject]@{ TaskLimit = 100; TasksMayBeMore = $false; Strategy = 'bounded' }
                Namespaces     = @()
                RecentProjects = @()
                Projects       = @()
                Groups         = @()
                Tasks          = @()
            }
            Mock Read-GLVStatusCache -ModuleName glvigor { $script:statusFixture }
            Mock Write-GLVStatusCache -ModuleName glvigor
            Mock Show-GLVStatus -ModuleName glvigor
        }

        It "Should use cached metadata without making a refresh request by default" {
            Mock Get-GLVStatusSnapshot -ModuleName glvigor { $script:statusFixture }

            $result = Get-GLVStatus -Raw -CachePath '/tmp/glvigor-status-test.json'

            $result.User.Username | Should -Be 'example-user'
            $result.Cache.Refreshed | Should -BeFalse
            Should -Invoke Get-GLVStatusSnapshot -ModuleName glvigor -Times 0
            Should -Invoke Write-GLVStatusCache -ModuleName glvigor -Times 0
        }

        It "Should refresh and replace cached metadata with Update" {
            Mock Get-GLVStatusSnapshot -ModuleName glvigor { $script:statusFixture }

            $result = Get-GLVStatus -Update -Raw -CachePath '/tmp/glvigor-status-test.json'

            $result.Cache.Refreshed | Should -BeTrue
            Should -Invoke Read-GLVStatusCache -ModuleName glvigor -Times 0
            Should -Invoke Get-GLVStatusSnapshot -ModuleName glvigor -Times 1
            Should -Invoke Write-GLVStatusCache -ModuleName glvigor -Times 1
        }

        It "Should automatically refresh when no compatible cache exists" {
            Mock Read-GLVStatusCache -ModuleName glvigor { $null }
            Mock Get-GLVStatusSnapshot -ModuleName glvigor { $script:statusFixture }

            $result = Get-GLVStatus -Raw -CachePath '/tmp/glvigor-status-test.json'

            $result.Cache.Refreshed | Should -BeTrue
            Should -Invoke Get-GLVStatusSnapshot -ModuleName glvigor -Times 1
        }

        It "Should pass Update and Raw through the status route" {
            Mock Get-GLVStatus -ModuleName glvigor

            Invoke-GLVigor -Mode status -Update -Raw

            Should -Invoke Get-GLVStatus -ModuleName glvigor -Times 1 -ParameterFilter {
                $Update -and $Raw
            }
        }

        It "Should aggregate assigned tasks with one capped query and discard non-owner projects" {
            InModuleScope glvigor {
                $originalAuth = $global:_glvigor.auth
                try {
                    $global:_glvigor.auth = [pscustomobject]@{
                        hostname   = 'https://gitlab.example'
                        apipath    = 'https://gitlab.example/api/v4'
                        apikey     = ConvertTo-SecureString 'test-token' -AsPlainText -Force
                        id         = 100
                        username   = 'example-user'
                        name       = 'Example User'
                        httpstatus = 200
                    }
                    Mock Get-GLVScopedProjects {
                        @([pscustomobject]@{
                            id = 10; name = 'repo'; path_with_namespace = 'example-user/repo'
                            namespace = [pscustomobject]@{ full_path = 'example-user'; kind = 'user' }
                            visibility = 'private'; default_branch = 'main'; open_issues_count = 2
                            last_activity_at = [datetime]::UtcNow.ToString('o'); archived = $false
                            web_url = 'https://gitlab.example/example-user/repo'
                        })
                    }
                    Mock Get-GLVOwnedGroups { @() }
                    Mock Invoke-RestMethod {
                        @(
                            [pscustomobject]@{ id = 501; iid = 1; project_id = 10; title = 'Owned task'; state = 'opened'; updated_at = [datetime]::UtcNow.ToString('o'); due_date = $null; labels = @('priority'); web_url = 'https://gitlab.example/example-user/repo/-/issues/1' },
                            [pscustomobject]@{ id = 502; iid = 2; project_id = 99; title = 'Foreign task'; state = 'opened'; updated_at = [datetime]::UtcNow.ToString('o'); due_date = $null; labels = @(); web_url = 'https://gitlab.example/other/repo/-/issues/2' }
                        )
                    }

                    $result = Get-GLVStatusSnapshot

                    $result.Summary.Projects | Should -Be 1
                    $result.Tasks.Count | Should -Be 1
                    $result.Tasks[0].Title | Should -Be 'Owned task'
                    Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                        $Uri -like '*/issues?scope=assigned_to_me*per_page=100*'
                    }
                } finally {
                    $global:_glvigor.auth = $originalAuth
                }
            }
        }
    }

    Context "GitLab Namespace Filtering" {
        BeforeEach {
            $script:originalAuth = $global:_glvigor.auth
            $script:originalGitLabOrg = $env:GITLAB_ORG
            $env:GITLAB_ORG = 'example-group'
            $global:_glvigor.auth = [pscustomobject]@{
                username   = 'example-user'
                id         = 100
                apipath    = 'https://gitlab.example/api/v4'
                apikey     = ConvertTo-SecureString 'test-token' -AsPlainText -Force
                httpstatus = 200
            }
        }

        AfterEach {
            $global:_glvigor.auth = $script:originalAuth
            $env:GITLAB_ORG = $script:originalGitLabOrg
        }

        It "Should scope issue search results using project URLs" {
            InModuleScope glvigor {
                $issues = @(
                    [pscustomobject]@{ id = 1; project_id = 10; web_url = 'https://gitlab.com/example-user/repo/-/issues/1' },
                    [pscustomobject]@{ id = 2; project_id = 20; web_url = 'https://gitlab.com/example-group/subgroup/repo/-/issues/2' },
                    [pscustomobject]@{ id = 3; project_id = 30; web_url = 'https://gitlab.com/unrelated/repo/-/issues/3' }
                )

                $result = @(Get-GLVNamespaceFilter -InputObject $issues)

                $result.id | Should -Be @(1, 2)
            }
        }

        It "Should bypass namespace filtering with Global" {
            InModuleScope glvigor {
                $issues = @(
                    [pscustomobject]@{ id = 1; web_url = 'https://gitlab.com/example-user/repo/-/issues/1' },
                    [pscustomobject]@{ id = 2; web_url = 'https://gitlab.com/unrelated/repo/-/issues/2' }
                )

                @(Get-GLVNamespaceFilter -InputObject $issues -Global).Count | Should -Be 2
            }
        }

        It "Should constrain default issue search to GitLab project ownership" {
            Mock Invoke-RestMethod -ModuleName glvigor {
                if ($Uri -like '*min_access_level=50*') {
                    return @(
                        [pscustomobject]@{ id = 10; path_with_namespace = 'example-user/repo' },
                        [pscustomobject]@{ id = 20; path_with_namespace = 'example-group/subgroup/repo' }
                    )
                }

                if ($Uri -like '*/projects/10/issues*') {
                    return @([pscustomobject]@{ id = 1; project_id = 10; title = 'Owned issue'; web_url = 'https://gitlab.example/example-user/repo/-/issues/1' })
                }

                return @()
            }

            $result = @(Search-GitLab -Type issues -Raw)

            $result.Count | Should -Be 1
            $result[0].project_id | Should -Be 10
            Should -Invoke Invoke-RestMethod -ModuleName glvigor -Times 1 -ParameterFilter {
                $Uri -like '*projects?min_access_level=50*'
            }
            Should -Invoke Invoke-RestMethod -ModuleName glvigor -Times 0 -ParameterFilter {
                $Uri -like '*/search?*'
            }
        }

        It "Should reject direct cmdlet access outside owner scope before the resource request" {
            Mock Invoke-RestMethod -ModuleName glvigor {
                if ($Uri -like '*projects?min_access_level=50*') {
                    return @([pscustomobject]@{ id = 10; path_with_namespace = 'example-user/repo' })
                }
                throw "The project resource endpoint must not be called"
            }

            { Request-Project -ProjectID 99 } | Should -Throw '*outside*owner scope*'
            Should -Invoke Invoke-RestMethod -ModuleName glvigor -Times 0 -ParameterFilter {
                $Uri -like '*/projects/99'
            }
        }

        It "Should allow direct cmdlet access to an owner-scoped group project" {
            Mock Invoke-RestMethod -ModuleName glvigor {
                if ($Uri -like '*projects?min_access_level=50*') {
                    return @([pscustomobject]@{ id = 20; path_with_namespace = 'example-group/subgroup/repo' })
                }
                if ($Uri -like '*/projects/20') {
                    return [pscustomobject]@{ id = 20; name = 'repo'; path_with_namespace = 'example-group/subgroup/repo' }
                }
            }

            $result = Request-Project -ProjectID 20

            $result.id | Should -Be 20
            Should -Invoke Invoke-RestMethod -ModuleName glvigor -Times 1 -ParameterFilter {
                $Uri -like '*/projects/20'
            }
        }

        It "Should keep every direct public project resource cmdlet behind the owner guard" {
            $publicPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', 'public'))
            $unguarded = [System.Collections.Generic.List[string]]::new()

            foreach ($file in [System.IO.Directory]::EnumerateFiles($publicPath, '*.ps1', [System.IO.SearchOption]::TopDirectoryOnly)) {
                $content = [System.IO.File]::ReadAllText($file)
                if ($content.Contains('/projects/') -and
                    -not $content.Contains('Assert-GLVProjectOwnerScope') -and
                    -not $file.EndsWith('Search-GitLab.ps1', [System.StringComparison]::OrdinalIgnoreCase)) {
                    $unguarded.Add([System.IO.Path]::GetFileName($file))
                }
            }

            $unguarded | Should -BeNullOrEmpty
        }

        It "Should reject groups outside the authenticated user's Owner scope" {
            Mock Invoke-RestMethod -ModuleName glvigor {
                if ($Uri -like '*groups?min_access_level=50*') {
                    return @([pscustomobject]@{ id = 5; full_path = 'example-group' })
                }
            }

            InModuleScope glvigor {
                { Assert-GLVGroupOwnerScope -GroupID 99 } | Should -Throw '*outside*Owner scope*'
            }
        }

        It "Should not broaden namespace filtering when ownership context is unavailable" {
            $env:GITLAB_ORG = $null
            $global:_glvigor.auth = $null

            InModuleScope glvigor {
                $projects = @([pscustomobject]@{ id = 1; path_with_namespace = 'unrelated/repo' })
                @(Get-GLVNamespaceFilter -InputObject $projects).Count | Should -Be 0
            }
        }

        It "Should pass Global through the task list route" {
            Mock Search-GitLab -ModuleName glvigor { @([pscustomobject]@{ id = 1 }) }
            Mock Write-GLVTable -ModuleName glvigor

            Invoke-GLVigor task list -Global

            Should -Invoke Search-GitLab -ModuleName glvigor -Times 1 -ParameterFilter {
                $Type -eq 'issues' -and $Raw -and $Global
            }
        }

        It "Should pass Global through the merge list route" {
            Mock Search-GitLab -ModuleName glvigor { @([pscustomobject]@{ id = 1 }) }
            Mock Write-GLVTable -ModuleName glvigor

            Invoke-GLVigor merge list -Global

            Should -Invoke Search-GitLab -ModuleName glvigor -Times 1 -ParameterFilter {
                $Type -eq 'merge_requests' -and $Raw -and $Global
            }
        }
    }
}
