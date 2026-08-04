# ==============================================================================
# File: references/gitlab-api-catalog.md
# ==============================================================================
# GitLab API Curation Catalog for GLVigor

> **Purpose**: Authoritative catalog of GitLab v4 API REST endpoints supported (and scheduled for support) by `glvigor`.

---

## 1. Projects & Repositories (`repo`)
| Endpoint | HTTP Method | GLVigor Function | Action / Mode | Status |
| :--- | :--- | :--- | :--- | :--- |
| `/projects` | GET | `Search-GitLab -Type project` | `glv -mode repo -action list` | Implemented |
| `/projects/:id` | GET | `Request-Project` | `glv -mode repo -action get` | Implemented |
| `/projects` | POST | `Register-Project` | `glv -mode repo -action create` | Implemented |
| `/projects/:id` | PUT | `Update-Project` | `glv -mode repo -action update` | Implemented |
| `/projects/:id` | DELETE | `Unregister-Project` | `glv -mode repo -action delete` | Implemented |
| `/projects/:id/remote_mirrors` | GET, POST, DELETE | `*-MirrorConfig` | `glv -mode repo` | Implemented |
| `/projects/:id/repository/branches` | GET, POST, DELETE | `*-Branch` | `glv -mode repo` | Planned |
| `/projects/:id/repository/commits` | GET | `Get-GitLog` | `glv -mode repo` | Implemented |

---

## 2. Issues & Tasks (`task`)
| Endpoint | HTTP Method | GLVigor Function | Action / Mode | Status |
| :--- | :--- | :--- | :--- | :--- |
| `/issues` | GET | `Search-GitLab -Type issue` | `glv -mode task -action list` | Implemented |
| `/projects/:id/issues/:issue_iid` | GET | `Request-Issue` | `glv -mode task -action get` | Implemented |
| `/projects/:id/issues` | POST | `Register-Issue` | `glv -mode task -action create` | Implemented |
| `/projects/:id/issues/:issue_iid` | PUT | `Update-Issue` | `glv -mode task -action update` | Implemented |
| `/projects/:id/issues/:issue_iid` | DELETE | `Unregister-Issue` | `glv -mode task -action delete` | Implemented |
| `/projects/:id/milestones` | GET, POST, PUT | `*-Milestone` | `glv -mode task` | Planned |

---

## 3. Merge Requests (`merge`)
| Endpoint | HTTP Method | GLVigor Function | Action / Mode | Status |
| :--- | :--- | :--- | :--- | :--- |
| `/merge_requests` | GET | `Search-GitLab -Type mergerequest` | `glv -mode merge -action list` | Implemented |
| `/projects/:id/merge_requests/:mr_iid` | GET | `Request-MergeRequest` | `glv -mode merge -action get` | Implemented |
| `/projects/:id/merge_requests` | POST | `Register-MergeRequest` | `glv -mode merge -action create` | Implemented |
| `/projects/:id/merge_requests/:mr_iid` | PUT | `Update-MergeRequest` | `glv -mode merge -action update` | Implemented |
| `/projects/:id/merge_requests/:mr_iid` | DELETE | `Unregister-MergeRequest` | `glv -mode merge -action delete` | Implemented |
| `/projects/:id/merge_requests/:mr_iid/merge` | PUT | `Approve-MergeRequest` | `glv -mode merge` | Planned |

---

## 4. Tags & Releases (`tags`)
| Endpoint | HTTP Method | GLVigor Function | Action / Mode | Status |
| :--- | :--- | :--- | :--- | :--- |
| `/projects/:id/repository/tags` | GET, POST, DELETE | `*-GitTag` | `glv -mode tags` | Planned |
| `/projects/:id/releases` | GET, POST, PUT, DELETE | `*-GitLabRelease` | `glv -mode tags` | Planned |

---

## 5. Generic Packages & Registries (`package`)
| Endpoint | HTTP Method | GLVigor Function | Action / Mode | Status |
| :--- | :--- | :--- | :--- | :--- |
| `/projects/:id/packages` | GET, DELETE | `*-GitLabPackage` | `glv -mode package` | Planned |
| `/projects/:id/packages/generic/:name/:version/:file` | PUT (Upload), GET (Download) | `Publish-GenericPackage` | `glv -mode package` | Planned |

---

## 6. Groups & Labels (`group`, `label`)
| Endpoint | HTTP Method | GLVigor Function | Action / Mode | Status |
| :--- | :--- | :--- | :--- | :--- |
| `/groups` | GET, POST, PUT, DELETE | `*-Group` | Cmdlet Available | Implemented |
| `/projects/:id/labels` | GET, POST, PUT, DELETE | `*-Label` | Cmdlet Available | Implemented |

---

## 7. User Authentication & License (`auth`)
| Endpoint | HTTP Method | GLVigor Function | Action / Mode | Status |
| :--- | :--- | :--- | :--- | :--- |
| `/personal_access_tokens/self` / `/user` | GET | `Request-GitLabAuth` | `glv -mode auth` | Implemented |
| `/license` | GET | `Request-License` | Cmdlet Available | Implemented |
