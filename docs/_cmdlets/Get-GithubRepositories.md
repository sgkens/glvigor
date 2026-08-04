---
layout: default
title: Get-GithubRepositories
alias: glvghls
module: Other Git Providers (OGP)
synopsis: Lists GitHub repositories for a specified user or organization (defaults to user space with ownership scoping).
---

<h1 id="get-githubrepositories">Get-GithubRepositories (<code>glvghls</code>)</h1>
<p class="lede">{{ page.synopsis }}</p>

<h2 id="syntax">Syntax<a class="anchor" href="#syntax"> #</a></h2>

<div class="pane">
  <div class="pane-bar">
    <span class="dots"><span></span><span></span><span></span></span>
    <span class="pane-title">syntax</span>
  </div>
  <div class="pane-body">
<pre><code>Get-GithubRepositories [-User &lt;String&gt;] [-Org &lt;String&gt;] [-IsOrg] [-Visibility &lt;String&gt;] [-Sort &lt;String&gt;] [-Global] [-ApiKey &lt;String&gt;]</code></pre>
  </div>
</div>

<h2 id="parameters">Parameters<a class="anchor" href="#parameters"> #</a></h2>

<table>
  <thead>
    <tr><th>Parameter</th><th>Type</th><th>Required</th><th>Description</th></tr>
  </thead>
  <tbody>
    <tr><td><code>-User</code></td><td>String</td><td>False</td><td>GitHub username to list repositories for. Defaults to authenticated user space.</td></tr>
    <tr><td><code>-Org</code></td><td>String</td><td>False</td><td>GitHub organization name to list repositories for.</td></tr>
    <tr><td><code>-IsOrg</code></td><td>Switch</td><td>False</td><td>Explicitly query organization scope instead of user space.</td></tr>
    <tr><td><code>-Visibility</code></td><td>String</td><td>False</td><td>Filter repositories by visibility: <code>all</code>, <code>public</code>, <code>private</code>. Default is <code>all</code>.</td></tr>
    <tr><td><code>-Sort</code></td><td>String</td><td>False</td><td>Property to sort by: <code>created</code>, <code>updated</code>, <code>pushed</code>, <code>full_name</code>. Default is <code>full_name</code>.</td></tr>
    <tr><td><code>-Global</code></td><td>Switch</td><td>False</td><td>Bypasses default personal and organization ownership scope filtering.</td></tr>
    <tr><td><code>-ApiKey</code></td><td>String</td><td>False</td><td>GitHub Personal Access Token. If omitted, uses <code>$env:GITHUB_API_KEY</code>.</td></tr>
  </tbody>
</table>

<h2 id="examples">Examples<a class="anchor" href="#examples"> #</a></h2>

<div class="pane">
  <div class="pane-bar">
    <span class="dots"><span></span><span></span><span></span></span>
    <span class="pane-title">examples</span>
    <button class="pane-action" data-copy="Get-GithubRepositories -User 'octocat'
Get-GithubRepositories -Org 'my-company-org' -IsOrg -Global
Get-GithubRepositories -User 'octocat' | Remove-GithubRepositories -SkillConfirm:$false">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="11" height="11" rx="1"/><path d="M5 15V5a2 2 0 0 1 2-2h10"/></svg>
      <span>copy</span>
    </button>
  </div>
  <div class="pane-body">
<pre><code><span class="tok-com"># List repositories for user 'octocat'</span>
Get-GithubRepositories -User <span class="tok-str">'octocat'</span>

<span class="tok-com"># List organization repositories with global bypass switch</span>
Get-GithubRepositories -Org <span class="tok-str">'my-company-org'</span> -IsOrg -Global

<span class="tok-com"># Pipe repositories into non-interactive deletion</span>
Get-GithubRepositories -User <span class="tok-str">'octocat'</span> | Remove-GithubRepositories -SkillConfirm:<span class="tok-num">$false</span></code></pre>
  </div>
</div>
