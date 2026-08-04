using module .\auspex.psm1

<# Class: ColorValidator - Validates color names #>
class ColorValidator : System.Management.Automation.ValidateArgumentsAttribute {
    [void] Validate([object] $arguments, [System.Management.Automation.EngineIntrinsics] $engineIntrinsics) {
        $validColors = $global:__psshields.color_pallete.colorGroups.colors.name
        if ($validColors -notcontains $arguments) {
            throw "Invalid color name. Use Get-ColorPallete to see valid colors."
        }
    }
}

<# ArgumentCompleter for color parameters #>
class ColorCompleter : System.Management.Automation.IArgumentCompleter {
    [System.Collections.Generic.IEnumerable[System.Management.Automation.CompletionResult]] CompleteArgument(
        [string] $commandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [System.Management.Automation.Language.CommandAst] $commandAst,
        [System.Collections.IDictionary] $fakeBoundParameters
    ) {
        $results = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
        
        # Get colors from the global palette
        $colors = $global:__psshields.color_pallete.colorGroups.colors
        
        foreach ($color in $colors) {
            if ($color.name -like "$wordToComplete*") {
                $completionText = $color.name
                $listItemText = $color.name
                $resultType = [System.Management.Automation.CompletionResultType]::ParameterValue
                $toolTip = "Hex: $($color.hex) | RGB: $($color.rgb -join ',')"
                
                $results.Add([System.Management.Automation.CompletionResult]::new(
                    $completionText,
                    $listItemText,
                    $resultType,
                    $toolTip
                ))
            }
        }
        
        return $results
    }
}

<# ArgumentValidator for BadgeType parameters #>
class BadgeTypeValidator : System.Management.Automation.ValidateArgumentsAttribute {
    [void] Validate([object] $arguments, [System.Management.Automation.EngineIntrinsics] $engineIntrinsics) {
        # Fetch Badge Types
        $badgeTypes = (Get-PlatformConfig | Select-Object -ExpandProperty Values | Select-Object  -ExpandProperty badges).keys -join ','
        [string[]]$badgeTypes_array = $badgeTypes.split(',')

        if ($badgeTypes -notcontains $arguments) {
            throw "Invalid color name. Use Invoke-ShieldsCommander -ViewBadgeTypes to see valid badges."
        }
    }
}

<# ArgumentCompleter for BadgeType parameters #>
class BadgeTypeCompleter : System.Management.Automation.IArgumentCompleter {
    [System.Collections.Generic.IEnumerable[System.Management.Automation.CompletionResult]] CompleteArgument(
        [string] $commandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [System.Management.Automation.Language.CommandAst] $commandAst,
        [System.Collections.IDictionary] $fakeBoundParameters
    ) {
        $results = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
        
        # Fetch Badge Types
        $badgeTypes = (Get-PlatformConfig | Select-Object -ExpandProperty Values | Select-Object  -ExpandProperty badges).keys -join ','
        [string[]]$badgeTypes_array = $badgeTypes.split(',')
        foreach ($badge in $badgeTypes_array) {
            if ($badge -like "$wordToComplete*") {
                $completionText = $badge
                $listItemText = $badge
                $resultType = [System.Management.Automation.CompletionResultType]::ParameterValue
                
                $toolTip = "badge: $($badge)"
                
                $results.Add([System.Management.Automation.CompletionResult]::new(
                    $completionText,
                    $listItemText,
                    $resultType,
                    $toolTip
                ))
            }
        }
        
        return $results
    }
}


<# ArgumentCompleter for Platforms parameters #>
class PlatformTypeCompleter : System.Management.Automation.IArgumentCompleter {
    [System.Collections.Generic.IEnumerable[System.Management.Automation.CompletionResult]] CompleteArgument(
        [string] $commandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [System.Management.Automation.Language.CommandAst] $commandAst,
        [System.Collections.IDictionary] $fakeBoundParameters
    ) {
        $results = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
        
        # Fetch Badge Types
        [string[]]$badgeTypes = (get-PlatformConfig).keys -join "," -split ','
        foreach ($badge in $badgeTypes) {
            if ($badge -like "$wordToComplete*") {
                $completionText = $badge
                $listItemText = $badge
                $resultType = [System.Management.Automation.CompletionResultType]::ParameterValue
                
                $toolTip = "badge: $($badge)"
                
                $results.Add([System.Management.Automation.CompletionResult]::new(
                    $completionText,
                    $listItemText,
                    $resultType,
                    $toolTip
                ))
            }
        }
        
        return $results
    }
}
