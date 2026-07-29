# AGENTS.md

Guidance for AI agents working in this repository.

## Product overview

**Skill Sync** is a native macOS menu bar application (SwiftUI/AppKit) that organizes coding-agent skills and MCP servers across Codex and Claude Code. It uses `.agents/skills` as the canonical source of truth, symlinks agent-specific directories back to it, and previews every filesystem change before execution.

There is no backend server, database, web frontend, or embedded Node runtime. Persistence is local (`UserDefaults`, `~/Library/Application Support/Skill Sync`, and the agents' own config files).

## Platform requirement

**Full build, test, and run require macOS 14+ with Xcode 26+.** The app uses AppKit, SwiftUI, and `xcodebuild`; it cannot be compiled or launched on Linux.

On Linux cloud-agent VMs, use the partial checks documented below. For complete validation, rely on CI (`macos-15` runner) or a local Mac.

## Tech stack

| Area | Value |
|------|-------|
| Language | Swift **6.0**, `SWIFT_STRICT_CONCURRENCY = complete` |
| UI | SwiftUI + AppKit (menu bar app, `LSUIElement`) |
| Platform | macOS **14.0+** (`MACOSX_DEPLOYMENT_TARGET`), universal **arm64 + x86_64** |
| App version | `0.1.0` (`MARKETING_VERSION` in `SkillSync.xcodeproj`) |
| Package manager | Swift Package Manager (via Xcode); no `package.json` or CocoaPods |
| SPM dependency | [Sparkle 2.9.2](https://github.com/sparkle-project/Sparkle) (in-app updates) |
| Unit tests | Swift Testing (`import Testing`) in `SkillSyncTests/` |
| UI tests | XCTest in `SkillSyncUITests/` (not run in CI) |
| Lint / format | SwiftLint (`.swiftlint.yml`) + `swift format` (`.swift-format`) |
| CI | GitHub Actions on `macos-15` (`.github/workflows/ci.yml`) |

## Architecture

```text
SwiftUI views (Views/)
    ↓ user intents / @Published state
AppModel (@MainActor, Application/)
    ↓
Domain models and plans (Domain/)
    ↓
Scanning · reconciliation · process execution · persistence (Infrastructure/)
    ↓
Agent adapters · skills.sh · MCP Registry · Sparkle (Integrations/)
```

`AppModel` is the UI boundary. Heavy work runs in **actors** (`WorkspaceScanner`, `SkillFileSystem`, `ProcessRunner`, `SkillsCLI`, `MCPService`, etc.) so the main thread stays responsive. Agent-specific paths and CLI syntax live in adapters — views must not branch on agent directory conventions.

See `docs/ARCHITECTURE.md` for the full design rationale.

### Skill reconciliation

Canonical layout:

```text
project/
  .agents/skills/example/     physical source of truth
  .claude/skills/example  ->  ../../.agents/skills/example
  .codex/skills/example   ->  ../../.agents/skills/example   (legacy, if present)
```

State machine: `scan → fingerprint → classify → preview → revalidate → back up → link → rescan`

Classification covers canonical content, agent-only content, identical duplicates, healthy links, broken links, and conflicts. **Never auto-resolve content conflicts** — the user must choose what becomes canonical.

### Agent adapters

| Concern | Codex | Claude Code |
|---------|-------|-------------|
| Skills | `.agents/skills` + legacy `.codex/skills` discovery | `.claude/skills` symlink target |
| Global MCP | `~/.codex/config.toml` via `codex mcp` | `~/.claude.json` via `claude mcp --scope user` |
| Project MCP | `<project>/.codex/config.toml` (isolated `CODEX_HOME`) | `<project>/.mcp.json` via `--scope project` |

Adapter types: `AgentsStandardAdapter`, `ClaudeCodeAdapter`, `CodexLegacyAdapter` — all conform to `AgentAdapter`.

### External integrations

| Integration | Endpoint / command | Notes |
|-------------|-------------------|-------|
| skills.sh catalog | `https://skills.sh/api/search` | `SkillsCatalogClient` |
| skills CLI | `npx --yes skills@1.5.20` | Pinned in `SkillsCLI.pinnedVersion`; telemetry disabled |
| MCP Registry | `https://registry.modelcontextprotocol.io` | `MCPRegistryClient` |
| Codex MCP | `codex mcp` subcommands | `CodexMCPAdapter` |
| Claude MCP | `claude mcp` subcommands | `ClaudeMCPAdapter` |
| Sparkle updates | `appcast.xml` in repo root | Feed URL in `SkillSync/Info.plist` |

Commands are built as **argument arrays** and launched with `Process`; shell strings exist only for UI previews. Known secret values are redacted from captured stdout/stderr.

## Project layout

```text
SkillSync/
  Application/       AppModel, navigation (AppDestination)
  Domain/            Agent-neutral models (Workspace, SkillRecord, ReconciliationPlan, …)
  Infrastructure/    Scanning, filesystem, process runner, persistence
  Integrations/      Agent adapters, skills.sh, MCP Registry, Sparkle
  Views/             SwiftUI manager, menu bar, catalog, MCP, settings
SkillSyncTests/      Swift Testing unit tests (7 files, fully offline)
SkillSyncUITests/    XCTest UI tests (launch-only smoke)
Scripts/             ci.sh, build-release.sh, create-dmg.sh
packaging/homebrew/  Generated-cask template
docs/                ARCHITECTURE.md, RELEASING.md
```

## Testing

| Target | Framework | CI? | Notes |
|--------|-----------|-----|-------|
| `SkillSyncTests` | Swift Testing | Yes (`-only-testing:SkillSyncTests`) | Uses `TestDirectory` helper with temp dirs; no network or external CLIs |
| `SkillSyncUITests` | XCTest | No | Only verifies app launch |

Test files and primary coverage:

- `WorkspaceScannerTests` — scan/classify across `.agents`, `.claude`, `.codex`
- `ReconciliationTests` — plan generation and conflict handling
- `SkillFileSystemTests` — backup, symlink, and mutation safety
- `ProcessRunnerTests` — command execution and secret redaction
- `SkillsCatalogTests` — CLI argument construction
- `MCPIntegrationTests` — MCP command generation for both agents

Add Swift Testing coverage for new filesystem mutations and command-generation behavior. Follow the safety sequence in `CONTRIBUTING.md`.

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

SourceKit-dependent analyzer rules (`unused_declaration`, `unused_import`) are skipped automatically on Linux; CI on macOS runs the full rule set.

### Optional external CLIs (not bundled)

- **Node.js 22+ / `npx`** — skills.sh install/update (`skills@1.5.20`)
- **`codex` CLI** — Codex MCP management
- **`claude` CLI** — Claude Code MCP management

## Development commands (macOS)

```sh
# Full CI validation
brew install swiftlint
Scripts/ci.sh

# Individual checks
swift format lint --strict --recursive SkillSync SkillSyncTests SkillSyncUITests
swiftlint lint --strict
xcodebuild test \
  -project SkillSync.xcodeproj \
  -scheme SkillSync \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/SkillSyncDerived \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:SkillSyncTests

# Debug build + launch
xcodebuild \
  -project SkillSync.xcodeproj \
  -scheme SkillSync \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/SkillSyncDerived \
  CODE_SIGNING_ALLOWED=NO \
  build
open /tmp/SkillSyncDerived/Build/Products/Debug/SkillSync.app
```

## Conventions for agents

1. Keep agent-specific paths and CLI syntax inside `Integrations/` adapters.
2. Any new filesystem mutation must follow: discover → preview → revalidate → backup → execute → rescan.
3. Use Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`).
4. Never commit real API keys, signing certificates, or machine-specific MCP configs.
5. Run `Scripts/ci.sh` before opening a PR (on macOS).

See `CONTRIBUTING.md`, `SECURITY.md`, and `docs/RELEASING.md` for contributor rules, credential boundaries, and release steps.
