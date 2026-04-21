Title: Agents

URL Source: https://opencode.ai/docs/agents/

Markdown Content:
# Agents | OpenCode

Configure and use specialized agents.

Agents are specialized AI assistants that can be configured for specific tasks and workflows. They allow you to create focused tools with custom prompts, models, and tool access.

Tip

Use the plan agent to analyze code and review suggestions without making any code changes.

You can switch between agents during a session or invoke them with the `@` mention.

---

## [Types](https://opencode.ai/docs/agents/#types)

There are two types of agents in OpenCode; primary agents and subagents.

---

### [Primary agents](https://opencode.ai/docs/agents/#primary-agents)

Primary agents are the main assistants you interact with directly. You can cycle through them using the **Tab** key, or your configured `switch_agent` keybind. These agents handle your main conversation. Tool access is configured via permissions — for example, Build has all tools enabled while Plan is restricted.

Tip

You can use the **Tab** key to switch between primary agents during a session.

OpenCode comes with two built-in primary agents, **Build** and **Plan**. We’ll look at these below.

---

### [Subagents](https://opencode.ai/docs/agents/#subagents)

Subagents are specialized assistants that primary agents can invoke for specific tasks. You can also manually invoke them by **@ mentioning** them in your messages.

OpenCode comes with two built-in subagents, **General** and **Explore**. We’ll look at this below.

---

## [Built-in](https://opencode.ai/docs/agents/#built-in)

OpenCode comes with two built-in primary agents and two built-in subagents.

---

### [Use build](https://opencode.ai/docs/agents/#use-build)

*Mode*: `primary`

Build is the **default** primary agent with all tools enabled. This is the standard agent for development work where you need full access to file operations and system commands.

---

### [Use plan](https://opencode.ai/docs/agents/#use-plan)

*Mode*: `primary`

A restricted agent designed for planning and analysis. We use a permission system to give you more control and prevent unintended changes. By default, all of the following are set to `ask`:

- `file edits`: All writes, patches, and edits
- `bash`: All bash commands

This agent is useful when you want the LLM to analyze code, suggest changes, or create plans without making any actual modifications to your codebase.

---

### [Use general](https://opencode.ai/docs/agents/#use-general)

*Mode*: `subagent`

A general-purpose agent for researching complex questions and executing multi-step tasks. Has full tool access (except todo), so it can make file changes when needed. Use this to run multiple units of work in parallel.

---

### [Use explore](https://opencode.ai/docs/agents/#use-explore)

*Mode*: `subagent`

A fast, read-only agent for exploring codebases. Cannot modify files. Use this when you need to quickly find files by patterns, search code for keywords, or answer questions about the codebase.

---

### [Use compaction](https://opencode.ai/docs/agents/#use-compaction)

*Mode*: `primary`

Hidden system agent that compacts long context into a smaller summary. It runs automatically when needed and is not selectable in the UI.

---

### [Use title](https://opencode.ai/docs/agents/#use-title)

*Mode*: `primary`

Hidden system agent that generates short session titles. It runs automatically and is not selectable in the UI.

---

### [Use summary](https://opencode.ai/docs/agents/#use-summary)

*Mode*: `primary`

Hidden system agent that creates session summaries. It runs automatically and is not selectable in the UI.

---

## [Usage](https://opencode.ai/docs/agents/#usage)

1. For primary agents, use the **Tab** key to cycle through them during a session. You can also use your configured `switch_agent` keybind.
2. Subagents can be invoked:
   - **Automatically** by primary agents for specialized tasks based on their descriptions.
   - Manually by **@ mentioning** a subagent in your message. For example:
     ```
     @general help me search for this function
     ```
3. **Navigation between sessions**: When subagents create child sessions, use `session_child_first` (default: **<Leader>+Down**) to enter the first child session from the parent.
4. Once you are in a child session, use:
   - `session_child_cycle` (default: **Right**) to cycle to the next child session
   - `session_child_cycle_reverse` (default: **Left**) to cycle to the previous child session
   - `session_parent` (default: **Up**) to return to the parent session

---

## [Configure](https://opencode.ai/docs/agents/#configure)

You can customize the built-in agents or create your own through configuration. Agents can be configured in two ways:

---

### [JSON](https://opencode.ai/docs/agents/#json)

opencode.json
```json
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "build": {
      "mode": "primary",
      "model": "anthropic/claude-sonnet-4-20250514",
      "prompt": "{file:./prompts/build.txt}",
      "tools": {
        "write": true,
        "edit": true,
        "bash": true
      }
    },
    "plan": {
      "mode": "primary",
      "model": "anthropic/claude-haiku-4-20250514",
      "tools": {
        "write": false,
        "edit": false,
        "bash": false
      }
    },
    "code-reviewer": {
      "description": "Reviews code for best practices and potential issues",
      "mode": "subagent",
      "model": "anthropic/claude-sonnet-4-20250514",
      "prompt": "You are a code reviewer. Focus on security, performance, and maintainability.",
      "tools": {
        "write": false,
        "edit": false
      }
    }
  }
}
```

---

### [Markdown](https://opencode.ai/docs/agents/#markdown)

Global: `~/.config/opencode/agents/`
Per-project: `.opencode/agents/`

review.md
```markdown
---
description: Reviews code for quality and best practices
mode: subagent
model: anthropic/claude-sonnet-4-20250514
temperature: 0.1
tools:
  write: false
  edit: false
  bash: false
---
You are in code review mode. Focus on:
- Code quality and best practices
- Potential bugs and edge cases
- Performance implications
- Security considerations
Provide constructive feedback without making direct changes.
```

---

## [Options](https://opencode.ai/docs/agents/#options)

- **Description**: Brief explanation of the agent's role.
- **Temperature**: Control randomness (0.0-1.0).
- **Max steps**: Limit agentic iterations (`steps`).
- **Prompt**: System prompt file path.
- **Model**: Provider/model-id override.
- **Permissions**: Control tool access (`ask`, `allow`, `deny`).
- **Mode**: `primary`, `subagent`, or `all`.
- **Hidden**: Hide from `@` menu.
- **Task permissions**: Control subagent invocation.
- **Color**: UI customization.

Last updated: Apr 21, 2026
