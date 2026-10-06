#!/usr/bin/env bash
set -Eeuo pipefail

# Install the agent skills that cannot be committed into .claude/skills/.
#
# The vendored skills in .claude/skills/ are MIT and tracked in git. These
# three sources are not, because their licenses do not permit redistribution,
# so each checkout installs them locally and .gitignore keeps them out:
#
#   1. Apple's Xcode-bundled skills (`xcrun agent skills export`). They ship
#      with Xcode under Apple's license. macOS with Xcode 27+ only; re-run
#      after each Xcode update.
#   2. OpenAI's Build iOS Apps plugin skills (github.com/openai/plugins). The
#      repo carries no license. Pinned to OPENAI_PLUGINS_SHA so an upstream
#      change cannot alter agent instructions until someone reviews it and
#      bumps the pin. Its swiftui-liquid-glass collides with the vendored
#      FloWritesCode skill of the same name, so it installs as
#      swiftui-liquid-glass-openai.
#   3. Krzysztof Zabłocki's general.md (merowing.info), no license. Wrapped as
#      a manual-only skill: its directives apply to "EVERY Swift/SwiftUI
#      query" and demand clarifying questions first, which would override
#      AGENTS.md if it were auto-invoked. Pinned by sha256. His
#      rule-loading.md is not installed: it only routes to the paid
#      Swifty Stack rule files.
#
# Every installed directory is checked with `git check-ignore` before the
# script finishes; a new skill that .gitignore does not cover is removed and
# reported, so an Xcode or pin update can never stage licensed content.
#
# Linux sessions (Claude Code on the web, Cursor Cloud) have no xcrun: the
# Apple step is skipped and the rest still installs.

OPENAI_PLUGINS_SHA=5fd93af4cd0c623e020d0cc7e9ce178b4ac1f70f
MEROWING_GENERAL_URL=https://merowing.info/assets/files/general.md
MEROWING_GENERAL_SHA256=310209777cbeee675cda964ee2224ea777ea1793f49b8b7311d090b098b7733f

repo_root="$(git rev-parse --show-toplevel)"
dest="$repo_root/.claude/skills"
staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT

installed=()
failures=0

install_skill() {
  local src="$1" name="$2"
  rm -rf "${dest:?}/$name"
  cp -R "$src" "$dest/$name"
  installed+=("$name")
}

sha256() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

# --- 1. Apple ---------------------------------------------------------------
if ! command -v xcrun >/dev/null 2>&1; then
  echo "apple: xcrun not found (not macOS); skipping Apple's Xcode skills."
else
  xcode_major="$(xcodebuild -version 2>/dev/null | awk '/^Xcode/ { split($2, v, "."); print v[1] }')"
  if [[ -z "$xcode_major" || "$xcode_major" -lt 27 ]]; then
    echo "apple: Xcode 27 or later is required (selected: ${xcode_major:-none})." >&2
    echo "apple: check \`xcode-select -p\`, or point DEVELOPER_DIR at an Xcode 27 install." >&2
    failures=$((failures + 1))
  else
    # --output-dir resolves relative paths against /, so it must be absolute.
    xcrun agent skills export --output-dir "$staging/apple" >/dev/null
    for skill_dir in "$staging"/apple/*/; do
      install_skill "$skill_dir" "$(basename "$skill_dir")"
    done
    echo "apple: installed $(find "$staging/apple" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ') skills"
  fi
fi

# --- 2. OpenAI Build iOS Apps -------------------------------------------------
openai_repo="$staging/openai"
git init -q "$openai_repo"
git -C "$openai_repo" remote add origin https://github.com/openai/plugins.git
git -C "$openai_repo" sparse-checkout set --no-cone /plugins/build-ios-apps/skills/
git -C "$openai_repo" fetch -q --depth 1 origin "$OPENAI_PLUGINS_SHA"
git -C "$openai_repo" checkout -q FETCH_HEAD
for skill_dir in "$openai_repo"/plugins/build-ios-apps/skills/*/; do
  name="$(basename "$skill_dir")"
  rm -rf "$skill_dir/agents" # Codex-only metadata
  if [[ "$name" == swiftui-liquid-glass ]]; then
    sed 's/^name: swiftui-liquid-glass$/name: swiftui-liquid-glass-openai/' \
      "$skill_dir/SKILL.md" > "$skill_dir/SKILL.md.tmp"
    mv "$skill_dir/SKILL.md.tmp" "$skill_dir/SKILL.md"
    name=swiftui-liquid-glass-openai
  fi
  install_skill "$skill_dir" "$name"
done
echo "openai: installed build-ios-apps skills at ${OPENAI_PLUGINS_SHA:0:7}"

# --- 3. merowing general.md ---------------------------------------------------
curl -fsSL "$MEROWING_GENERAL_URL" -o "$staging/general.md"
actual_sha="$(sha256 "$staging/general.md")"
if [[ "$actual_sha" != "$MEROWING_GENERAL_SHA256" ]]; then
  echo "merowing: general.md changed upstream (sha256 $actual_sha); review it and update MEROWING_GENERAL_SHA256." >&2
  failures=$((failures + 1))
else
  mkdir -p "$staging/merowing-swift-engineering"
  {
    cat <<'EOF'
---
name: merowing-swift-engineering
description: Krzysztof Zabłocki's Swift Engineering Excellence Framework (general.md from merowing.info). Manual only; invoke with /merowing-swift-engineering for his architecture-first review lens on a Swift change.
disable-model-invocation: true
---

<!-- Installed by scripts/install-local-skills.sh from
https://merowing.info/assets/files/general.md (sha256 pinned there).
Manual only: the directives below were written to apply to every Swift
query. When they conflict with AGENTS.md (for example, asking
clarifying questions before every change, the 🏗️ load signal, or
dependencies.mdc, which is not installed), AGENTS.md wins. -->

EOF
    cat "$staging/general.md"
  } > "$staging/merowing-swift-engineering/SKILL.md"
  install_skill "$staging/merowing-swift-engineering" merowing-swift-engineering
  echo "merowing: installed merowing-swift-engineering (manual only)"
fi

# --- Guard: nothing installed here may be tracked by git ----------------------
for name in "${installed[@]}"; do
  if ! git -C "$repo_root" check-ignore -q ".claude/skills/$name/SKILL.md"; then
    rm -rf "${dest:?}/$name"
    echo "guard: .claude/skills/$name is not gitignored; removed it. Add it to the local-skills block in .gitignore and re-run." >&2
    failures=$((failures + 1))
  fi
done

# --- Tiers: every skill, vendored or local, needs an entry in skillOverrides ---
if ! python3 "$repo_root/scripts/check-skill-tiers.py"; then
  failures=$((failures + 1))
fi

if [[ "$failures" -gt 0 ]]; then
  exit 1
fi
echo "Done. Restart Claude Code sessions to pick up new skills."
