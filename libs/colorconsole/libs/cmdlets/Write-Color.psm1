Function Write-Color() {
    [CmdletBinding()]
    [Alias('wsole')]
    [OutputType([void])]
    param(
        [parameter(mandatory = $true, Position = 0)]
        [string]$string,
        [parameter(mandatory = $false, Position = 1)]
        [int]$color = 15,
        [parameter(mandatory = $false)]
        [int]$bgcolor = 0,
        [parameter(mandatory = $false)]
        [int]$padding = 0,
        [parameter(mandatory = $false)]
        [switch]$nl
    )
    Begin{
        $coloredText = New-ColorConsole -string $string -color $color -bgcolor $bgcolor -padding $padding
    }
    Process{
        if($nl){
            [Console]::Write("$($coloredText)`n")
        }else{
            [Console]::Write($coloredText)
        }
    }
}