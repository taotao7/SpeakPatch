#!/bin/bash
# Builds a release app bundle and zip artifact for GitHub Releases.
#
# Usage: ./scripts/package-release.sh 0.1.0

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="${1:-}"
if [[ -z "$VERSION" && -n "${GITHUB_REF_NAME:-}" ]]; then
    VERSION="${GITHUB_REF_NAME#v}"
fi

if [[ -z "$VERSION" ]]; then
    echo "usage: $0 <version>" >&2
    exit 64
fi

BUILD_NUMBER="${GITHUB_RUN_NUMBER:-1}"
ARTIFACT_DIR="$ROOT/dist"
ZIP_NAME="SpeakPatch-${VERSION}-macos.zip"
ZIP_PATH="$ARTIFACT_DIR/$ZIP_NAME"
CHECKSUM_PATH="$ARTIFACT_DIR/$ZIP_NAME.sha256"

rm -rf "$ARTIFACT_DIR"
mkdir -p "$ARTIFACT_DIR"

SPEAKPATCH_VERSION="$VERSION" SPEAKPATCH_BUILD="$BUILD_NUMBER" ./scripts/build-app.sh release

ditto -c -k --sequesterRsrc --keepParent SpeakPatch.app "$ZIP_PATH"
SHA256="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
printf "%s  %s\n" "$SHA256" "$ZIP_NAME" > "$CHECKSUM_PATH"

echo "zip=$ZIP_PATH"
echo "checksum=$CHECKSUM_PATH"
echo "sha256=$SHA256"
