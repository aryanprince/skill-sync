#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${TMPDIR:-/tmp}/SkillSyncDerived}"

cd "$ROOT_DIR"

swift format lint --strict --recursive SkillSync SkillSyncTests SkillSyncUITests

if command -v swiftlint >/dev/null 2>&1; then
    swiftlint lint --strict
else
    echo "warning: SwiftLint is not installed; skipping SwiftLint checks."
fi

xcodebuild \
    -project SkillSync.xcodeproj \
    -scheme SkillSync \
    -destination 'platform=macOS' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    -only-testing:SkillSyncTests \
    test

xcodebuild \
    -project SkillSync.xcodeproj \
    -scheme SkillSync \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    ARCHS='arm64 x86_64' \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGNING_ALLOWED=NO \
    build

BINARY_PATH="$DERIVED_DATA_PATH/Build/Products/Release/SkillSync.app/Contents/MacOS/SkillSync"
ARCHITECTURES="$(lipo -archs "$BINARY_PATH")"

if [[ "$ARCHITECTURES" != *arm64* || "$ARCHITECTURES" != *x86_64* ]]; then
    echo "Expected a universal binary, found: $ARCHITECTURES" >&2
    exit 1
fi

echo "Validated universal binary: $ARCHITECTURES"
