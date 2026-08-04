# ==============================================================================
# File: Public/Start-GLVTui.ps1
# ==============================================================================
function Start-GLVTui {
    <#
    .SYNOPSIS
        Flicker-free interactive TUI dashboard with Arrow and Vim key navigation.
    .DESCRIPTION
        Renders an alt-buffer TUI supporting Up/Down/j/k navigation, Enter/Space selection,
        and Escape/q back/exit controls without console clear screen flicker.
    .PARAMETER BorderStyle
        Border rendering style for TUI panels.
    .PARAMETER ActiveView
        Initial menu view mode.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('Thin', 'Double', 'Rounded', 'None')]
        [string]$BorderStyle = 'Rounded',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Menu', 'Repo', 'Task', 'Merge', 'Tags', 'Package')]
        [string]$ActiveView = 'Menu'
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
    }

    process {
        Enable-TerminalAltBuffer
        Hide-TerminalCursor

        try {
            $running = $true
            $currentView = $ActiveView
            $selectedIndex = 0

            # Menu structures (Label, TargetView)
            $mainMenuItems = @(
                @{ Label = "Repo CRUD      (Projects & Mirrors)";     Target = 'Repo' }
                @{ Label = "Task CRUD      (Issues & Milestones)";    Target = 'Task' }
                @{ Label = "Merge CRUD     (Merge Requests & Reviews)"; Target = 'Merge' }
                @{ Label = "Tags CRUD      (Tags, SemVer & Releases)";  Target = 'Tags' }
                @{ Label = "Package CRUD   (Generic Packages & Uploads)"; Target = 'Package' }
                @{ Label = "Quit Dashboard";                           Target = 'Quit' }
            )

            $subViewItems = @{
                'Repo' = @(
                    @{ Label = "List All Projects"; Action = 'ListRepo' }
                    @{ Label = "Get Project Details"; Action = 'GetRepo' }
                    @{ Label = "Create New Project"; Action = 'CreateRepo' }
                    @{ Label = "Back to Main Menu"; Action = 'Back' }
                )
                'Task' = @(
                    @{ Label = "List Project Issues"; Action = 'ListTask' }
                    @{ Label = "Get Issue Details"; Action = 'GetTask' }
                    @{ Label = "Register New Issue"; Action = 'CreateTask' }
                    @{ Label = "Back to Main Menu"; Action = 'Back' }
                )
                'Merge' = @(
                    @{ Label = "List Merge Requests"; Action = 'ListMerge' }
                    @{ Label = "Get Merge Request Details"; Action = 'GetMerge' }
                    @{ Label = "Back to Main Menu"; Action = 'Back' }
                )
            }

            # Pre-render static top banner
            $bannerText = " GLVIGOR - GITLAB FULL CONTROL TUI "
            $gradientBanner = New-AsciiGradient -Type fg -Steps @(39, 45, 51, 82) -String $bannerText -Format bold
            $headerPanel = New-TuiPanel -Content $gradientBanner -Title "Vigor Shell" -BorderStyle $BorderStyle -Alignment Center -Width 80

            # Initial full clear once
            [Console]::Clear()

            while ($running) {
                # Determine items for active view
                $items = if ($currentView -eq 'Menu') { $mainMenuItems } else { $subViewItems[$currentView] }
                if ($null -eq $items) { $items = $mainMenuItems; $currentView = 'Menu' }

                # Clamp selected index
                if ($selectedIndex -ge $items.Count) { $selectedIndex = $items.Count - 1 }
                if ($selectedIndex -lt 0) { $selectedIndex = 0 }

                # Build rendered lines for current state
                $renderedLines = @()
                for ($i = 0; $i -lt $items.Count; $i++) {
                    $item = $items[$i]
                    if ($i -eq $selectedIndex) {
                        # Highlighted active item (Neon Teal accent indicator)
                        $renderedLines += "`e[1;38;5;39m▶ [x] $($item.Label)`e[0m"
                    } else {
                        # Standard inactive item
                        $renderedLines += "  [ ] $($item.Label)"
                    }
                }

                $panelTitle = switch ($currentView) {
                    'Repo'  { "Repo Manager (↑/↓/j/k, Enter/Space, Esc)" }
                    'Task'  { "Task Manager (↑/↓/j/k, Enter/Space, Esc)" }
                    'Merge' { "Merge Request Manager (↑/↓/j/k, Enter/Space, Esc)" }
                    default { "Navigation Menu (↑/↓/j/k, Enter/Space, Esc)" }
                }

                $mainPanel = New-TuiPanel -Content $renderedLines -Title $panelTitle -BorderStyle $BorderStyle -Width 80

                # Reposition cursor to top-left (0,0) without clearing to eliminate screen flicker
                [Console]::SetCursorPosition(0, 0)
                [Console]::WriteLine($headerPanel)
                [Console]::WriteLine($mainPanel)

                # Blocking key read for instant, flicker-free event processing
                $keyInfo = [Console]::ReadKey($true)
                $key = $keyInfo.Key
                $keyChar = $keyInfo.KeyChar.ToString().ToLower()

                # Navigation Logic: Arrow keys, Vim (j/k), Space/Enter, Escape
                if ($key -eq [ConsoleKey]::UpArrow -or $keyChar -eq 'k') {
                    if ($selectedIndex -gt 0) { $selectedIndex-- }
                }
                elseif ($key -eq [ConsoleKey]::DownArrow -or $keyChar -eq 'j') {
                    if ($selectedIndex -lt ($items.Count - 1)) { $selectedIndex++ }
                }
                elseif ($key -eq [ConsoleKey]::Enter -or $key -eq [ConsoleKey]::Spacebar) {
                    $selectedItem = $items[$selectedIndex]
                    if ($currentView -eq 'Menu') {
                        if ($selectedItem.Target -eq 'Quit') {
                            $running = $false
                        } else {
                            $currentView = $selectedItem.Target
                            $selectedIndex = 0
                        }
                    } else {
                        if ($selectedItem.Action -eq 'Back') {
                            $currentView = 'Menu'
                            $selectedIndex = 0
                        }
                    }
                }
                elseif ($key -eq [ConsoleKey]::Escape -or $keyChar -eq 'q') {
                    if ($currentView -ne 'Menu') {
                        $currentView = 'Menu'
                        $selectedIndex = 0
                    } else {
                        $running = $false
                    }
                }
            }
        }
        finally {
            Show-TerminalCursor
            Disable-TerminalAltBuffer
        }
    }
}
