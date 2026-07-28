# Security policy

## Reporting a vulnerability

Report vulnerabilities privately through GitHub's security advisory feature.
Do not open a public issue with an exploit, credential, or sensitive local path.

## Filesystem safety model

Skill Sync only scans global agent locations and roots the user selects. A
cleanup is split into planning and execution. Before execution, the source is
fingerprinted again; changed or divergent content is skipped. Physical content
is moved into `~/Library/Application Support/Skill Sync/Backups` before a
relative symlink replaces it, and the latest in-session operation can be undone.

The app never follows a conflict by choosing one copy automatically. It also
does not request root privileges.

## MCP credentials

The initial release intentionally uses the plain-text configuration supported
by Codex and Claude Code. Secret input fields are visually masked, and known
secret values are removed from process output and in-app activity messages.
They still exist in the destination agent configuration.

Prefer global or local user configuration for credentials. Before writing a
literal value to a project-scoped configuration, inspect whether `.mcp.json` or
`.codex` is tracked and keep secret-bearing files out of Git.

Skill Sync does not currently use Keychain, inject values through mise, or
upload MCP configuration to a Skill Sync service.

## Network access

The app talks directly to:

- `https://skills.sh/api/search` for catalog search;
- `https://registry.modelcontextprotocol.io` for MCP discovery;
- the Sparkle feed hosted in this repository for application updates;
- npm through `npx` only after the user confirms a skill install or update.

Telemetry is disabled when Skill Sync invokes the skills CLI.

## Release trust

Public releases must be Developer ID signed, Apple notarized, and signed with a
separate Sparkle EdDSA key. Release credentials belong in the protected GitHub
`release` environment, never in source control. CI actions are pinned to full
commit SHAs.
