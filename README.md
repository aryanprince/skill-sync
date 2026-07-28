# Skill Sync

Skill Sync is a native macOS menu bar app that keeps coding-agent skills and MCP
servers organized. It uses `.agents/skills` as the canonical location, links
Claude Code back to that source of truth, and previews every filesystem change
before it runs.

The initial release supports Codex, Claude Code, macOS 14+, and both Apple
Silicon and Intel Macs.

## What it does

- Scans user-selected project folders plus global agent directories.
- Finds physical duplicates, healthy links, broken links, and divergent skill
  conflicts across `.agents`, `.claude`, and legacy `.codex` locations.
- Moves a selected skill to `.agents/skills`, creates relative symlinks for
  compatible agent directories, and keeps recoverable backups.
- Searches [skills.sh](https://skills.sh), installs with a pinned `skills` CLI,
  and checks global or project skills for updates.
- Lists Codex and Claude Code MCP servers and searches the official
  [MCP Registry](https://registry.modelcontextprotocol.io).
- Adds and removes MCP servers through the agents' own CLIs. Secret fields are
  masked in the UI and redacted from command output.
- Updates non-Homebrew installations through
  [Sparkle 2](https://sparkle-project.org).

Skill Sync does not make a divergent-content decision automatically. Conflicts
remain untouched until the user chooses what should become canonical.

## Current credential model

Version 0.1 stores MCP values in the configuration format already consumed by
Codex or Claude Code. That means credentials are plain text. Project-scoped
credentials receive an explicit warning because `.mcp.json` or `.codex` may be
tracked by Git.

Keychain-backed credentials and environment-manager integration are deliberately
outside the initial scope. See [SECURITY.md](SECURITY.md) for the exact safety
boundary.

## Requirements

- macOS 14 Sonoma or later
- Xcode 26 or later for development
- Node.js with `npx` available for skills.sh installation and updates
- The Codex and/or Claude Code CLI for the corresponding MCP operations

The app itself is SwiftUI/AppKit and has no web runtime, persistent database, or
background helper. Sparkle is the only bundled third-party runtime dependency.

## Build from source

Clone the repository and open `SkillSync.xcodeproj`, or stay entirely in the
terminal:

```sh
git clone https://github.com/aryanprince/skill-sync.git
cd skill-sync
xcodebuild \
  -project SkillSync.xcodeproj \
  -scheme SkillSync \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/SkillSyncDerived \
  CODE_SIGNING_ALLOWED=NO \
  build
open /tmp/SkillSyncDerived/Build/Products/Debug/SkillSync.app
```

Xcode is not required to scaffold or build subsequent changes. The checked-in
project and shared Swift Package resolution make CLI builds deterministic.

## Development checks

Run the same validation used by CI:

```sh
brew install swiftlint
Scripts/ci.sh
```

Individual checks:

```sh
swift format lint --strict --recursive SkillSync SkillSyncTests SkillSyncUITests
swiftlint lint --strict
xcodebuild test \
  -project SkillSync.xcodeproj \
  -scheme SkillSync \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO
```

`swift format` handles deterministic formatting. SwiftLint adds semantic style
rules, while the Swift compiler provides type checking and strict concurrency
checking. Swift Testing is used for unit tests.

## Project map

```text
SkillSync/
  Application/       App state and navigation
  Domain/            Agent-neutral models and plans
  Infrastructure/    Scanning, filesystem, process, persistence
  Integrations/      Agent, skills.sh, MCP Registry, Sparkle adapters
  Views/              SwiftUI manager, menu bar, sheets, settings
Scripts/              CI and release packaging
packaging/homebrew/   Generated-cask template
```

See [Architecture](docs/ARCHITECTURE.md), [Contributing](CONTRIBUTING.md), and
[Releasing](docs/RELEASING.md) for the deeper implementation and maintenance
guides.

## Distribution status

The repository can already produce and test an unsigned universal app. Public
DMG and Homebrew distribution remain gated on a Developer ID certificate and
Apple notarization. The release workflow is prepared but no paid Apple Developer
account or signing material is stored in this repository.

## License

[MIT](LICENSE) © 2026 Skill Sync Contributors
