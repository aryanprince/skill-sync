# Architecture

Skill Sync is intentionally a small native app. SwiftUI owns presentation,
Foundation and AppKit provide filesystem/process/platform behavior, and Sparkle
handles application updates. There is no database, web view, embedded Node.js,
or privileged helper.

## Layers

```text
SwiftUI views
    ↓ user intents / published state
AppModel (@MainActor)
    ↓
Domain plans and agent-neutral models
    ↓
Scanning · reconciliation · process execution · persistence
    ↓
Agent adapters · skills.sh · MCP Registry · Sparkle
```

`AppModel` is the UI boundary. File scanning and command execution live in
actors so work does not block the main thread. Agent-specific conventions are
isolated behind adapters instead of leaking paths into views.

## Skill reconciliation

The canonical project layout is:

```text
project/
  .agents/skills/example/     physical source of truth
  .claude/skills/example  ->  ../../.agents/skills/example
  .codex/skills/example   ->  ../../.agents/skills/example (legacy, if present)
```

The state machine is:

```text
scan → fingerprint → classify → preview → revalidate → back up → link → rescan
```

Classification distinguishes canonical content, agent-only content, identical
duplicates, healthy links, broken links, and conflicts. Only deterministic
states receive one-click actions. A content conflict requires an explicit user
choice.

## Agent adapters

The current adapters support:

| Concern | Codex | Claude Code |
|---|---|---|
| Skills | `.agents/skills` plus legacy `.codex/skills` discovery | `.claude/skills` symlink target |
| Global MCP | `~/.codex/config.toml` via `codex mcp` | `~/.claude.json` via `claude mcp --scope user` |
| Project MCP | `<project>/.codex/config.toml` through isolated `CODEX_HOME` | `<project>/.mcp.json` via `--scope project` |

Future agents should implement a path/command adapter and reuse the same domain
planner. The UI should not branch on a new agent's directory convention.

## External commands

Commands are constructed as argument arrays and launched with `Process`; shell
strings exist only for previews. Known secret values are redacted from captured
stdout/stderr. The skills integration pins the npm package version and disables
telemetry.

## Persistence

Watched roots use `UserDefaults`. Backups, the operation journal, and transient
cache live under `~/Library/Application Support/Skill Sync`. Installed skills
and MCP configuration remain in the agents' own locations.
