---
description: Review OpenCode releases and assess CodeWalk impact
agent: planner
---

Review the target OpenCode release and decide whether CodeWalk needs follow-up work.

Target selection:
- If `$ARGUMENTS` is empty, analyze the latest OpenCode release using the snapshot below.
- If `$ARGUMENTS` is present, treat it as the target release reference. It can be a tag, compare URL, or release URL. Fetch that exact target before reaching conclusions.

Latest release snapshot:
!`python -c 'import json,urllib.request;req=urllib.request.Request("https://api.github.com/repos/anomalyco/opencode/releases/latest",headers={"User-Agent":"CodeWalk release-monitor"});data=json.load(urllib.request.urlopen(req));body=(data.get("body") or "").strip();body=body[:4000]+("..." if len(body)>4000 else "");print(json.dumps({"tag_name":data.get("tag_name"),"name":data.get("name"),"published_at":data.get("published_at"),"html_url":data.get("html_url"),"body":body}, indent=2))'`

Mandatory local anchors:
- `ADR.md` (ADR-023 is the primary compatibility rule)
- `ai-docs/opencode_server.md`
- `ai-docs/opencode_web.md`
- `ai-docs/opencode_models.md`
- `CODEBASE.md`
- `BEHAVIOR.md`
- `ROADMAP.md`

CodeWalk hotspots worth checking when relevant:
- `lib/presentation/services/local_opencode_server_runtime_io.dart`
- `lib/data/datasources/chat_remote_datasource.dart`
- `lib/presentation/providers/chat_provider.dart`
- `lib/presentation/providers/settings_provider.dart`
- `lib/presentation/pages/chat_page.dart`

Rules:
- Use `planner`, not the built-in `plan` agent.
- Stay analysis-only. Do not edit files or implement changes.
- Treat ADR-023 and official OpenCode docs/source as the compatibility source of truth.
- Focus first on Core, Desktop, and Web impact, then cover any other affected surfaces.
- If release notes are vague, inspect linked upstream docs/source before concluding that no work is needed.
- Classify every proposed follow-up as `required`, `recommended`, or `none`.
- When suggesting CodeWalk work, cite exact repo paths.

Return exactly these sections:

## Release Examined
- Target:
- Why this target:

## Upstream Summary
- Summarize the relevant release changes briefly.

## Impact & Risk by Area
### Core
- Impact:
- Risk:
- Evidence:

### Desktop
- Impact:
- Risk:
- Evidence:

### Web
- Impact:
- Risk:
- Evidence:

### Other
- Impact:
- Risk:
- Evidence:

## Proposal of Adjustments
- required:
- recommended:
- none:

## Execution Plan
- If CodeWalk changes are needed, provide a numbered implementation plan with exact files and validation steps.
- If no work is needed, write exactly `No CodeWalk changes required now.` and explain why.

## Follow-up Checks
- List any docs, tests, ADR, roadmap, or verification follow-up that should happen next.
