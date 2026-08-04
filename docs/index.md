---
title: GLVigor PowerShell documentation
description: Install GLVigor, authenticate with GitLab, use the glv command router, and compose raw API objects through PowerShell pipelines.
permalink: /
---

<section class="hero">
  <span class="eyebrow">PowerShell 7.4 · GitLab API v4</span>
  <h1>GitLab operations from one PowerShell command surface.</h1>
  <p>GLVigor routes project, issue, merge request, pipeline, mirror, and repository-provider operations through <code>glv</code>, direct cmdlets, or an interactive terminal interface.</p>
  <div class="ui-cluster">
    <a class="ui-button ui-button--primary" href="{{ '/getting-started/' | relative_url }}">Install and authenticate</a>
    <a class="ui-button" href="{{ '/cmdlets/' | relative_url }}">Browse commands</a>
  </div>
</section>

<div class="metric-grid" aria-label="Module capabilities">
  <div class="metric"><strong>GitLab</strong><span>Projects, issues, merge requests, branches, tags, groups, labels, pipelines, and packages</span></div>
  <div class="metric"><strong>5 providers</strong><span>GitHub, Gitea, Forgejo, Codeberg, and Cogs repository operations</span></div>
  <div class="metric"><strong>2 outputs</strong><span>Terminal rendering for operators and raw objects for PowerShell pipelines</span></div>
</div>

## Start with the router

The `glv` alias points to `Invoke-GLVigor`. Positional values select a domain, an action, and an optional target. Additional named arguments are forwarded to the selected command.

<div class="pane">
  <div class="pane-bar">
    <span class="dots" aria-hidden="true"><span></span><span></span><span></span></span>
    <span class="pane-title">PowerShell 7.4</span>
    <button class="pane-action" type="button" data-copy-code><span data-copy-label>Copy</span></button>
  </div>
  <div class="pane-body">
<pre><code><span class="tok-com"># Authenticate from GITLAB_HOST and GITLAB_API_KEY</span>
<span class="terminal-prompt">PS&gt;</span> glv auth

<span class="tok-com"># Review cached owner-space activity and assigned work</span>
<span class="terminal-prompt">PS&gt;</span> glv status

<span class="tok-com"># Render owned projects as a terminal table</span>
<span class="terminal-prompt">PS&gt;</span> glv repo list

<span class="tok-com"># Return API objects for the PowerShell pipeline</span>
<span class="terminal-prompt">PS&gt;</span> glv search <span class="tok-str">'old issue title'</span> -Type issues -Raw |
&gt;&gt; glv task update -Title <span class="tok-str">'Updated issue title'</span>

<span class="tok-com"># Open the interactive terminal interface</span>
<span class="terminal-prompt">PS&gt;</span> glv tui</code></pre>
  </div>
</div>

<div class="callout info">
  <div class="callout-bar">Pipeline contract</div>
  <div class="callout-body"><p>Use <code>-Raw</code> when a downstream command requires properties omitted from a filtered display object. Without <code>-Raw</code>, <code>glv</code> preserves the human-facing table or panel renderer.</p></div>
</div>

## Choose an interface

<div class="feature-grid">
  <article class="ui-card">
    <span class="eyebrow">Router</span>
    <h3><code>glv</code></h3>
    <p>Use domain and action syntax for terminal workflows, interactive forms, and pipeline composition.</p>
    <a href="{{ '/cmdlets/invoke-glvigor/' | relative_url }}">Router reference</a>
  </article>
  <article class="ui-card">
    <span class="eyebrow">PowerShell</span>
    <h3>Direct cmdlets</h3>
    <p>Call exported functions directly when scripts require explicit parameters and standard command discovery.</p>
    <a href="{{ '/cmdlets/' | relative_url }}">Command catalog</a>
  </article>
  <article class="ui-card">
    <span class="eyebrow">Terminal</span>
    <h3>Owner-space status</h3>
    <p>Review cached repository activity, owned namespaces, issue totals, and assigned tasks from one detailed TUI.</p>
    <a href="{{ '/concepts/status-dashboard/' | relative_url }}">Status dashboard</a>
  </article>
</div>

## Route domains

<div class="route-grid">
  <article class="ui-card"><h3>GitLab resources</h3><p><code>repo</code>, <code>task</code>, <code>merge</code>, <code>branch</code>, <code>tag</code>, <code>group</code>, and <code>label</code>.</p></article>
  <article class="ui-card"><h3>Delivery</h3><p><code>pipeline</code>, <code>package</code>, <code>mirror</code>, and local <code>git</code> routes.</p></article>
  <article class="ui-card"><h3>Repository providers</h3><p><code>github</code> and <code>gitea</code> router routes plus direct Forgejo, Codeberg, and Cogs cmdlets.</p></article>
  <article class="ui-card"><h3>Operator tools</h3><p><code>status</code>, <code>auth</code>, <code>search</code>, <code>help</code>, <code>ui</code>, and <code>tui</code>.</p></article>
</div>

## Documentation map

| Goal | Start here | Result |
| --- | --- | --- |
| Install and load the module | [Installation]({{ '/getting-started/' | relative_url }}) | Imported commands and aliases |
| Configure hosts, tokens, and display preferences | [Configuration]({{ '/configuration/' | relative_url }}) | Repeatable session setup |
| Review owner-space activity without repeated API calls | [Status dashboard]({{ '/concepts/status-dashboard/' | relative_url }}) | Cached repository, namespace, and task summary |
| Pipe complete API objects | [Pipeline output]({{ '/concepts/pipeline-output/' | relative_url }}) | Objects with GitLab IDs and metadata |
| Find a function or parameter | [Command reference]({{ '/cmdlets/' | relative_url }}) | Categorized exported command list |

## Site configuration reference

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `PowerShellVersion` | Version | `7.4.5` | Minimum version declared by the module manifest. |
| `GitLabApiVersion` | String | `v4` | API path used by GitLab request commands. |
| `RouterAlias` | String | `glv` | Alias exported for `Invoke-GLVigor`. |
| `DefaultBorderStyle` | String | `Rounded` | TUI border style used when no configuration override exists. |
| `RawOutput` | Switch | `false` | Emits complete objects instead of rendering router output. |
