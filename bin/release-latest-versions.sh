#!/usr/bin/env bash
#
# Release stubs for every upstream version newer than this repository's newest
# tag.
#
# Forward-only by design: versions at or below the newest existing tag are
# history we deliberately leave alone, so a run can never insert an older
# release on top of the current one, and a repository that has fallen behind
# does not suddenly publish its entire back catalogue.
#
# Nothing is pushed here. The release workflow pushes what this produces.

set -euo pipefail

# --- per-repository configuration -------------------------------------------
PLUGIN_SLUG="storeengine"
DISPLAY_NAME="StoreEngine"
VERSIONS_FILE_NAME="storeengine_versions.txt"
BRANCH_NAME="main"
# ----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="$ROOT_DIR/source"
GENERATE_SCRIPT="$SCRIPT_DIR/generate.sh"
VERSIONS_FILE="$ROOT_DIR/$VERSIONS_FILE_NAME"
PLUGIN_API_URL="https://api.wordpress.org/plugins/info/1.0/${PLUGIN_SLUG}.json"

log()  { echo "==> $*"; }
step() { echo "  - $*"; }
fail() { echo "ERROR: $*" >&2; exit 1; }

for cmd in curl jq unzip git; do
    command -v "$cmd" >/dev/null 2>&1 || fail "required command not found: $cmd"
done
[[ -f "$GENERATE_SCRIPT" ]] || fail "generate script not found: $GENERATE_SCRIPT"

# Keep source/ tidy without touching the two files that belong to the repo.
clean_source() {
    find "$SOURCE_DIR/" -mindepth 1 \
        ! -name 'composer.json' ! -name '.gitignore' \
        -exec rm -rf {} + 2>/dev/null || true
}

log "Fetching $DISPLAY_NAME versions from WordPress.org..."
API_JSON="$(curl -sf "$PLUGIN_API_URL")" || fail "could not reach the WordPress.org API"

# Stable releases only. "trunk" is not a release, a key that does not start with
# a digit is malformed (dokan-lite publishes a literal "v4.1.5"), and none of
# these packages has ever tagged a pre-release.
ALL_VERSIONS="$(jq -r '."versions" | keys[]' <<<"$API_JSON" \
    | grep -E '^[0-9]' \
    | grep -viE '(alpha|beta|-rc|_rc|\.rc|dev)' \
    | sort -V)"
[[ -n "$ALL_VERSIONS" ]] || fail "no versions returned for $PLUGIN_SLUG"

printf '%s\n' "$ALL_VERSIONS" > "$VERSIONS_FILE"

# Forward-only: keep just what sorts strictly above the newest existing tag.
LATEST_TAG="$(git -C "$ROOT_DIR" tag --list 'v*' | sed 's/^v//' \
    | grep -E '^[0-9]' | sort -V | tail -1 || true)"
if [[ -n "$LATEST_TAG" ]]; then
    log "Newest existing tag: v$LATEST_TAG"
    ALL_VERSIONS="$(while IFS= read -r v; do
        if [[ "$v" != "$LATEST_TAG" ]] &&
           [[ "$(printf '%s\n%s\n' "$LATEST_TAG" "$v" | sort -V | tail -1)" == "$v" ]]; then
            echo "$v"
        fi
    done <<<"$ALL_VERSIONS" || true)"
else
    log "No tags yet; releasing the newest upstream version only."
    ALL_VERSIONS="$(tail -1 <<<"$ALL_VERSIONS")"
fi

PENDING="$(grep -v '^$' <<<"$ALL_VERSIONS" || true)"
if [[ -z "$PENDING" ]]; then
    log "Already up to date, nothing to release."
    exit 0
fi

TOTAL="$(grep -c '' <<<"$PENDING")"
log "$TOTAL version(s) to release: $(tr '\n' ' ' <<<"$PENDING")"

RELEASED=0
SKIPPED=0
N=0
while IFS= read -r VERSION; do
    N=$((N + 1))
    log "[$N/$TOTAL] $DISPLAY_NAME $VERSION"

    clean_source

    ZIP="$SOURCE_DIR/${PLUGIN_SLUG}.${VERSION}.zip"
    step "downloading..."
    if ! curl -sfL -o "$ZIP" "https://downloads.wordpress.org/plugin/${PLUGIN_SLUG}.${VERSION}.zip"; then
        step "download failed, skipping"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    step "extracting..."
    if ! unzip -q -d "$SOURCE_DIR/" "$ZIP"; then
        step "extract failed, skipping"
        rm -f "$ZIP"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi
    rm -f "$ZIP"

    # The finder configs use paths relative to the repository root.
    step "generating stubs..."
    if ! (cd "$ROOT_DIR" && bash "$GENERATE_SCRIPT"); then
        step "stub generation failed, skipping"
        clean_source
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Stage first, then inspect the index: a stub file that does not exist yet
    # is untracked, and an unstaged check would not notice it.
    git -C "$ROOT_DIR" add -A -- . ':(exclude)source' || fail "git add failed"

    if git -C "$ROOT_DIR" diff --cached --quiet; then
        step "identical to the previous version, no tag"
    else
        git -C "$ROOT_DIR" commit -q -m "Generate stubs for $DISPLAY_NAME $VERSION"
        git -C "$ROOT_DIR" tag "v${VERSION}"
        step "tagged v${VERSION}"
        RELEASED=$((RELEASED + 1))
    fi

    clean_source
done <<<"$PENDING"

log "Done: $RELEASED released, $SKIPPED skipped."
