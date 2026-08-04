function ConvertTo-AsciiTokens {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Lines,

        # 4-connectivity treats diagonal-only touching chars as separate
        # tokens; 8-connectivity merges them. Use 8 for "loose" line art
        # like slashes/backslashes that only touch at corners.
        [ValidateSet(4, 8)]
        [int]$Connectivity = 8
    )

    begin {
        $inputLines = [System.Collections.Generic.List[string]]::new()
    }

    process {
        foreach ($line in $Lines) {
            if ($null -ne $line) {
                [void]$inputLines.Add($line)
            }
        }
    }

    end {
        if ($inputLines.Count -eq 0) { return $null }

        $width  = ($inputLines | Measure-Object -Property Length -Maximum).Maximum
        if (-not $width) { $width = 0 }
        $padded = $inputLines | ForEach-Object { $_.PadRight($width) }
        $height = $padded.Count

        $grid = New-Object 'char[][]' $height
        for ($y = 0; $y -lt $height; $y++) { $grid[$y] = $padded[$y].ToCharArray() }

        $visited = New-Object 'bool[,]' $height, $width
        $tokenId = 0
        $tokens  = [System.Collections.Generic.List[object]]::new()

        $dirs4 = @(@(0,1), @(0,-1), @(1,0), @(-1,0))
        $dirs8 = $dirs4 + @(@(1,1), @(1,-1), @(-1,1), @(-1,-1))
        $dirs  = if ($Connectivity -eq 8) { $dirs8 } else { $dirs4 }

        for ($y = 0; $y -lt $height; $y++) {
            for ($x = 0; $x -lt $width; $x++) {
                if ($visited[$y, $x]) { continue }
                $ch = $grid[$y][$x]
                if ($ch -eq ' ' -or $ch -eq "`t") { $visited[$y, $x] = $true; continue }

                # BFS flood fill - each cell is visited exactly once total
                $queue = [System.Collections.Generic.Queue[object]]::new()
                $queue.Enqueue(@($y, $x))
                $visited[$y, $x] = $true
                $cells   = [System.Collections.Generic.List[object]]::new()
                $charSet = [System.Collections.Generic.HashSet[char]]::new()
                $minX = $maxX = $x
                $minY = $maxY = $y

                while ($queue.Count -gt 0) {
                    $cy, $cx = $queue.Dequeue()
                    $cells.Add(@($cy, $cx))
                    [void]$charSet.Add($grid[$cy][$cx])
                    if ($cx -lt $minX) { $minX = $cx }
                    if ($cx -gt $maxX) { $maxX = $cx }
                    if ($cy -lt $minY) { $minY = $cy }
                    if ($cy -gt $maxY) { $maxY = $cy }

                    foreach ($d in $dirs) {
                        $ny = $cy + $d[0]; $nx = $cx + $d[1]
                        if ($ny -ge 0 -and $ny -lt $height -and $nx -ge 0 -and $nx -lt $width -and -not $visited[$ny, $nx]) {
                            $g = $grid[$ny][$nx]
                            if ($g -ne ' ' -and $g -ne "`t") {
                                $visited[$ny, $nx] = $true
                                $queue.Enqueue(@($ny, $nx))
                            }
                        }
                    }
                }

                $tokens.Add([pscustomobject]@{
                    Id          = $tokenId++
                    Cells       = $cells
                    BoundingBox = [pscustomobject]@{ X = $minX; Y = $minY; W = ($maxX - $minX + 1); H = ($maxY - $minY + 1) }
                    CharCount   = $cells.Count
                    CharSet     = -join $charSet
                })
            }
        }

        return [pscustomobject]@{
            Width  = $width
            Height = $height
            Lines  = $padded
            Tokens = $tokens
        }
    }
}
