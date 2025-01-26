using module G:\devspace\projects\powershell\_repos\githubreadmehelper\githubreadmehelper.psm1
<# EXAMPLE#>

$projectname        = 'glvigor'
$user               = 'sgkens'
$projectdescription = 'Glvigor provides a number of cmdlets to interact with gitlab api allowing you to search and edit gitlab resources and from with in git and you git respository.'
$group              = 'powershell'
$branch             = "main"
$gitlaburl          = "https://$ENV:GITLAB_HOST"
$badgeType          =  'for-the-badge'
$logoColor          = 'OrangeRed'
$labelColor         = 'White'
$color              = 'OrangeRed'

# Example
Build-GithubReadme -projectname $projectname `
                   -gitlaburl $gitlaburl `
                   -user $user `
                   -projectdescription $projectdescription `
                   -ShieldIoBagdeType $badgeType `
                   -ShieldIoLabelcolor $logoColor `
                   -ShieldIoLogoColor $labelColor `
                   -ShieldIoColor $color `
                   -branch $branch `
                   -group $group `
                   -buildpackages