---
layout: default
title: TUI Architecture & Master Router Concepts
permalink: /concepts/tui-architecture/
---

# TUI Architecture & Master Router Concepts

GLVigor implements an Alt-Buffer terminal UI architecture for PowerShell console environments. It separates REST API calls from presentation and provides keyboard navigation, ANSI color gradients, box rendering, and form input controls.

---

## Architecture Topology

<div class="mermaid">
graph TD
    User["CLI User / Terminal"] --> Router["Invoke-GLVigor (glv)"]
    Router --> UHRouter["uhwriter Engine (New-UHRouter)"]

    UHRouter --> TUIDash["Start-GLVTui (Alt-Buffer Dashboard)"]
    UHRouter --> FormCard["Invoke-GLVFormCard (-it Interactive Cards)"]
    UHRouter --> RestCmdlets["Public REST Cmdlets (Request-Project, etc.)"]

    FormCard --> RestCmdlets
    RestCmdlets --> ScopeFilter["Get-GLVNamespaceFilter (-Global Scoping)"]
    ScopeFilter --> OutputRenderer["Write-GLVTable / Write-GLVPanel"]
</div>

---

## Key TUI Architectural Concepts

### 1. Alt-Buffer & Cursor Management
To prevent console output corruption and eliminate screen flicker, GLVigor enters the terminal Alt-Screen buffer (`\x1b[?1049h`) and hides the cursor (`\x1b[?25l`) during TUI execution. Instead of invoking `[Console]::Clear()`, line updates reposition the cursor to `(0,0)` via `[Console]::SetCursorPosition(0,0)`.

### 2. Pre-calculated Padding Rule
Applying ANSI escape sequences before calculating string width results in misaligned borders due to invisible escape characters. GLVigor calculates all string padding and layout alignment *before* wrapping strings in ANSI SGR escape sequences.

### 3. Interactive Form Cards (`-it`)
When passing the `-it` or `-Interactive` flag to `glv <mode> create` or `glv <mode> update <id>`, GLVigor launches an interactive Form Card (`Invoke-GLVFormCard`):
- Supports field pre-population for update operations.
- Keyboard navigation (<kbd>Tab</kbd>, <kbd>Up</kbd>/<kbd>Down</kbd>, <kbd>Backspace</kbd>).
- Single keypress submission (<kbd>Enter</kbd>) or cancellation (<kbd>Esc</kbd>).
- Automatic non-interactive fallback (`Read-Host`) when console output/input redirection is detected.

### 4. Router Namespace & Parameter Forwarding
The master router (`Invoke-GLVigor`) parses remaining CLI arguments into a parameter dictionary namespace (`$boundParams`). This allows parameters like `-Type`, `-Title`, `-Global`, and `-User` to pass dynamically to underlying cmdlets.
