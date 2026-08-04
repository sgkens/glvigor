# Gitlab Vigor (`glvigor`) - Development Tracker & Master Roadmap

> **Role & Architecture**: System automation & PowerShell module standard based on `phellams-aa`.
> **Goal**: Refactor `glvigor` into a zero-touch, high-performance, full-featured GitLab CLI & TUI toolkit.

---

## 📋 Task & Architecture Backlog

### Phase 1: Architecture Refactoring & Module Clean-up
- [x] **1.1 Directory & Loader Reorganization**
  - Refactor `glvigor.psm1` to use clean Public/Private helper structure.
  - Integrate new generic helpers from `helpers/` (`New-AsciiColor`, `New-AsciiGradient`, `New-ColorConsole`, `New-Spinner`, `New-TrailingLog`, `ui/`, etc.).
  - Transition from `libs/` dependencies to native dot-sourced `/Public` and `/Private` structure adhering strictly to `phellams-aa` specifications.
  - Implement `$ErrorActionPreference = 'Stop'` and `Set-StrictMode -Version Latest` compatibility across all functions.

- [x] **1.2 Master Router (`Invoke-GLVigor` / `glv`)**
  - Create `Invoke-GLVigor.ps1` with alias `glv`.
  - Support mode-based execution (`glv -mode repo`, `glv -mode task`, `glv -mode merge`, `glv -mode tags`, `glv -mode package`, `glv -mode tui`).
  - Provide parameter auto-completion and seamless dynamic command dispatching.

---

### Phase 2: High-Performance TUI & Visual Logging Engine
- [x] **2.1 Clean & Elegant Console Logging**
  - Replace busy console log icons and verbose strings with a streamlined, high-density, visually clean logging framework (`Write-GLVLog`).
  - Pre-calculate lengths prior to applying ANSI/ASCII escape codes (applying the strict **Padding Rule** to prevent terminal tearing).
  - Add log level toggles (`-Quiet`, `-Verbose`, `-Debug`, `-Json`).

- [x] **2.2 Advanced TUI Rendering Engine**
  - Implement full RGB colors with standard 16/256 ANSI fallbacks.
  - Smooth SGR Gradients (`New-AsciiGradient`) for titles, banners, and progress bars.
  - Configurable UI component borders (`TopLeftBracket`, `HorizontalBorder`, customizable box drawing characters).
  - Tear-free full-screen Alt-Buffer TUI renderer (`[Console]::SetBufferSize`, ANSI Alt-Screen `\x1b[?1049h`).

---

### Phase 3: Interactive Full-Screen Alt-Buffer TUI Dashboards & CRUD Modules
- [x] **3.1 Repository CRUD (`repo-crud`)**
  - Interactive management of GitLab projects (`Request-Project`, `Register-Project`, `Update-Project`, `Unregister-Project`, `*-MirrorConfig`).
- [x] **3.2 Task & Issue CRUD (`task-crud`)**
  - Issue management, status transitions, weight, assignments, and board viewing in TUI (`Request-Issue`, `Register-Issue`, `Update-Issue`, `Unregister-Issue`).
- [x] **3.3 Merge Request CRUD (`merge-crud`)**
  - Review, approve, create, and merge MRs with inline diff summary viewer (`Request-MergeRequest`, `Register-MergeRequest`, `Update-MergeRequest`, `Unregister-MergeRequest`).
- [x] **3.4 Tag & Release CRUD (`tags-crud`)**
  - Tag creation, semver auto-tagging, release note generation, and release assets management (`Request-GitTag`, `Register-GitTag`).
- [x] **3.5 Package & Artifact Manager (`package-crud`)**
  - Generic package registry integration: uploading, downloading, metadata inspection, and package deletion (`Publish-GenericPackage`).

---

### Phase 4: Comprehensive GitLab API Curation & Coverage Matrix
- [x] **4.1 Curate GitLab API Endpoint Catalog**
  - Established authoritative endpoint mapping in `references/gitlab-api-catalog.md`.
  - **Projects & Groups**: Repositories, Branches, Commits, Deploy Keys, Webhooks, Group Memberships.
  - **Issues & Work Items**: Tasks, Epics, Iterations, Milestones, Custom Fields.
  - **Merge Requests & Code Review**: Discussions, Approvals, Commits, Pipelines status per MR.
  - **CI/CD & Pipelines**: Pipeline triggers, Job logs, Artifact downloads, Environment status.
  - **Package & Container Registry**: Generic Packages, NPM/NuGet/PyPI Registries, Container Images.
  - **User & Auth**: Token management, SSH key management, User profile details.

---

### Phase 5: Help & Documentation Engine (`uhwriter`)
- [x] **5.1 Cross-Platform Help Integration (`helpers/uhwriter`)**
  - Integrated forked `uhwriter` module loader in `glvigor.psm1`.
  - Defined `$global:GLVTheme` properties for centralized module colors and styling.
  - Implemented `Get-GLVHelp` (`glvhelp`) with dynamic command catalog browsing (`glv -mode help`).
- [x] **5.2 Subcommand Dispatcher Refactoring (`New-UHRouter`)**
  - Refactored `Invoke-GLVigor` (`glv`) to use `New-UHRouter` (`uhroute`) engine from `uhwriter`.
  - Enabled auto-registered tab completions, native argument dispatching, and Levenshtein distance "Did you mean?" fuzzy matching.

---

### Phase 6: Code Quality, Security, QoL & Assurability Audit Improvements
- [x] **6.1 Security & Token Protection**
  - [x] **Secure PAT Storage**: Encapsulate API keys in `[SecureString]` inside `$global:_glvigor.auth` memory state instead of plain string storage.
  - [x] **Sanitize Log Credentials**: Audited `Write-GLVLog` and `Invoke-RestMethod` debug outputs to guarantee access tokens and Authorization headers are never leaked to logs or console streams.
  - [x] **HTTPS Enforcement**: Enforce HTTPS protocol resolution in `Request-GitLabAuth`.

- [x] **6.2 Quality of Life (QoL) Enhancements**
  - [x] **Local Project Context Auto-Discovery**: Created `Get-GitContext` to automatically detect target GitLab `ProjectID`/Path from local `.git/config` remotes when `-ProjectID` is omitted.
  - [x] **Formatted Output Pipelines**: Standardized REST API returns to clean projections with `-Raw` fallback switch.
  - [x] **Unified Error Handling**: Wrapped REST failures in standardized exception handlers with clear HTTP status codes.

- [x] **6.3 Code Quality & Assurability Assurance**
  - [x] **Pester Unit & Integration Test Suite**: Implemented Pester v5 tests in `/test` (`glvigor.Tests.ps1`) covering module exports and auth security.
  - [x] **PHWriter / Comment-Based Help Audit**: Verified comment-based help coverage (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`) across public functions in `/public`.
  - [x] **GitLab CI/CD Automated Pipeline**: Verified `.gitlab-ci.yml` pipeline integration.

---

### Phase 7: Pipeline Flowgraph Visualization & Live Monitoring
- [x] **7.1 Flowgraph ASCII Engine Integration (`helpers/flowgraph`)**
  - Integrated `flowgraph` engine into `glvigor.psm1` with `clap.ps1` ANSI padding compatibility.
  - Implemented `Get-GLVPipeline` (`glvpipe`) supporting `-Local` parsing of `.gitlab-ci.yml` stage flowgraphs.
  - Added `-Live` switch to `Get-GLVPipeline` for continuous, looped live-status terminal rendering.
  - Added `pipeline` mode to `Invoke-GLVigor` (`glv pipeline -Local`, `glv pipeline -Live`).

---

### Phase 8: Master Router TUI Output Engine, Interactive Form Cards & Native Help Refactoring
- [x] **8.1 Clean Public Cmdlets vs. Master Router (`glv`) TUI Output Engine**
  - Preserved clean PowerShell object / `-Raw` REST outputs for public cmdlets (`Request-Project`, `Approve-MergeRequest`, etc.).
  - Upgraded `Invoke-GLVigor` (`glv`) to intercept raw cmdlet returns and render structured panels (`Write-GLVPanel`), tables (`Write-GLVTable`), and trees based on `context-source/glv-router-function-tui.md`.
  - Enforced strict `phellams-aa` character safety (Tier-1 Unicode box-drawing / Tier-2 ASCII fallback, no width-ambiguous emojis, fixed-width status tags: `[OK]`, `[RUN]`, `[ERR]`, `[PND]`, `[CXL]`, `[WARN]`, `[LOCK]`).
  - Applied `fluent-ui-v1` design principles (full RGB color engine with 256/16 ANSI fallbacks, subtle Orange `#FF8800` -> Blue `#0088FF` gradient borders, offset title gradients).

- [x] **8.2 Interactive Creation & Update Form Cards (`-it` / `-Interactive`)**
  - Implemented `Invoke-GLVFormCard` in Alt-Buffer TUI supporting all 'CU' (Create & Update) actions (`glv <mode> create -it` and `glv <mode> update <id> -it`).
  - Pre-populates field data in Update mode, supports keyboard navigation (<kbd>Tab</kbd>/<kbd>Down</kbd>/<kbd>Up</kbd>), live input preview, and single-keypress submit/cancel.

- [x] **8.3 Native `uhwriter` Help Router & Metadata Cleanup**
  - Refactored `Get-GLVHelp` and `glv help` / `glv <mode> help` / `glv search help` to interface directly with `Show-UHCommandCatalog -Module 'glvigor'` and `Invoke-UHPager`.
  - Stripped redundant AST header metadata (`[Source: ...]`, file paths) using `-Layout Minimal` for clean, professional help screens.

---

## 🛠 Progress Log & Status Updates
- **2026-07-30**: Completed Phase 1 - 5 roadmap. Conducted audit for security, friction points, QoL, and test assurance; populated Phase 6 backlog tasks in `devtracker-pending.md`.
- **2026-08-04**: Added Phase 8 roadmap for Master Router TUI output engine, interactive creation/update form cards (`-it`), and native `uhwriter` help router integration. Completed Phase 8 implementation and verified with Pester test suite.
