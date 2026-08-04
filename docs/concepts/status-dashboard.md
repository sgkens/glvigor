---
title: Owner-space status dashboard
description: Use the cache-first status TUI to review owned repositories, namespaces, activity, and assigned work without repeated GitLab API traffic.
permalink: /concepts/status-dashboard/
---

# Owner-space status dashboard

<code>glv status</code> is a detailed, read-only terminal dashboard for the authenticated user's GitLab owner space. It combines personal repositories, repositories in groups or subgroups where the user has Owner access, namespace activity, repository visibility, open-issue totals, and assigned tasks.

## Cache-first operation

    # Render the existing local snapshot; fetch only when the cache is missing
    glv status

    # Explicitly refresh the snapshot from GitLab, then render it
    glv status -Update

    # Return the complete snapshot for scripts without rendering the TUI
    $status = glv status -Raw
    $status.RecentProjects | Select-Object Path, OpenIssues, LastActivityAtUtc

The cache is stored at <code>~/.phellams/glvigor/status-cache.json</code>. GLVigor writes it atomically so an interrupted refresh does not replace a valid snapshot with a partial document. A snapshot older than 24 hours is marked stale in the dashboard, but it is not refreshed automatically; use <code>-Update</code> when live metadata is required.

If no compatible cache exists, or the cache belongs to a different authenticated host or user, <code>glv status</code> performs one initial refresh.

## Owner-only scope

Projects are fetched with GitLab Owner access level 50. Assigned issues use one capped query and are then filtered against those project IDs before they enter the cache. The dashboard therefore does not surface tasks from repositories outside the authenticated user's owner space.

The dashboard separates:

- Personal repositories owned by the authenticated user.
- Repositories owned through groups and subgroups.
- Owned GitLab group metadata.
- Recently updated repositories, ordered by last activity.
- Assigned open issues in owned repositories.

## Bounded refresh plan

A refresh uses a fixed query shape rather than making a request for every repository:

1. Reuse the authenticated session identity without another API request.
2. Paginated owner-access project index.
3. Paginated owner-access group index.
4. One assigned-open-issues request capped at 100 results.

The TUI shows when the assigned-task cap was reached. The normalized Raw object also exposes <code>ApiPlan.TasksMayBeMore</code>, allowing automation to distinguish a complete task page from a capped summary.

## Snapshot object

    $status = glv status -Raw

    $status.Summary
    $status.Namespaces
    $status.RecentProjects
    $status.Tasks
    $status.Cache

The cache contains normalized metadata only. Authentication tokens, secure strings, and HTTP headers are never serialized.

### Summary fields

<code>Summary</code> includes total, personal, group-owned, recently active, private, internal, public, and archived repository counts. It also includes owned-group, open-issue, and assigned-task totals.

### Cache fields

<code>Cache.Path</code> identifies the active cache file, <code>Cache.AgeHours</code> gives its precise age, <code>Cache.IsStale</code> becomes true after 24 hours, and <code>Cache.Refreshed</code> indicates whether the current command fetched GitLab.
