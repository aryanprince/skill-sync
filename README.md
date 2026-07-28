# Skill Sync

Skill Sync is a native macOS menu bar app for keeping coding-agent skills and
MCP server configurations organized. It treats `.agents/skills` as the
canonical skill location and reconciles agent-specific directories without
silently overwriting divergent content.

The first release targets Codex and Claude Code on macOS 14 or later.

## Status

Skill Sync is under active development. Filesystem-changing actions are being
built around previews, verification, backups, and Undo.

## Development

Requirements:

- macOS 14 or later
- Xcode 26 or later
- Swift 6

Build and test:

```sh
xcodebuild test \
  -project SkillSync.xcodeproj \
  -scheme SkillSync \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO
```

Check formatting:

```sh
swift format lint --strict --recursive SkillSync SkillSyncTests SkillSyncUITests
```

## Security

Skill Sync never applies a divergent-skill resolution without an explicit
choice. MCP credentials are plain text in the initial release and are redacted
from the app's logs and activity history. See [SECURITY.md](SECURITY.md).

## License

MIT

