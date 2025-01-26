# $name = 'psmpacker' # name of the project to mirror
# $description = 'PSMPacker is a PowerShell utility module designed to assist in the creation of versioned folders for PowerShell module and script projects. It provides functions to create versioned folders, update version numbers in module manifests and script files, copy files and folders to the destination folder, and create zip archives of the build folder.'
# $group = 'phellams' # group name to mirror to omite if user not in group
# $mirror_namespace_gitlab = $group 
# $mirror_namespace_github = $group 
# $mirror_namespace_gitea = $group 
# $gitlab_user = 'sgkens' # gitlab.com requires the {https://user:token@..} <- fails to authenticate with the api key when using the {https://token@..}
# #$user = 'phellams'

#==============b
# LOCAL
# ====================  
# auth gitlab local
Request-GitlabAuth -hostname $env:GITLAB_HOST -apiKey $env:GITLAB_API_KEY

[array] $repository_projects = @()
$user = 'sgkens'

foreach ($project in (search-gitlab -type projects -raw)) {
    $repository_projects += @{
        name                    = $project.name;
        description             = $project.description;
        user                    = $user
        id                      = $project.id;
        group                   = if ($user -ne $project.namespace.full_path) { $project.namespace.full_path } else { $null };
        mirror_namespace_gitlab = if ($user -ne $project.namespace.full_path) { $project.namespace.full_path } else { $null };
        mirror_namespace_github = if ($user -ne $project.namespace.full_path) { $project.namespace.full_path } else { $null };
        mirror_namespace_gitea  = if ($user -ne $project.namespace.full_path) { $project.namespace.full_path } else { $null };
    }
}

$counter = 0
foreach ($project in $repository_projects.where({ $_.name -notcontains @('Monitoring', 'gitlab-instance') })) {
    $counter++;
    if($counter -lt 10){start-sleep -Milliseconds 100}
    else{
        start-sleep -Seconds 10; 
        $counter = 0;
        [console]::writeline("sleeping for 60 seconds... $counter")
    }
    # setup mirror to github.com from gitlab.com all branches
    # =======================================
    # $mirror_config_gitlab = @{
    #     ProjectName  = $project.name;
    #     Endpoint     = "gitlab";
    #     Namespace    = $project.mirror_namespace_gitlab;
    #     APIKey       = $ENV:GITLAB_API_KEY;
    #     Enabled      = $true;
    #     byPassPrompt = $true;
    #     user         = $user 
    # }
    # Register-MirrorConfig @mirror_config_gitlab
    

    # Unregister existing mirrors for all Repositories
    # Request-MirrorConfig -projectid $project.id -raw | % { 
    #     unregister-mirrorconfig -projectid $project.id -mirrorid $_.id
    #     start-sleep -Milliseconds 500
    # }

    # Create project on gitea local
    # =======================================
    # if ($null -eq $group) {
    #     $Getia_props = @{
    #         Name        = $project.name;
    #         apiKey      = $env:GITEA_API_KEY;
    #         Hostname    = $env:GITEA_HOST;
    #         Group       = $project.group;
    #         Description = $project.description
    #     }
    #     Register-GiteaRepository @Getia_props
    # }
    # else {
    #     $Getia_props = @{
    #         Name        = $project.name;
    #         apiKey      = $env:GITEA_API_KEY;
    #         Hostname    = $env:GITEA_HOST;
    #         User        = $project.user;
    #         Description = $project.description
    #     }
    #     Register-GiteaRepository @Getia_props
    # }
    # =======================================
    # setup mirror to gitlab.com from gitlab local
    $gitlab_props = @{
        ProjectName = $project.name;
        Endpoint    = 'gitlab';
        User        = $project.user;
        Namespace   = $project.mirror_namespace_gitlab;
        APIKey      = $ENV:GITLAB_PUBLIC_API_KEY;
        Enabled     = $true
        byPassPrompt = $true
    }
    Register-MirrorConfig @gitlab_props
}

# REMOTE    
# =======================================
# re-auth gitlab.com
# Request-GitlabAuth -hostname gitlab.com -apiKey $ENV:GITLAB_PUBLIC_API_KEY
# $counter = 0
# foreach ($project in $repository_projects.where({ $_.name -notcontains @('Monitoring', 'gitlab-instance') })) {
#     $counter++;
#     if($counter -lt 10){start-sleep -Milliseconds 100}
#     else{
#         start-sleep -Seconds 10; 
#         $counter = 0;
#         [console]::writeline("sleeping for 60 seconds... $counter")
#     }

    # Unregister existing mirrors for all Repositories
    # $project_id = search-gitlab -type projects -title $project.name -match -raw | select-object -ExpandProperty id
    # Request-MirrorConfig -projectid $project_id -raw | % { 
    #     unregister-mirrorconfig -projectid $project_id -mirrorid $_.id
    #     start-sleep -Milliseconds 500
    # }

    # # setup project on gitlab.com
    # # =======================================
    # if ($null -eq $group) { 
    #     Register-Project -Name $project.name -Description $project.description -Group $project.group 
    # }
    # else {
    #      Register-Project -Name $project.name -Description $project.description -User $project.user 
    #     }

    # # setup project on github.com
    # # =======================================
    # if ($null -eq $group) { 
    #     Register-GithubRepository -Name $project.name -apikey $env:GITHUB_API_KEY -group $project.group -Description $project.description 
    # }
    # else { 
    #     Register-GithubRepository -Name $project.name -apikey $env:GITHUB_API_KEY -user $project.user -Description $project.description 
    # }

    # # setup mirror to github.com from gitlab.com only protected branches
    # allow time for repositories to be created
    # =======================================
    # start-sleep 3

    # Github
#     $mirror_config_github = @{
#         ProjectName = $project.name;
#         Endpoint    = 'github';
#         Namespace   = $project.mirror_namespace_github;
#         APIKey      = $ENV:GITHUB_API_KEY;
#         Enabled     = $true;
#         OnlyProtected = $true;
#         byPassPrompt = $true
#     }
#     register-mirrorconfig @mirror_config_github

#     # Gitea Self-hosted
#     $mirror_config_gitlab = @{
#         ProjectName  = $project.name;
#         Endpoint     = "gitea";
#         Namespace    = $project.mirror_namespace_gitea;
#         APIKey       = $env:GITEA_API_KEY;
#         GiteaHost    = $env:GITEA_HOST;
#         Enabled      = $true;
#         byPassPrompt = $true;
#     }
#     Register-MirrorConfig @mirror_config_gitlab
# }

