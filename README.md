# <img width="56" src="https://raw.githubusercontent.com/sgkens/resources/main/modules/glvigor/glvigor-logo.svg"/>  **GLVigor**

✅-PowerShell Core(pwsh) 7.x 🚧-Powershell(powershell) 5.x
<!--license-->
<a href="https://github.com/sgkens/glvigor/blob/main/LICENSE">
<img src="https://img.shields.io/badge/license-mit-blue?style=for-the-badge&logo=unlicense&label=License&logoColor=rgba(255%2C255%2C255 245%2C245%2C245%2C1)&labelColor=rgba(255%2C165%2C0 255%2C69%2C0%2C1)&color=rgba(178%2C34%2C34%2C1)"></a><!--Code-Factor-->
<a href="https://www.codefactor.io/repository/github/sgkens/glvigor">
<img src="https://img.shields.io/codefactor/grade/github/sgkens/glvigor?style=for-the-badge&logo=codefactor&label=codefactor&logoColor=255%2C255%2C255 245%2C245%2C245%2C1&labelColor=rgba(255%2C165%2C0 255%2C69%2C0%2C1)&color=rgba(178%2C34%2C34%2C1)"></a><!--coverage-->
<a href="https://coveralls.io/github/sgkens/glvigor">
<img src="https://img.shields.io/coverallsCoverage/github/sgkens/glvigor?style=for-the-badge&logo=coveralls&label=coveralls&logoColor=rgba(255%2C255%2C255 245%2C245%2C245%2C1)&labelColor=rgba(255%2C165%2C0 255%2C69%2C0%2C1)&color=rgba(178%2C34%2C34%2C1)"></a>

---

***GLViger*** offers a comprehensive set of cmdlets for managing key resources on a GitLab instance. With this module, you can create, view, update, remove, and search for *issues*, *merge requests*, *projects*, *groups*, and *labels* through the GitLab API. Additionally, the module includes cmdlets for handling Git-related functions, such as *viewing*, *adding*, and removing *mirrors*, as well as updating the *origin*.

# Features
✔•-( ***Completed*** ❌•-( ***Work In Progress***
## 🔵 ***GitLab API***
 - ✔ Search resources: ***projects***, ***issues***, ***merge_requests***, ***snippet_titles***, ***users***, ~~***⚒ blobs***~~, ***commits***, ***groups***, ~~***⚒ notes***~~ 
     -  **Cmdlets**
         - ***Create*** [*🧅 Search-Gitlab*](#🧅-Search-Gitlab)
 - ✔`CRUD` Operations on project ***Mirror Configurations***: ***github***, ***gitlab***, ***gitea***, ***gitlalen**(Self-Hosted Community Edition|Enterpise
     - **Cmdlets**:
         - ***Create*** [*🧅 Register-MirrorConfig*](#🧅-Register-MirrorConfig)
         - ***Read*** [*🧅 Request-MirrorConfig*](#🧅-Request-MirrorConfig)
         - ***Update*** [*🧅 Update-MirrorConfig*](#🧅-Update-MirrorConfig)
         - ***Delete*** [*🧅 Unregister-MirrorConfig*](#🧅-Unregister-MirrorConfig)
 - ✔ `CRUD` operations on **Issues**, supported types ***issue***, ***incident***, and ***task***, Filter by ***State***, ***Milestone***, ***labels***.
     - **Cmdlets**:
         - ***Create*** [*🧅 Register-Issue*](#🧅-Register-Issue)
         - ***Read*** [*🧅 Request-Issue*](#🧅-Request-Issue)
         - ***Update*** [*🧅 Update-Issue*](#🧅-Update-Issue)
         - ***Delete*** [*🧅 Unregister-Issue*](#🧅-Unregister-Issue)
 - ✔|🚧 `CRUD` operations on **projects**.
     - **Cmdlets**:
         - ***Create*** [*🧅 Register-Project*](#🧅-Register-Project)
         - ***Read*** [*🧅 Request-Project*](#🧅-Request-Project)
         - ***Update*** [*🧅 Update-Project*](#🧅-Update-Project)
         - ***Delete*** [*🧅 Unregister-Project*](#🧅-Unregister-Project)
  - ✔ `CRUD` operations on **groups**.
      - **Cmdlets**:
          - ***Create*** [*🧅 Register-Group*](#🧅-Register-Group)
          - ***Read*** [*🧅 Request-Group*](#🧅-Request-Group)
          - ***Update*** [*🧅 Update-Group*](#🧅-Update-Group)
          - ***Delete*** [*🧅 Unregister-Group*](#🧅-Unregister-Group)
  - ✔ `CRUD` operations on **labels**.
      - **Cmdlets**:
          - ***Create*** [*🧅 Register-Label*](#🧅-Register-Label)
          - ***Read*** [*🧅 Request-Label*](#🧅-Request-Label)
          - ***Update*** [*🧅 Update-Label*](#🧅-Update-Label)
          - ***Delete*** [*🧅 Unregister-Label*](#🧅-Unregister-Label)
 - ✔ `CRUD` operations on **merge_requests**.
     - **Cmdlets**:
         - ***Create*** [*🧅 Register-MergeRequest*](#🧅-Register-MergeRequest)
         - ***Read*** [*🧅 Request-MergeRequest*](#🧅-Request-MergeRequest)
         - ***Update*** [*🧅 Update-MergeRequest*](#🧅-Update-MergeRequest)
         - ***Delete*** [*🧅 Unregister-MergeRequest*](#🧅-Unregister-MergeRequest)
 - ✔ ***Get*** blobs. [*🧅 Request-Blob*](#🧅-Request-Blob)


## 🔵 ***Git CMD***
 - ✔ ***Get/update*** git origin, returns non-mirrored origin as a `pscustomobject`
 - ✔ ***Create/Get/Delete/update*** local remote mirrors, supported endpoints: *`github`*, *`gitlab`*, *`gitea`*, *`gitlalen SE(CE|EE)`*.
 - ✔ ***Get*** gitlog filter based on `branch`, `commit-id`, `commit-id-short`, `commit-title`

# Install module

📦 Installing from Package Repositories or `.nupkg` files see [***Releases***](https://)

🛖 Installing from git repository:

1. 📥 Cone Repository.
    ```bash
    git clone https://gitlab.com/glvigor/glvigor.git
    ``` 
2. 🗃 Importing the module\library.
    ```powershell
    # Importing as you would a standard powershell module, 
    Import-Module -Name "path\to\glvigor\"
    ```

# Cmdlets/Functions
>🦜 ***Note*** !
Cmdlets that have the `request-`, `register-`, `unregister-`, or `Update-` all required an authenticated object which in generated by the `Request-GitlabAuth` Cmdlet.


## 🧅***Request-GitlabAuth*** <kbd>🟢-api-get</kbd>
*🔻returns*:  `Void`

Performs a `GET` request to a specified GitLab API endpoint. It retrieves user data, and if the user is authenticated and has sufficient access rights, the `$global:_glvigor.auth` object is set.

♾-***Cmdlet & Alias***:

```powershell
Request-GitLabAuth [[-Hostname] <String>] 
                   [[-APIKey] <String>] 
------------------
glvauth [[-h] <String>] 
        [[-a] <String>] 
```

💡***Examples***:

```powershell
# Using environment variables: $ENV:GITLAB_HOST and $ENV:GITLAB_API_KEY
Request-GitLabAuth

# Using parameter values
Request-GitLabAuth -Hostname gitlab.mydomain.com -apikey klhf7asf7mlknhbalkjsf8a7sf
```
---

## 🧅***Search-Gitlab*** <kbd>🟢-api-get</kbd>
*🔻returns*:  `PSCustomObject`

Performs a `GET` REST request to a specified GitLab API endpoint, fetching resources filtered by `-type` and `-title`. 

♾-***Cmdlet & Alias***:

```powershell
Search-Gitlab [[-ti|-Title] <string>] 
              [[-ty|-Type] <string> {ValidateSet(project,issues,groups,merge_request,milestones,commit,blob,snippet_titles,users)]
              [[-g|-Group] <string>] 
              [[-n|-NameSpace] <string>]
              [[-r|-Raw] <switch>]
              [[-m|-match] <switch>]
---
glvsgl ...
```

💡***Examples***:

```powershell
# Search project 'glvigor'
Search-Gitlab -Type projects -Title 'glvigor' 

# Return projects base on an exact match for title and namespace
Search-Gitlab -Type projects -Title glviger -match -namespace powershell
```

---

## 🧅***Request-MirrorConfig*** <kbd>🟢-api-get</kbd>
*🔻returns*:  `PSCustomObject`

Retrieves mirror configuration for a project.

```powershell
Request-MirrorConfig [[-p|-ProjectID] <string>] [[-m|-MirrorID] <string>]
# Alias: glvrmc
```

## 🧅***Register-MirrorConfig*** <kbd>🟡-api-post</kbd>
Registers a new mirror for a project.
```powershell
Register-MirrorConfig -Endpoint 'github' -Namespace 'my-org' -ProjectName 'my-repo' -APIKey '...'
# Alias: glvrm
```

## 🧅***Update-MirrorConfig*** <kbd>🟣-api-update</kbd>
Updates an existing mirror configuration.
```powershell
Update-MirrorConfig -ProjectID 1 -MirrorID 1 -enabled $false
# Alias: glvumc
```

## 🧅***Unregister-MirrorConfig*** <kbd>🔴-api-delete</kbd>
Removes a mirror configuration.
```powershell
Unregister-MirrorConfig -ProjectID 1 -MirrorID 1
# Alias: glvum
```

---

## 🧅***Request-Issue*** <kbd>🟢-api-get</kbd>
Retrieves issues for a project.
```powershell
Request-Issue -ProjectID 1 -IssueID 2
# Alias: glvrqi
```

## 🧅***Register-Issue*** <kbd>🟡-api-post</kbd>
Creates a new issue.
```powershell
Register-Issue -ProjectID 1 -Title "Issue Title" -Description "Description"
# Alias: glvri
```

## 🧅***Update-Issue*** <kbd>🟣-api-update</kbd>
Updates an existing issue.
```powershell
Update-Issue -ProjectID 1 -IssueIID 1 -Title "New Title"
# Alias: glvui
```

## 🧅***Unregister-Issue*** <kbd>🔴-api-delete</kbd>
Deletes an issue.
```powershell
Unregister-Issue -ProjectID 1 -IssueIID 1
# Alias: glvui
```

---

## 🧅***Request-Project*** <kbd>🟢-api-get</kbd>
Retrieves project details.
```powershell
Request-Project -ProjectID 1
# Alias: glvrp
```

## 🧅***Register-Project*** <kbd>🟡-api-post</kbd>
Creates a new project.
```powershell
Register-Project -name "my-new-project"
# Alias: glvrp
```

## 🧅***Update-Project*** <kbd>🟣-api-update</kbd>
Updates project settings.
```powershell
Update-Project -ProjectID 1 -name "updated-name"
# Alias: glvup
```

## 🧅***Unregister-Project*** <kbd>🔴-api-delete</kbd>
Deletes a project.
```powershell
Unregister-Project -ProjectID 1
# Alias: glvurp
```

---

## 🧅***Request-Group*** <kbd>🟢-api-get</kbd>
Retrieves group details.
```powershell
Request-Group -GroupID 1
# Alias: glvrg
```

## 🧅***Register-Group*** <kbd>🟡-api-post</kbd>
Creates a new group.
```powershell
Register-Group -name "my-group" -path "my-group"
# Alias: glvrg
```

## 🧅***Update-Group*** <kbd>🟣-api-update</kbd>
Updates group settings.
```powershell
Update-Group -GroupID 1 -name "new-group-name"
# Alias: glvug
```

## 🧅***Unregister-Group*** <kbd>🔴-api-delete</kbd>
Deletes a group.
```powershell
Unregister-Group -GroupID 1
# Alias: glvurg
```

---

## 🧅***Request-Label*** <kbd>🟢-api-get</kbd>
Retrieves label details.
```powershell
Request-Label -ProjectID 1 -LabelID 1
# Alias: glvrl
```

## 🧅***Register-Label*** <kbd>🟡-api-post</kbd>
Creates a new label.
```powershell
Register-Label -ProjectID 1 -name "bug" -color "#ff0000"
# Alias: glvrl
```

## 🧅***Update-Label*** <kbd>🟣-api-update</kbd>
Updates a label.
```powershell
Update-Label -ProjectID 1 -LabelID 1 -name "feature"
# Alias: glvul
```

## 🧅***Unregister-Label*** <kbd>🔴-api-delete</kbd>
Deletes a label.
```powershell
Unregister-Label -ProjectID 1 -LabelID 1
# Alias: glvurl
```

---

## 🧅***Request-MergeRequest*** <kbd>🟢-api-get</kbd>
Retrieves merge requests.
```powershell
Request-MergeRequest -ProjectID 1 -MergeRequestIID 1
# Alias: glvrmr
```

## 🧅***Register-MergeRequest*** <kbd>🟡-api-post</kbd>
Creates a new merge request.
```powershell
Register-MergeRequest -ProjectID 1 -SourceBranch "feat" -TargetBranch "main" -Title "PR"
# Alias: glvrmr
```

## 🧅***Update-MergeRequest*** <kbd>🟣-api-update</kbd>
Updates a merge request.
```powershell
Update-MergeRequest -ProjectID 1 -MergeRequestIID 1 -Title "New PR Title"
# Alias: glvumr
```

## 🧅***Unregister-MergeRequest*** <kbd>🔴-api-delete</kbd>
Deletes a merge request.
```powershell
Unregister-MergeRequest -ProjectID 1 -MergeRequestIID 1
# Alias: glvumr
```

---

## 🧅***Request-Blob*** <kbd>🟢-api-get</kbd>
Retrieves a blob from a project.
```powershell
Request-Blob -ProjectID 1 -BlobSHA "..."
# Alias: glvrb
```

---

## 🧅***Request-License*** <kbd>🟢-api-get</kbd>
Fetches a license template.
```powershell
Request-License -Type "mit" -Author "John Doe" -SaveToFile
```

---

## 🧅***Register-GithubRepository*** <kbd>🟢-api-get</kbd>
Creates a new GitHub repository.
```powershell
Register-GithubRepository -name "my-repo" -description "..."
# Alias: glvrgr
```

## 🧅***Register-GiteaRepository*** <kbd>🟢-api-get</kbd>
Creates a new Gitea repository.
```powershell
Register-GiteaRepository -Name "my-repo" -Hostname "gitea.com" -Token "..."
# Alias: glvrgtr
```

---

## 🧅***Get-GitLog*** <kbd>🔷-git-cmd</kbd>
Gets the git log with filtering options.
```powershell
Get-GitLog -Branch "main"
# Alias: glvgl
```

## 🧅***Get-LocalRemoteConfig*** <kbd>🔷-git-cmd</kbd>
Parses git remotes and returns detailed object.
```powershell
Get-LocalRemoteConfig
# Alias: glvlrc
```

## 🧅***Get-LocalMirrors*** <kbd>🔷-git-cmd</kbd>
Lists all local git mirrors (non-origin remotes).
```powershell
Get-LocalMirrors
# Alias: glvlm
```

## 🧅***Add-LocalMirror*** <kbd>🔷-git-cmd</kbd>
Adds a new local git remote mirror.
```powershell
Add-LocalMirror -Endpoint 'github' -User 'user' -APIKey '...'
```

## 🧅***Remove-LocalMirror*** <kbd>🔷-git-cmd</kbd>
Removes a local git mirror.
```powershell
Remove-LocalMirror -Name 'mirror'
```

## 🧅***Get-GitOrigin*** <kbd>🔷-git-cmd</kbd>
Returns the origin remote details.
```powershell
Get-GitOrigin
# Alias: glvgo
```

## 🧅***Set-GitOrigin*** <kbd>🔷-git-cmd</kbd>
Configures the origin remote.
```powershell
Set-GitOrigin -Origin 'gitlab' -User 'user' -ApiKey '...'
# Alias: glvso
```

---

# UI & Customization

## 🎨 Color Palette
GLViger uses a centralized color palette defined in `$global:__glvigor.colorpallet`. This allows for consistent 256-color output across all cmdlets.

## 🌈 Gradients
The module includes `New-AsciiGradient` (alias `ascgrd`) for creating beautiful ANSI gradients in your terminal.

```powershell
New-AsciiGradient -Type fg -Steps @(196, 214, 226, 46) -String "GLViger Gradient"
```

---

## 📑 License

This project is © licensed under the [MIT License](LICENSE).
