# Releasing Skill Sync

The release workflow is intentionally prepared but cannot publish a trusted app
until an Apple Developer Program membership and signing credentials exist.

## One-time setup

1. Create a Developer ID Application certificate and export it as a password-
   protected `.p12`.
2. Create an App Store Connect API key with notarization access.
3. Resolve the Sparkle package once, then run its `generate_keys` tool with a
   Skill Sync-specific account. Back up the private key securely:

   ```sh
   /path/to/Sparkle/bin/generate_keys --account skill-sync
   /path/to/Sparkle/bin/generate_keys --account skill-sync -x sparkle-private-key
   ```

4. Create a protected GitHub environment named `release`, ideally with required
   reviewer approval.
5. Add these environment secrets:

   | Secret | Value |
   |---|---|
   | `DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64` | Base64-encoded `.p12` |
   | `DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD` | `.p12` password |
   | `DEVELOPMENT_TEAM` | Apple team identifier |
   | `APPLE_API_KEY_ID` | App Store Connect API key ID |
   | `APPLE_API_ISSUER_ID` | App Store Connect issuer ID |
   | `APPLE_API_PRIVATE_KEY_BASE64` | Base64-encoded `.p8` |
   | `SPARKLE_PUBLIC_ED_KEY` | Public key printed by `generate_keys` |
   | `SPARKLE_PRIVATE_ED_KEY` | Contents exported with `generate_keys -x` |

The workflow injects the public key before compiling; the private key never
enters the app bundle.

## Release sequence

1. Update `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`, and `CHANGELOG.md`.
2. Run `Scripts/ci.sh` and merge the version change to `main`.
3. Create and push an annotated tag, for example `v0.1.0`.
4. The Release workflow builds a universal archive, signs it with Developer ID,
   notarizes and staples the app and DMG, signs the Sparkle archive, publishes a
   GitHub Release, emits a Homebrew cask, and updates `appcast.xml` on `main`.
5. Verify the DMG on a separate Mac and use “Check for Updates…” from the prior
   app version before announcing the release.

The tag version must exactly match `MARKETING_VERSION`; the workflow stops
otherwise.

## Local unsigned package check

Unsigned output is for development only and will trigger Gatekeeper if shared:

```sh
Scripts/build-release.sh /tmp/SkillSyncRelease
Scripts/create-dmg.sh \
  /tmp/SkillSyncRelease/SkillSync.xcarchive/Products/Applications/SkillSync.app \
  /tmp/SkillSyncRelease/SkillSync-0.1.0.dmg
```

## Homebrew

Every release includes a rendered `skill-sync.rb`. Until the project qualifies
for the main Homebrew Cask repository, publish that formula from a tap such as
`aryanprince/homebrew-tap`. Users can then install with:

```sh
brew install --cask aryanprince/tap/skill-sync
```

Homebrew users update with `brew upgrade --cask skill-sync`; direct-download
users update through Sparkle.
