#!/bin/bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 /path/to/SkillSync.app /path/to/SkillSync-version.dmg" >&2
    exit 64
fi

APP_PATH="$1"
DMG_PATH="$2"

if [[ ! -d "$APP_PATH" || "$APP_PATH" != *.app ]]; then
    echo "Expected an existing .app bundle: $APP_PATH" >&2
    exit 66
fi

if [[ "$DMG_PATH" != *.dmg ]]; then
    echo "Output must end in .dmg: $DMG_PATH" >&2
    exit 64
fi

if [[ -e "$DMG_PATH" ]]; then
    echo "Refusing to overwrite existing file: $DMG_PATH" >&2
    exit 73
fi

STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/SkillSyncDMG.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT

ditto "$APP_PATH" "$STAGING_DIR/SkillSync.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "Skill Sync" \
    -srcfolder "$STAGING_DIR" \
    -format UDZO \
    "$DMG_PATH"
