# Contributing

Thanks for helping improve Skill Sync.

## Before opening a pull request

1. Open an issue before a large behavior or configuration-format change.
2. Keep agent-specific paths and command syntax inside adapters.
3. Add Swift Testing coverage for filesystem and command-generation behavior.
4. Use Conventional Commit messages such as `feat:`, `fix:`, `docs:`, and
   `chore:`.
5. Run `Scripts/ci.sh`.

Install the optional lint dependency with `brew install swiftlint`. Formatting
uses the `swift format` command bundled with Xcode.

## Filesystem changes

Any new mutation must follow the same safety sequence:

1. Discover and classify without writing.
2. Present an exact review plan.
3. Revalidate the source immediately before execution.
4. Back up physical content before replacing it.
5. Prefer relative symlinks.
6. Rescan and report the result.

Never turn a content conflict into an implicit overwrite.

## Sensitive data

Never include real API keys, access tokens, private Sparkle keys, Apple signing
certificates, MCP configuration copied from a personal home directory, or
fixtures containing machine-specific credentials.

## Pull request checklist

- [ ] Formatting and SwiftLint pass.
- [ ] Unit tests pass.
- [ ] A universal Release build contains `arm64` and `x86_64`.
- [ ] New file mutations have conflict and recovery tests.
- [ ] User-facing behavior and the changelog are updated.
