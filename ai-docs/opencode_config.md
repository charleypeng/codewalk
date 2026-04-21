Title: Config

URL Source: https://opencode.ai/docs/config/

Markdown Content:
# Config | OpenCode

Using the OpenCode JSON config.

You can configure OpenCode using a JSON config file.

---

## [Format](https://opencode.ai/docs/config/#format)

OpenCode supports both **JSON** and **JSONC** (JSON with Comments) formats.

opencode.jsonc
```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4-5",
  "autoupdate": true,
  "server": {
    "port": 4096,
  }
}
```

---

## [Locations](https://opencode.ai/docs/config/#locations)

Configuration files are **merged together**, not replaced.

### [Precedence order](https://opencode.ai/docs/config/#precedence-order)

1. **Remote config** (`.well-known/opencode`)
2. **Global config** (`~/.config/opencode/opencode.json`)
3. **Custom config** (`OPENCODE_CONFIG` env var)
4. **Project config** (`opencode.json` in project root)
5. **.opencode directories** (agents, commands, plugins)
6. **Inline config** (`OPENCODE_CONFIG_CONTENT` env var)
7. **Managed config files** (system-wide admin settings)
8. **macOS managed preferences** (MDM enforced)

---

## [Schema](https://opencode.ai/docs/config/#schema)

The server/runtime config schema is defined in [**opencode.ai/config.json**](https://opencode.ai/config.json).
TUI config uses [**opencode.ai/tui.json**](https://opencode.ai/tui.json).

### [Key Sections](https://opencode.ai/docs/config/#schema)

- **TUI**: UI settings, scroll speed, mouse support.
- **Server**: Port, hostname, mDNS, CORS.
- **Tools**: Enable/disable specific tool access.
- **Models**: Main and small model selection, provider options.
- **Agents**: Custom agent definitions and default agent choice.
- **Permissions**: Global tool approval policies (`ask`, `allow`, `deny`).
- **Compaction**: Context window management.
- **Instructions**: Project rules and guidelines via markdown files.

---

## [Variables](https://opencode.ai/docs/config/#variables)

### [Env vars](https://opencode.ai/docs/config/#env-vars)
Use `{env:VARIABLE_NAME}` to substitute environment variables.

### [Files](https://opencode.ai/docs/config/#files)
Use `{file:path/to/file}` to substitute the contents of a file.

Last updated: Apr 21, 2026
