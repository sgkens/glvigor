# PHGitLab — TUI Output Design Spec

Handoff document for implementation. Scope: rendering rules for `Write-PHGitLab*` /
`Format-PHGitLab*` output functions across the module's ~70-endpoint surface
(projects, namespaces/groups, mirrors, pipelines, merge requests, and adjacent
resources).

Assumption flagged for review: module namespace assumed as `PHGitLab`
(consistent with `PH.ErrorReporting`). Rename throughout if the real name differs.

---

## 1. Character Safety

### 1.1 The problem

Two failure classes break alignment in practice:

1. **Ambiguous-width glyphs.** Unicode assigns an East Asian Width property to
   every codepoint. Most box-drawing and symbol characters are `Narrow` or
   `Neutral` and render as 1 column everywhere. A subset — most checkmarks,
   circled symbols, and emoji-adjacent glyphs (`✓ ✔ ✗ ✖ ● ○ ★ ⚠`) — are
   `Ambiguous`. Ambiguous-width glyphs render as 1 column in some terminals/fonts
   and 2 columns in others (this is a real, documented split, not a rendering
   bug), which silently shifts every column to the right of them. This is
   almost certainly the class of char causing the alignment breaks you've hit.
2. **Host/redirection variance.** `Write-Host` in a real console behaves
   differently from output that's redirected to a file, piped, or rendered
   inside CI logs (Windows PowerShell 5.1 console host vs. pwsh 7 vs. VS Code
   integrated terminal vs. a non-interactive runner all differ). Anything
   relying on console width detection needs a non-interactive fallback.

### 1.2 Safe glyph tiers

**Tier 1 — Unicode box-drawing, single-line only (`U+2500`–`U+257F`).**
Default when the host is interactive and UTF-8. These are unambiguous-width
by spec and consistently 1 column in every monospace font your ecosystem
already standardizes on (IBM Plex Mono, JetBrains Mono).

```
┌ ┐ └ ┘ ─ │ ├ ┤ ┬ ┴ ┼
```

Do not mix in double-line (`═ ║ ╔`) or rounded (`╭ ╮`) variants in the same
render pass — mixing weight/style within one panel is the actual visual bug
users report as "misalignment" even when the widths are technically fine.

**Tier 2 — Pure ASCII fallback.** Used when output is redirected, when
`$Host.UI.SupportsVirtualTerminal` is false, or via an explicit `-Charset
Ascii` switch. Zero ambiguity, zero dependency on font coverage, greps
cleanly in CI logs.

```
+ - | ` '
```

**Never use (ambiguous width / inconsistent glyph coverage):**

```
✓ ✔ ✗ ✖ ● ○ ★ ☆ ⚠ 🔒 🔥 ➜ »   (and any emoji)
```

Replace all semantic checkmark/warning use with the bracket-tag system in
§4 instead — it's ASCII-safe by construction and carries more information
than a glyph would anyway.

### 1.3 Detection logic (for the agent to implement)

```powershell
function Get-PHGitLabCharset {
    param([string]$Override)

    if ($Override) { return $Override }

    $redirected = [Console]::IsOutputRedirected
    $vt = $Host.UI.SupportsVirtualTerminal
    $encodingOk = [Console]::OutputEncoding.CodePage -eq 65001

    if (-not $redirected -and $vt -and $encodingOk) { 'Unicode' } else { 'Ascii' }
}
```

Every rendering function should accept `-Charset Unicode|Ascii` and default
to the detected value, not force it.

---

## 2. Layout Grammar

Three primitives cover the whole endpoint surface: **panel** (single-resource
detail), **table** (list views), **tree** (namespace/subgroup hierarchy).
Progress/status is a decorator applied inside any of the three.

### 2.1 Panel — single resource, key/value

```
┌─ REPOSITORY ────────────────────────────────────────────────┐
│ ID           42                                              │
│ Name         drift-platform                                  │
│ Path         phellams/drift-platform                         │
│ Visibility   private                                         │
│ Default      redline                                         │
│ Updated      2026-08-01 14:22 UTC                             │
└────────────────────────────────────────────────────────────┘
```

ASCII fallback:

```
+- REPOSITORY -------------------------------------------------+
| ID           42                                              |
| Name         drift-platform                                  |
| Path         phellams/drift-platform                         |
| Visibility   private                                         |
| Default      redline                                         |
| Updated      2026-08-01 14:22 UTC                             |
+----------------------------------------------------------------+
```

Rules: label column fixed-width (left-padded to longest label + 2, min 12),
title sits in the top border, width is either the terminal width (interactive)
or a fixed 66 cols (non-interactive/log-safe default).

### 2.2 Table — list views

```
┌─ PIPELINES · phellams/drift-platform ─────────────────────────┐
├──────┬──────────┬────────────┬───────────┬────────────────────┤
│ ID   │ STATUS   │ REF        │ DURATION  │ TRIGGERED           │
├──────┼──────────┼────────────┼───────────┼────────────────────┤
│ 8841 │ [OK]     │ redline    │ 2m 14s    │ sgkens · 12m ago    │
│ 8840 │ [RUN]    │ redline    │ 0m 41s    │ sgkens · 15m ago    │
│ 8839 │ [ERR]    │ agent/wip  │ 0m 58s    │ ci-bot · 1h ago     │
│ 8838 │ [CXL]    │ redline    │ —         │ sgkens · 2h ago     │
└──────┴──────────┴────────────┴───────────┴────────────────────┘
```

ASCII fallback swaps `┌┬┐├┼┤└┴┘─│` → `+-+ + + + +|` per §1.2. Column widths
computed from content, not fixed — pad status tags to their max width (`[OK]`
= 4 chars, `[CXL]` = 5, so pad the whole column to 5).

### 2.3 Tree — namespace/subgroup hierarchy

```
phellams
├── drift-platform
├── ravenui
│   ├── ravenui-docs
│   └── ravenui-components
├── mystro
└── ph-modules
    ├── ph-errorreporting
    └── ph-writer
```

ASCII fallback:

```
phellams
|-- drift-platform
|-- ravenui
|   |-- ravenui-docs
|   `-- ravenui-components
|-- mystro
`-- ph-modules
    |-- ph-errorreporting
    `-- ph-writer
```

---

## 3. ASCII Logo

Original wordmark construction (not a reproduction of GitLab's tanuki mark —
deliberately staying clear of the trademarked icon). Diagonal-cut block
letterforms carry the "vigor" energy without needing color.

**Full banner (module load / `Get-PHGitLabInfo`):**

```
 ▄▄▄▄▄▄▄  ▄     ▄  ▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄  ▄▄▄▄▄▄     ▄▄▄▄▄  ▄▄▄▄▄▄▄
▐░░░░░░░▌▐░▌   ▐░▌▐░░░░░░░▌▐░░░░░░░▌▐░░░░░░▌   ▐░░░░░▌▐░░░░░░░▌
▐░▌      ▐░▌   ▐░▌ ▀▀▀▀█░█▀ ▐░▌      ▐░▌  ▐░▌ ▐░▌  ▐░▌▐░▌  ▀▀▀
▐░▌  ▄▄▄ ▐░▌   ▐░▌     ▐░▌  ▐░▌      ▐░▌   ▐░▌▐░▌   ▐░▌▐░▌
▐░░░░░░▌ ▐░░░░░░░▌     ▐░▌  ▐░░░░░░░▌▐░▌    ▐░▌░▌    ▐░▌▐░▌  ▄▄▄
 ▀▀▀▀░░▌  ▀▀▀▀▀▀▀      ▐░▌   ▀▀▀▀▀▀▀ ▐░▌     ▐░▌      ▐░▌▐░░░░░░░▌
      ▀▀                ▀                    ▀        ▀  ▀▀▀▀▀▀▀
                    < administer everything · everywhere >
```

Note: block-shading glyphs (`▄ ▐ ░ ▌`) are Tier-1-adjacent — width-safe but
**only** for the one-time banner, since they're heavier to render than plain
box-drawing. Don't use these in repeating table rows.

**Compact/status-line mark (prompt or module version string):**

```
[gl▸vigor]
```

**ASCII-fallback banner** (no block glyphs at all):

```
 _____ _  _____ _   _   ___    ___    _   _   _____ ___  ___
|  __ \ |_   _| | | | | | \ \  / / |  / \ | |_   _/ _ \| _ \
| |  \/  | | | | |_| | | |\ \/ /| | / _ \| | | || | | | |/
| | __   | | | |  _  | | | \  / | |/ ___ \| |_| || |_| | |\ \
|_|\_\   |_| |_|_| |_| |_|  \/  |_/_/   \_\_____/\___/|_| \_\
                  < administer everything, everywhere >
```

---

## 4. Status Tags (semantic glyph replacement)

Fixed-width bracket tags, ASCII-only, no charset branching needed — they're
safe in both tiers and grep cleanly:

| Tag      | Meaning                    | Width |
| -------- | -------------------------- | ----- |
| `[OK]`   | success / merged / active  | 4     |
| `[ERR]`  | failed                     | 5     |
| `[RUN]`  | running / in progress      | 5     |
| `[PND]`  | pending / created          | 5     |
| `[CXL]`  | canceled                   | 5     |
| `[SKP]`  | skipped                    | 5     |
| `[WARN]` | degraded / needs attention | 6     |
| `[LOCK]` | protected / locked branch  | 6     |

When a column mixes tags, pad the whole column to the widest tag in that
render pass (usually `[WARN]`/`[LOCK]` at 6), not per-row.

---

## 5. CRUD Examples

Each block shows the invoked command (input) and the resulting panel/table
(output). These are representative, not exhaustive — the same primitives
apply across the other ~65 endpoints once the agent implements §2.

### 5.1 Repository — Create, Read

```powershell
PS> New-PHGitLabProject -Name "hyprwin" -Namespace "phellams" -Visibility Private
```

```
┌─ REPOSITORY CREATED ────────────────────────────────────────┐
│ ID           118                                             │
│ Name         hyprwin                                         │
│ Path         phellams/hyprwin                                │
│ Visibility   private                                         │
│ Default      main                                             │
│ Web URL      gitlab.example.com/phellams/hyprwin              │
└────────────────────────────────────────────────────────────┘
```

```powershell
PS> Get-PHGitLabProject -Path "phellams/drift-platform"
```

```
┌─ REPOSITORY ────────────────────────────────────────────────┐
│ ID           42                                              │
│ Name         drift-platform                                  │
│ Path         phellams/drift-platform                         │
│ Visibility   private                                         │
│ Default      redline                                          │
│ Stars        0        Forks   0                               │
│ Updated      2026-08-01 14:22 UTC                             │
└────────────────────────────────────────────────────────────┘
```

### 5.2 Namespace / Group — Read, Update

```powershell
PS> Get-PHGitLabGroup -Path "phellams" -IncludeSubgroups
```

```
┌─ GROUP · phellams ──────────────────────────────────────────┐
│ ID           7                                               │
│ Visibility   private                                         │
│ Projects     6                                               │
└────────────────────────────────────────────────────────────┘
phellams
├── drift-platform
├── ravenui
├── mystro
├── ph-modules
├── hyprwin
└── colorkit
```

```powershell
PS> Set-PHGitLabGroup -Path "phellams" -Description "solo dev ecosystem" -Visibility Internal
```

```
┌─ GROUP UPDATED · phellams ──────────────────────────────────┐
│ Description  solo dev ecosystem                              │
│ Visibility   internal   (was: private)                       │
└────────────────────────────────────────────────────────────┘
```

### 5.3 Pipelines — Read (list), Create (trigger), Delete (cancel)

```powershell
PS> Get-PHGitLabPipeline -Project "phellams/drift-platform" -Latest 4
```

_(see §2.2 table example — same output)_

```powershell
PS> New-PHGitLabPipeline -Project "phellams/drift-platform" -Ref "redline"
```

```
┌─ PIPELINE TRIGGERED ────────────────────────────────────────┐
│ ID           8842                                            │
│ Status       [PND]                                           │
│ Ref          redline                                         │
│ SHA          9f2a1c4                                         │
└────────────────────────────────────────────────────────────┘
```

```powershell
PS> Remove-PHGitLabPipeline -Project "phellams/drift-platform" -Id 8840 -Cancel
```

```
┌─ PIPELINE CANCELED ─────────────────────────────────────────┐
│ ID           8840                                            │
│ Status       [CXL]   (was: [RUN])                            │
└────────────────────────────────────────────────────────────┘
```

### 5.4 Merge Requests — Create, Read, Update, Delete (close)

```powershell
PS> New-PHGitLabMergeRequest -Project "phellams/ravenui" -Source "agent/raven-brand" -Target "main" -Title "Raven brand kit v1"
```

```
┌─ MERGE REQUEST CREATED ─────────────────────────────────────┐
│ !ID          214                                             │
│ Title        Raven brand kit v1                              │
│ Status       [PND]                                           │
│ Source       agent/raven-brand → main                        │
└────────────────────────────────────────────────────────────┘
```

```powershell
PS> Get-PHGitLabMergeRequest -Project "phellams/ravenui" -State Opened
```

```
┌─ MERGE REQUESTS · phellams/ravenui ─────────────────────────┐
├──────┬────────────────────────┬──────────┬───────────────────┤
│ !ID  │ TITLE                  │ STATUS   │ SOURCE → TARGET    │
├──────┼────────────────────────┼──────────┼───────────────────┤
│ 214  │ Raven brand kit v1     │ [PND]    │ agent/raven-brand  │
│ 209  │ Fix breadcrumb V2 CSS  │ [WARN]   │ agent/breadcrumb   │
└──────┴────────────────────────┴──────────┴───────────────────┘
```

```powershell
PS> Set-PHGitLabMergeRequest -Project "phellams/ravenui" -Id 214 -Title "Raven brand kit v1 (final)"
```

```
┌─ MERGE REQUEST UPDATED · !214 ──────────────────────────────┐
│ Title        Raven brand kit v1 (final)   (was: v1)          │
└────────────────────────────────────────────────────────────┘
```

```powershell
PS> Close-PHGitLabMergeRequest -Project "phellams/ravenui" -Id 209
```

```
┌─ MERGE REQUEST CLOSED · !209 ───────────────────────────────┐
│ Status       [CXL]   (was: [WARN])                           │
└────────────────────────────────────────────────────────────┘
```

### 5.5 Remote Mirror — Create, Read, Delete

```powershell
PS> New-PHGitLabRemoteMirror -Project "phellams/drift-platform" -Url "git@backup-host:phellams/drift-platform.git"
```

```
┌─ REMOTE MIRROR CREATED ─────────────────────────────────────┐
│ ID           31                                              │
│ URL          git@backup-host:phellams/drift-platform.git     │
│ Direction    push                                            │
│ Enabled      true                                             │
└────────────────────────────────────────────────────────────┘
```

```powershell
PS> Get-PHGitLabRemoteMirror -Project "phellams/drift-platform"
```

```
┌─ REMOTE MIRRORS · phellams/drift-platform ──────────────────┐
├──────┬──────────────────────────────────┬──────────┬─────────┤
│ ID   │ URL                              │ ENABLED  │ LAST SYNC│
├──────┼──────────────────────────────────┼──────────┼─────────┤
│ 31   │ backup-host:.../drift-platform    │ true     │ [OK]    │
└──────┴──────────────────────────────────┴──────────┴─────────┘
```

```powershell
PS> Remove-PHGitLabRemoteMirror -Project "phellams/drift-platform" -Id 31
```

```
┌─ REMOTE MIRROR DELETED ─────────────────────────────────────┐
│ ID 31 removed from phellams/drift-platform                   │
└────────────────────────────────────────────────────────────┘
```

---

## 6. Implementation Notes for the Agent

Suggested function surface, matching the `Write-PHError` / `Set-PHErrorTheme`
naming pattern already established in `PH.ErrorReporting`:

- `Write-PHGitLabPanel -Title -Data -State [Created|Updated|Deleted|Default]`
  — renders §2.1, title-bar text switches per `-State`.
- `Write-PHGitLabTable -Title -Columns -Rows`
  — renders §2.2, auto column-width, status-tag-aware padding.
- `Write-PHGitLabTree -Root -Items`
  — renders §2.3.
- `ConvertTo-PHGitLabStatusTag -Value` — maps GitLab API status strings
  (`success`, `failed`, `running`, `created`, `canceled`, `skipped`) to the
  §4 tag table. Centralize this mapping once; every panel/table consumes it
  rather than re-implementing string matching per resource type.
- `Get-PHGitLabCharset` — §1.3 detection, `-Charset` override on every
  `Write-PHGitLab*` function threads through to this.

Recommend a single internal `$script:PHGitLabGlyphMap` hashtable keyed by
`Unicode`/`Ascii` holding the 11 box-drawing chars, so every render function
does glyph lookups instead of hardcoding either tier — this is the thing
most likely to drift out of sync if left implicit.

Width handling: compute panel/table width from `[Console]::WindowWidth` when
interactive, clamp to a 66-col floor and a 120-col ceiling; use the fixed
66-col default from §2.1 whenever `IsOutputRedirected` is true (CI logs,
`Out-File`, pipeline artifacts) so saved output stays readable regardless of
the terminal that produced it.
