Title: Agent Skills

URL Source: https://opencode.ai/docs/skills/

Markdown Content:
# Agent Skills | OpenCode

Define reusable behavior via SKILL.md definitions.

Agent skills let OpenCode discover reusable instructions from your repo or home directory. Skills are loaded on-demand via the native `skill` tool.

---

## [Structure](https://opencode.ai/docs/skills/#place-files)

Create one folder per skill name containing a `SKILL.md`:
- `.opencode/skills/<name>/SKILL.md`
- `~/.config/opencode/skills/<name>/SKILL.md`

### [Discovery](https://opencode.ai/docs/skills/#understand-discovery)
OpenCode walks up from CWD to git worktree root to find local skills, and also loads global skills from `~/.config/opencode/`.

---

## [SKILL.md Specification](https://opencode.ai/docs/skills/#write-frontmatter)

### [Frontmatter](https://opencode.ai/docs/skills/#write-frontmatter)
```yaml
---
name: my-skill
description: Specific instructions for X task
license: MIT
metadata:
  workflow: specialized
---
```
- **Name**: 1-64 chars, lowercase alphanumeric, single hyphens.
- **Description**: 1-1024 chars, used by agents to decide when to load.

---

## [Usage](https://opencode.ai/docs/skills/#recognize-tool-description)

Agents see a list of `<available_skills>` in the `skill` tool description. They load a skill by calling:
`skill({ name: "skill-name" })`

---

## [Permissions](https://opencode.ai/docs/skills/#configure-permissions)

Control skill access in `opencode.json`:
```json
{
  "permission": {
    "skill": {
      "*": "allow",
      "internal-*": "deny",
      "experimental-*": "ask"
    }
  }
}
```
Skills with `deny` are hidden from agents entirely.

Last updated: Apr 21, 2026
