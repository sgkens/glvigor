function Show-UHCommandCatalog {
    <#
    .SYNOPSIS
      Opens a keyboard-navigable catalogue of public PowerShell module commands.
    .DESCRIPTION
      Displays commands in two or three columns. Arrow keys move selection, Page Up/Page Down move
      between pages, Home/End jump to the first or last command, Enter opens Get-Help -Full in the
      UHWriter pager, and Q or Escape exits.
    .PARAMETER InputObject
      Command catalogue objects from Get-UHModuleCommand.
    .PARAMETER Module
      Module names or wildcard patterns to discover when InputObject is not supplied.
    .PARAMETER Columns
      Number of catalogue columns.
    .PARAMETER Name
      Command wildcard filters.
    .PARAMETER Category
      PowerShell verb-group filters.
    .PARAMETER PassThru
      Returns the selected command instead of opening help.
    .EXAMPLE
      Show-UHCommandCatalog -Module UHWriter
    .EXAMPLE
      Get-UHModuleCommand -Module Microsoft.PowerShell.* -Category Diagnostic |
          Show-UHCommandCatalog -Columns 3
    .OUTPUTS
      UHWriter.ModuleCommand when PassThru is specified.
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [psobject[]]$InputObject,
        [SupportsWildcards()]
        [string[]]$Module = @('UHWriter'),
        [ValidateSet(2, 3)]
        [int]$Columns = 2,
        [SupportsWildcards()]
        [string[]]$Name = @('*'),
        [SupportsWildcards()]
        [string[]]$Category = @('*'),
        [switch]$PassThru
    )

    begin { $catalog = [System.Collections.Generic.List[object]]::new() }
    process {
        foreach ($item in $InputObject) {
            if ($null -ne $item) { $catalog.Add($item) }
        }
    }
    end {
        if ($catalog.Count -eq 0) {
            foreach ($item in Get-UHModuleCommand -Module $Module -Name $Name -Category $Category) {
                $catalog.Add($item)
            }
        }
        $items = @($catalog | Sort-Object Category, ModuleName, Name)
        if ($items.Count -eq 0) {
            Write-Warning 'No public module commands matched the catalogue filters.'
            return
        }

        # Redirected hosts cannot read navigation keys. Returning objects preserves pipeline behavior.
        if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) {
            if ($PassThru) { Write-Output $items[0] } else { Write-Output $items }
            return
        }

        $esc = [char]27
        $reset = "${esc}[0m"
        $selectedStyle = "${esc}[7m"
        $hideCursor = "${esc}[?25l"
        $showCursor = "${esc}[?25h"
        $enterAlt = "${esc}[?1049h"
        $leaveAlt = "${esc}[?1049l"
        $selected = 0

        try {
            [Console]::Write($enterAlt + $hideCursor)
            while ($true) {
                $width = [Math]::Max(45, [Console]::WindowWidth)
                $height = [Math]::Max(8, [Console]::WindowHeight)
                $rowsPerPage = [Math]::Max(1, $height - 4)
                $itemsPerPage = $rowsPerPage * $Columns
                $pageStart = [int]([Math]::Floor($selected / $itemsPerPage) * $itemsPerPage)
                $columnWidth = [Math]::Max(12, [int][Math]::Floor(($width - ($Columns - 1)) / $Columns))
                $builder = [System.Text.StringBuilder]::new($height * $width)
                [void]$builder.Append("${esc}[2J${esc}[H")
                $title = "UHWriter command catalogue | $($items.Count) public commands | ${Columns} columns"
                [void]$builder.AppendLine($title.Substring(0, [Math]::Min($title.Length, $width)))

                for ($row = 0; $row -lt $rowsPerPage; $row++) {
                    for ($column = 0; $column -lt $Columns; $column++) {
                        $index = $pageStart + ($column * $rowsPerPage) + $row
                        if ($index -ge $items.Count) {
                            [void]$builder.Append(''.PadRight($columnWidth))
                            continue
                        }
                        $item = $items[$index]
                        $label = '{0} [{1}]' -f $item.Name, $item.Category
                        if ($label.Length -gt ($columnWidth - 2)) {
                            $label = $label.Substring(0, [Math]::Max(1, $columnWidth - 3)) + '…'
                        }
                        $cell = (' ' + $label).PadRight($columnWidth)
                        if ($index -eq $selected) {
                            [void]$builder.Append($selectedStyle).Append($cell).Append($reset)
                        } else {
                            [void]$builder.Append($cell)
                        }
                        if ($column -lt ($Columns - 1)) { [void]$builder.Append('│') }
                    }
                    [void]$builder.AppendLine()
                }

                $pageNumber = [Math]::Floor($pageStart / $itemsPerPage) + 1
                $pageCount = [Math]::Ceiling($items.Count / $itemsPerPage)
                [void]$builder.Append("Arrows navigate | PgUp/PgDn page | Enter help | Q quit | page $pageNumber/$pageCount")
                [Console]::Write($builder.ToString())

                $key = [Console]::ReadKey($true)
                switch ($key.Key) {
                    UpArrow    { $selected = [Math]::Max(0, $selected - 1) }
                    DownArrow  { $selected = [Math]::Min($items.Count - 1, $selected + 1) }
                    LeftArrow  { $selected = [Math]::Max(0, $selected - $rowsPerPage) }
                    RightArrow { $selected = [Math]::Min($items.Count - 1, $selected + $rowsPerPage) }
                    PageUp     { $selected = [Math]::Max(0, $selected - $itemsPerPage) }
                    PageDown   { $selected = [Math]::Min($items.Count - 1, $selected + $itemsPerPage) }
                    Home       { $selected = 0 }
                    End        { $selected = $items.Count - 1 }
                    Enter {
                        [Console]::Write($leaveAlt + $showCursor)
                        if ($PassThru) {
                            Write-Output $items[$selected]
                            return
                        }
                        $helpText = Get-Help -Name $items[$selected].Name -Full |
                            Out-String -Width ([Math]::Max(45, [Console]::WindowWidth))
                        Invoke-UHPager -Content $helpText -Title "$($items[$selected].Name) help" -NoColor
                        [Console]::Write($enterAlt + $hideCursor)
                    }
                    Escape { return }
                    Q { return }
                }
            }
        }
        finally { [Console]::Write($reset + $showCursor + $leaveAlt) }
    }
}
