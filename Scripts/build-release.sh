#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${1:-$ROOT_DIR/.release}"
DERIVED_DATA_PATH="$OUTPUT_DIR/DerivedData"
ARCHIVE_PATH="$OUTPUT_DIR/SkillSync.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/SkillSync.app"

if [[ -e "$OUTPUT_DIR" ]]; then
    echo "Output directory already exists: $OUTPUT_DIR" >&2
    echo "Choose a new path or remove the existing directory intentionally." >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
cd "$ROOT_DIR"

BUILD_ARGUMENTS=(
    -project SkillSync.xcodeproj
    -scheme SkillSync
    -configuration Release
    -destination 'generic/platform=macOS'
    -derivedDataPath "$DERIVED_DATA_PATH"
    -archivePath "$ARCHIVE_PATH"
    ARCHS='arm64 x86_64'
    ONLY_ACTIVE_ARCH=NO
)

if [[ -n "${RELEASE_SIGNING_IDENTITY:-}" ]]; then
    : "${DEVELOPMENT_TEAM:?DEVELOPMENT_TEAM is required for signed releases}"
    BUILD_ARGUMENTS+=(
        CODE_SIGN_STYLE=Manual
        "CODE_SIGN_IDENTITY=$RELEASE_SIGNING_IDENTITY"
        "DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM"
        OTHER_CODE_SIGN_FLAGS='--timestamp --options runtime'
    )
else
    BUILD_ARGUMENTS+=(CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO)
fi

xcodebuild "${BUILD_ARGUMENTS[@]}" archive

if [[ ! -d "$APP_PATH" ]]; then
    echo "Archive did not contain SkillSync.app" >&2
    exit 1
fi

BINARY_PATH="$APP_PATH/Contents/MacOS/SkillSync"
ARCHITECTURES="$(lipo -archs "$BINARY_PATH")"
if [[ "$ARCHITECTURES" != *arm64* || "$ARCHITECTURES" != *x86_64* ]]; then
    echo "Expected a universal binary, found: $ARCHITECTURES" >&2
    exit 1
fi

echo "$APP_PATH"
