---
layout: default
title: Remove-GithubRepositories
alias: glvghrm
module: Other Git Providers (OGP)
synopsis: Deletes GitHub repositories by ID or Owner/Repo name string with confirmation safety controls (-SkillConfirm:$false).
---

<h1 id="remove-githubrepositories">Remove-GithubRepositories (<code>glvghrm</code>)</h1>
<p class="lede">{{ page.synopsis }}</p>

<h2 id="syntax">Syntax<a class="anchor" href="#syntax"> #</a></h2>

<div class="pane">
  <div class="pane-bar">
    <span class="dots"><span></span><span></span><span></span></span>
    <span class="pane-title">syntax</span>
  </div>
  <div class="pane-body">
<pre><code>Remove-GithubRepositories [-Id] &lt;Object[]&gt; [-Owner &lt;String&gt;] [-SkillConfirm &lt;Boolean&gt;] [-ApiKey &lt;String&gt;]</code></pre>
  </div>
</div>

<h2 id="parameters">Parameters<a class="anchor" href="#parameters"> #</a></h2>

<table>
  <thead>
    <tr><th>Parameter</th><th>Type</th><th>Required</th><th>Description</th></tr>
  </thead>
  <tbody>
    <tr><td><code>-Id</code></td><td>Object[]</td><td>True</td><td>An array of GitHub repository IDs or repository objects (piped from <code>Get-GithubRepositories</code>).</td></tr>
    <tr><td><code>-Owner</code></td><td>String</td><td>False</td><td>Optional owner name if repository full name or ID is resolved with owner context.</td></tr>
    <tr><td><code>-SkillConfirm</code></td><td>Boolean</td><td>False</td><td>Confirmation safety switch. Defaults to <code>$true</code>. Set <code>-SkillConfirm:$false</code> to bypass the interactive prompt.</td></tr>
    <tr><td><code>-ApiKey</code></td><td>String</td><td>False</td><td>GitHub Personal Access Token with <code>delete_repo</code> scope.</td></tr>
  </tbody>
</table>

<h2 id="examples">Examples<a class="anchor" href="#examples"> #</a></h2>

<div class="pane">
  <div class="pane-bar">
    <span class="dots"><span></span><span></span><span></span></span>
    <span class="pane-title">examples</span>
    <button class="pane-action" data-copy="Remove-GithubRepositories -Id 'octocat/hello-world' -SkillConfirm:$false
Get-GithubRepositories -User 'octocat' | Remove-GithubRepositories -SkillConfirm:$false">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="11" height="11" rx="1"/><path d="M5 15V5a2 2 0 0 1 2-2h10"/></svg>
      <span>copy</span>
    </button>
  </div>
  <div class="pane-body">
<pre><code><span class="tok-com"># Delete a single repository without an interactive prompt</span>
Remove-GithubRepositories -Id <span class="tok-str">'octocat/hello-world'</span> -SkillConfirm:<span class="tok-num">$false</span>

<span class="tok-com"># Pipe repositories directly into deletion</span>
Get-GithubRepositories -User <span class="tok-str">'octocat'</span> | Remove-GithubRepositories -SkillConfirm:<span class="tok-num">$false</span></code></pre>
  </div>
</div>
