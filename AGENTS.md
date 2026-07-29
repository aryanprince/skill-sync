# AGENTS.md

Guidance for AI agents working in this repository.

## Product overview

**Skill Sync** is a native macOS menu bar application (SwiftUI/AppKit) that organizes coding-agent skills and MCP servers across Codex and Claude Code. There is no backend server, database, or web frontend.

## Platform requirement

**Full build, test, and run require macOS 14+ with Xcode 26+.** The app uses AppKit, SwiftUI, and `xcodebuild`; it cannot be compiled or launched on Linux.

On Linux cloud-agent VMs, use the partial checks documented below. For complete validation, rely on CI (`macos-15` runner) or a local Mac.

## Cursor Cloud specific instructions

### What works on Linux cloud VMs

| Check | Command |
|-------|---------|
| SwiftLint (style rules) | `swiftlint lint --strict` (uses `swiftlint-static`; see update script) |
| Shell script syntax | `bash -n Scripts/ci.sh` (and other `Scripts/*.sh`) |
| Skills CLI (optional integration) | `npx --yes skills@1.5.20 --help` |

### What requires macOS

| Check | Command |
|-------|---------|
| Format lint | `swift format lint --strict --recursive SkillSync SkillSyncTests SkillSyncUITests` |
| Unit tests | `xcodebuild test -project SkillSync.xcodeproj -scheme SkillSync -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO -only-testing:SkillSyncTests` |
| Debug build + launch | See `README.md` |
| Full CI parity | `Scripts/ci.sh` (needs `swift format`, `swiftlint`, and `xcodebuild`) |

### Running SwiftLint on Linux

The dynamic `swiftlint` binary may crash on some cloud VMs (`libsourcekitdInProc.so` / illegal instruction). The VM update script installs `swiftlint-static` to `~/.local/bin` and symlinks `swiftlint` to it. Ensure `~/.local/bin` is on `PATH`.

SourceKit-dependent analyzer rules are skipped automatically on Linux; CI on macOS runs the full rule set.

### Optional external CLIs (not bundled)

- **Node.js 22+ / `npx`** — skills.sh install/update (`skills@1.5.20`)
- **`codex` CLI** — Codex MCP management
- **`claude` CLI** — Claude Code MCP management

Unit tests run fully offline with temp directories. UI tests only launch the app and are not run in CI.

### Project layout

```text
SkillSync/           Application source (Swift)
SkillSyncTests/      Swift Testing unit tests
SkillSyncUITests/    XCTest UI tests
Scripts/             ci.sh, build-release.sh, create-dmg.sh
docs/                Architecture and releasing guides
```

### Standard commands (macOS)

See `README.md` and `CONTRIBUTING.md`. Before opening a PR on macOS, run `Scripts/ci.sh`.
