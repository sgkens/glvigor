---
layout: default
title: Pipelines & CI/CD Jobs
permalink: /cmdlets/pipelines/
---

# Pipelines & CI/CD Jobs Cmdlets

Cmdlets for managing GitLab CI/CD pipelines, jobs, traces, and artifacts.

## `Get-GLVPipeline` (`glvpipe`)
Retrieves and visualizes GitLab pipeline status or local `.gitlab-ci.yml` flowgraphs.

```powershell
Get-GLVPipeline -Local
Get-GLVPipeline -Live
```

## `Request-GLVJobTrace` (`glvrqtrace`)
Retrieves job execution trace logs.

```powershell
Request-GLVJobTrace -JobID 98765
```

## `Request-GLVJobArtifact` (`glvrqart`)
Downloads CI/CD job artifacts.

```powershell
Request-GLVJobArtifact -ProjectID 12345 -JobID 98765 -OutFile './artifacts.zip'
```
