#!/bin/bash
# Writes the SpeakPatch Homebrew cask into a tap checkout.
#
# Usage: ./scripts/update-tap-cask.sh /path/to/homebrew-tap 0.1.0 <sha256>

set -euo pipefail

TAP_ROOT="${1:-}"
VERSION="${2:-}"
SHA256="${3:-}"

if [[ -z "$TAP_ROOT" || -z "$VERSION" || -z "$SHA256" ]]; then
    echo "usage: $0 <tap-root> <version> <sha256>" >&2
    exit 64
fi

mkdir -p "$TAP_ROOT/Casks"

cat > "$TAP_ROOT/Casks/speakpatch.rb" <<RUBY
cask "speakpatch" do
  version "$VERSION"
  sha256 "$SHA256"

  url "https://github.com/taotao7/SpeakPatch/releases/download/v#{version}/SpeakPatch-#{version}-macos.zip",
      verified: "github.com/taotao7/SpeakPatch/"
  name "SpeakPatch"
  desc "Menu-bar assistant for rewriting selected text"
  homepage "https://github.com/taotao7/SpeakPatch"

  depends_on macos: :ventura

  app "SpeakPatch.app"

  zap trash: "~/Library/Preferences/com.speakpatch.app.plist"
end
RUBY
