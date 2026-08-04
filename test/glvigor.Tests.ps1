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
}
