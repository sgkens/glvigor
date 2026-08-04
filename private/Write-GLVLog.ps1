# ==============================================================================
# File: Private/Write-GLVLog.ps1
# ==============================================================================
function Write-GLVLog {
    <#
    .SYNOPSIS
        Cyberpunk / Retro-Futuristic high-density logging engine for GLVigor.
    .DESCRIPTION
        Renders rich gradients, max 3-letter status badges, and safe ASCII glyphs for 100% tear-free output.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Debug', 'Api')]
        [string]$Level = 'Info',

        [Parameter(Mandatory = $false)]
        [string]$Category = 'GLV',

        [Parameter(Mandatory = $false)]
        [int]$Padding = 0
    )

    begin {
        $levelConfig = @{
            Info    = @{ Code = 'INF'; Icon = '●'; GradientSteps = @(39, 45, 51);   BadgeColor = 39  } # Cyan Ramp
            Success = @{ Code = 'OK!'; Icon = '●'; GradientSteps = @(82, 118, 120); BadgeColor = 82  } # Neon Green
            Warning = @{ Code = 'WRN'; Icon = '▲'; GradientSteps = @(214, 208, 202); BadgeColor = 214 } # Amber
            Error   = @{ Code = 'ERR'; Icon = 'x'; GradientSteps = @(196, 160, 124); BadgeColor = 196 } # Crimson
            Debug   = @{ Code = 'DBG'; Icon = '*'; GradientSteps = @(244, 240, 236); BadgeColor = 244 } # Slate
            Api     = @{ Code = 'API'; Icon = '▸'; GradientSteps = @(141, 135, 129); BadgeColor = 141 } # Neon Purple
        }
    }

    process {
        $cfg = $levelConfig[$Level]

        # 1. Pre-calculate layout string lengths before applying ANSI formatting
        # Force category to max 3 characters for strict uniformity
        $shortCat = if ($Category.Length -gt 3) { $Category.Substring(0, 3).ToUpper() } else { $Category.PadRight(3).ToUpper() }
        
        $badgeText = "$($cfg.Icon) $($cfg.Code)"
        $categoryText = " $shortCat "
        $rawMessage = if ($Padding -gt 0) { "{0,-$Padding}" -f $Message } else { $Message }

        # 2. Render Gradient Category Badge
        $gradientCategory = New-AsciiGradient -Type fg -Steps $cfg.GradientSteps -String $categoryText -Format bold

        # 3. Render Status Badge
        $statusBadge = New-AsciiColor -string "[$badgeText]" -color $cfg.BadgeColor -Format Bold

        # 4. Render Safe Flow Separator Line
        $separator = New-AsciiColor -string "->" -color 240

        # 5. Render Message Body
        $coloredMsg = New-AsciiColor -string $rawMessage -color 15

        # Output single high-density uniform line
        [Console]::WriteLine(" $gradientCategory $statusBadge $separator $coloredMsg")
    }
}
