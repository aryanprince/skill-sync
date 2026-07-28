# Security policy

## Reporting a vulnerability

Please report vulnerabilities privately through GitHub's security advisory
feature instead of opening a public issue.

## Credential model

The initial release supports plain-text MCP credentials because Codex and
Claude Code consume their own configuration files. Skill Sync masks secret
input and redacts known values from process output and activity logs, but it
does not provide encrypted storage yet.

Prefer local or user-scoped MCP configuration. Skill Sync warns before placing
a literal credential in a Git-tracked project file.

## Filesystem model

Skill Sync limits mutations to user-selected roots, revalidates a plan before
execution, and creates recoverable backups before replacing physical content.

