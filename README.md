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
         - ***Create*** [*🧅 Search-Gitlab*](#🧅Request-GitlabAuth-🟢-api-get)
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
  - ✔ ***Create/Edit/Get/Delete*** groups.
      - ✔ View groups(**search**) - `Search-Gitlab -Type groups -Title 'Name'`
      - ✔ View group(**search**) - `Search-Gitlab -Type groups -Title 'Name' -match`
      - ✔ View group
      - ✔ Create group
      - ✔ Delete group
      - ✔ Update group - ✔ ***Create/Edit/Get/Delete*** labels.
     - ✔ View labels(**search**) - `Search-Gitlab -Type label -Title 'Name'`
     - ✔ View label(**search**) - `Search-Gitlab -Type label -Title 'Name' -match`
     - ✔ View label
     - ✔ Create label
     - ✔ Delete label
     - ✔ Update label
 - ✔ ***Create/Edit/Get/Delete*** merge_requests.
     - ✔ View merge_requests(**search**) - `Search-Gitlab -Type merge_requests -Title 'Name'`
     - ✔ View merge_request(**search**) - `Search-Gitlab -Type merge_requests -Title 'Name' -match`
     - ✔ View merge_request
     - ✔ Create merge_request
     - ✔ Delete merge_request
     - ✔ Update merge_request
 - ✔ ***Get*** blobs.


## 🔵 ***Git CMD***
 - ✔ ***Get/update*** git origin, returns non-mirrored origin as a `pscustomobject`
 - ✔ ***Create/Get/Delete/update*** local remote mirrors, supported endpoints: *`github`*, *`gitlab`*, *`gitea`*, *`gitlalen SE(CE|EE)`*.
 - ✔ ***Get*** gitlog filter based on `branch`, `commit-id`, `commit-id-short`, `commit-title`

## 🧅***Get-GitLog*** <kbd>🔷-git-cmd</kbd>
*🔻returns*:  `PSCustomObject`

Gets the git log with filtering options.

- Use `-Branch` to filter the log by branch.
- Use `-CommitID` to filter by full commit ID.
- Use `-CommitIDShort` to filter by short commit ID.
- Use `-CommitTitle` to filter by commit title.

♾-***Cmdlet & Alias***:

```powershell
Get-GitLog [[-b|-Branch] <string>]
           [[-c|-CommitID] <string>]
           [[-cs|-CommitIDShort] <string>]
           [[-ct|-CommitTitle] <string>]
------------
glvgl [[-b|-Branch] <string>]
      [[-c|-CommitID] <string>]
      [[-cs|-CommitIDShort] <string>]
      [[-ct|-CommitTitle] <string>]
```

💡***Examples***:

```powershell
# Get log for a specific branch
Get-GitLog -Branch "main"

# Get log for a specific commit ID
Get-GitLog -CommitID "a1b2c3d4e5f67890a1b2c3d4e5f67890a1b2c3d4"
```

---
## ⚡Type Accelerators or Aliases
|🔹═Function Cmdlet|⚡═Accelerator Alias|
|-|-|
|♾|⚡|

# Install module

📦 Installing from Package Repositories or `.nupkg` files see [***Releases***](https://)

🛖 Installing from git repository:

1. 📥 Cone Repository.
    ```bash
    git clone https://gitlab.com/glvigor/glvigor.git
    ``` 
2. 🗃 Importing the module\library.
    ```powershell
    # class methods and type Accelerators(cmdlets/functions)
     using module path\to\coforge\lib\glvigor.psm1` 

    # or

    # Importing as you would a standard powershell module, 
    Import-Module -Name "path\to\glvigor\"
    ```

# Cmdlets/Functions
>🦜 ***Note*** !
Cmdlets that have the `request-`, `register-`, `unregister-`, or `Update-` all required an authenticated object which in generated by the `Request-GitlabAuth` Cmdlet.


## 🧅***Request-GitlabAuth*** <kbd>🟢-api-get</kbd>
*🔻returns*:  `Void`

Performs a `GET` request to a specified GitLab API endpoint. It retrieves user data, and if the user is authenticated and has sufficient access rights, the `$global:_glvigor.auth` object is set. This object can be used by other API cmdlets (functions) to manage further interactions.

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
# or via alias
glvauth

# Using parameter values
Request-GitLabAuth -Hostname gitlab.mydomain.com -apikey klhf7asf7mlknhbalkjsf8a7sf
# alias
glvauth -h gitlab.mydomain.com -a klhf7asf7mlknhbalkjsf8a7sf
```
---

## 🧅***Search-Gitlab*** <kbd>🟢-api-get</kbd>
*🔻returns*:  `PSCustomObject`

Performs a `GET` REST request to a specified GitLab API endpoint, fetching resources filtered by `-type` and `-title`. The result is returned as a `pscustomobject`. Use `-raw` to output the unfiltered object. To further refine the results, the `-namespace` parameter can be used to filter by the GitLab group name. For an exact match, combine `-title` and `-namespace` with the `-match` parameter.

♾-***Cmdlet & Alias***:

```powershell
Search-Gitlab [[-ti|-Title] <string>] 
              [[-ty|-Type] <string> {ValidateSet(project,issues,groups,merge_request,milestones,commit,blob,snippet_titles,users)]
              [[-g|-Group] <string>] 
              [[-n|-NameSpace] <string>]
              [[-r|-Raw] <switch>]
              [[-m|-match] <switch>]
---

glvsgl [[-ti|-Title] <string>] 
       [[-ty|-Type] <string> {ValidateSet(project,issues,groups,merge_request,milestones,commit,blob,snippet_titles,users)]
       [[-g|-Group] <string>] 
       [[-n|-NameSpace] <string>]
       [[-r|-Raw] <switch>]
       [[-m|-match] <switch>]
```

>🦜 ***Note*** ! ***Types*** control the *Search Scope* valid types are: **projects**, **issues**, **merge_requests**, **milestones**, **snippet_titles**, **users**, **blobs**, **commits**, **notes**, and **groups**.

💡***Examples***:
> CMDLETS and ALIASES

```powershell
# Search project 'glvigor'
Search-Gitlab -Type projects -Title 'glvigor' 
glvsgl -ty projects -ti 'glvigor' 

---

# Search project 'glvigor' returns unfiltered PSObject
Search-Gitlab -Type projects -Title 'glvigor' -raw
glvsgl -ty projects -ti 'glvigor' -r

---

# Search issues by title
Search-Gitlab -Type issues -title ''
glvsgl -ty issues -ti ''

---

# Return projects base on an exact match for title and namespace
Search-Gitlab -Type projects -Title glviger -match -namespace powershell
glvsgl -ty projects -ti glviger -n powershell -m

---

# Return all merge requests with -title in the web_url location, unfilter pscustomobject
Search-Gitlab -Type merge_request -title glviger -match -raw
glvsgl -ty merge_request -ti glviger -m -r
```

> 💭 Access to resources may vary depending on user access level.

---

## 🧅***Request-MirrorConfig*** <kbd>🟢-api-get</kbd>
*🔻returns*:  `PSCustomObject`

Performs a `GET` REST request to the specified GitLab API endpoint to retrieve mirror configuration based on the project ID.

- Use `-ProjectID` to return all mirrors for a project.
- Use `-ProjectID` and `-MirrorID` to return a specific mirror.

Additionally, `Request-MirrorConfig` can accept piped input from `Search-Gitlab` when used with the `-match` parameter.

♾-***Cmdlet & Alias***:

```powershell
Request-MirrorConfig [[-d|-Data] <pscustomobject>]  
                     [[-p|-ProjectID] <string>] 
                     [[-m|-MirrorID] <string>] 
------------
glvrmc [[-d|-Data] <pscustomobject>]  
       [[-p|-ProjectID] <string>] 
       [[-m|-MirrorID] <string>] 
```

💡***Examples***:

```powershell
# Retrives the specific mirror if available
Request-mirrorConfig -ProjectID 191 -MirrorID 25

# via pipe

# all mirrors
Search-Gitlab -Type projects -title glvigor -match | Request-mirrorConfig

# Specific mirror
Search-Gitlab -Type projects -title glvigor -match | Request-mirrorConfig -MirrorID 12

# or Request Project
Request-Project -ID 12 | Request-mirrorConfig
```

---
## 🧅***Register-MirrorConfig*** <kbd>🟡-api-post</kbd>

## 🧅***Update-MirrorConfig*** <kbd>🟣-api-update</kbd>
## 🧅***Unregister-MirrorConfig*** <kbd>🔴-api-delete</kbd>

## 🧅***Request-Issue*** <kbd>🟢-api-get</kbd>
## 🧅***Register-Issue*** <kbd>🟡-api-post</kbd>
## 🧅***Update-Issue*** <kbd>🟣-api-update</kbd>
## 🧅***Unregister-Issue*** <kbd>🔴-api-delete</kbd>

## 🧅***Request-Project*** <kbd>🟢-api-get</kbd>
## 🧅***Register-Project*** <kbd>🟡-api-post</kbd>
## 🧅***Update-Project*** <kbd>🟣-api-update</kbd>
## 🧅***Unregister-Project*** <kbd>🔴-api-delete</kbd>

## 🧅***Request-MergeRequest*** <kbd>🟢-api-get</kbd>
## 🧅***Register-MergeRequest*** <kbd>🟡-api-post</kbd>
## 🧅***Update-MergeRequest*** <kbd>🟣-api-update</kbd>
## 🧅***Unregister-MergeRQ*** <kbd>🔴-api-delete</kbd>

## 🧅***Request-Label*** <kbd>🟢-api-get</kbd>
## 🧅***Register-Label*** <kbd>🟡-api-post</kbd>
## 🧅***Update-Label*** <kbd>🟣-api-update</kbd>
## 🧅***Unregister-Label*** <kbd>🔴-api-delete</kbd>

## 🧅***Request-Group*** <kbd>🟢-api-get</kbd>
## 🧅***Register-Group*** <kbd>🟡-api-post</kbd>
## 🧅***Update-Group*** <kbd>🟣-api-update</kbd>
## 🧅***Unregister-Group*** <kbd>🔴-api-delete</kbd>

## 🧅***Request-Blob*** <kbd>🟢-api-get</kbd>
*🔻returns*:  `PSCustomObject`

Performs a `GET` REST request to the specified GitLab API endpoint to retrieve a blob.

- Use `-ProjectID` and `-BlobSHA` to return a specific blob.

♾-***Cmdlet & Alias***:

```powershell
Request-Blob [[-p|-ProjectID] <int>]
             [[-b|-BlobSHA] <string>]
------------
glvrb [[-p|-ProjectID] <int>]
      [[-b|-BlobSHA] <string>]
```

💡***Examples***:

```powershell
# Retrieve a specific blob
Request-Blob -ProjectID 1 -BlobSHA "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391"
```

---
## 🧅***Request-License*** <kbd>🟢-api-get</kbd>
*🔻returns*:  `PSCustomObject`

Performs a `GET` REST request to the specified GitLab API endpoint to retrieve a license.

- Use `-Type` to return a specific license.
- Use `-Author` to specify the author's name for the license.
- Use `-SaveToFile` to save the license to a file named `LICENSE` in the current directory.

```powershell
Request-License -Type "mit" -Author "John Doe" -SaveToFile
```

---
## 🧅***Register-GithubRepository*** <kbd>🟢-api-get</kbd>
*🔻returns*:  `PSCustomObject`

Creates a new GitHub repository via the GitHub API.

- Use `-name` to specify the name of the repository to create.
- Use `-apikey` to provide the GitHub personal access token for authentication.

```powershell
Register-GithubRepository -name "my-repo" -user "username" -description "My new repo"
```

---
## 🧅***Register-GiteaRepository*** <kbd>🟢-api-get</kbd>
*🔻returns*:  `PSCustomObject`

Creates a new Gitea repository via the Gitea API with configurable settings.

- Use `-Name` to specify the name of the repository to create.
- Use `-Token` to provide the Gitea personal access token for authentication.
- Use `-Hostname` to specify the Gitea server hostname.

```powershell
Register-GiteaRepository -Name "my-repo" -User "username" -Hostname "gitea.example.com" -Token "token123" -Description "My new repo"
```

---
## 🧅***Get-LocalRemoteConfig*** <kbd>🔷-git-cmd</kbd>
## 🧅***Add-LocalMirror*** <kbd>🔷-git-cmd</kbd>
*🔻returns*:  `Void`

Sets the local mirror configuration for a repository, supporting both parameters and environment variables.

- Use `-Endpoint` to specify the destination instance.
- Use `-User` to specify the username or group name of the project to mirror.
- Use `-APIKey` to provide the API key for the destination instance.

```powershell
Add-LocalMirror -Endpoint 'gitlab' -User 'user' -APIKey 'key'
```

---
## 🧅***Get-LocalMirrors*** <kbd>🔷-git-cmd</kbd>
## 🧅***Set-LocalMirror*** <kbd>🔷-git-cmd</kbd>
## 🧅***Get-GitOrigin*** <kbd>🔷-git-cmd</kbd>
## 🧅***Remove-LocalMirror*** <kbd>🔷-git-cmd</kbd>
*🔻returns*:  `Void`

Removes a local git mirror

- Use `-Name` to specify the name of the mirror to remove.

```powershell
Remove-LocalMirror -Name 'mirror'
```

---
## 🧅***Get-GitOrigin*** <kbd>🔷-git-cmd</kbd>
*🔻returns*:  `PSCustomObject`

Calls Get-LocalRemoteConfig and parses git origin and returns filtered pscustomobject

```powershell
Get-GitOrigin
```

---
## 🧅***Set-GitOrigin*** <kbd>🔷-git-cmd</kbd>
---
# Build

# Package Repositories

# Releases

## 📑 License

This project is © licensed under the [MIT License](LICENSE).
