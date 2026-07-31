#!/usr/bin/env bash
#
# Generate StoreEngine stubs for the latest versions.
#
# This script:
# 1. Fetches the latest StoreEngine versions from WordPress.org
# 2. Updates the project with the remote branch
# 3. Processes only the versions that haven't been tagged yet
# 4. Generates stubs for each new version
#

# Exit immediately if a command exits with a non-zero status
set -e

# Error handling function
function error_exit {
    echo "ERROR: $1" >&2
    exit 1
}

# Command existence check
function check_command {
    command -v "$1" >/dev/null 2>&1 || error_exit "Required command '$1' not found"
}

# Progress output function
function log_step {
    echo "==> $1"
}

# Check if a command succeeded
function check_result {
    if [ $? -ne 0 ]; then
        error_exit "$1"
    fi
}

# Initialize variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_FILE="$ROOT_DIR/storeengine_versions.txt"
PLUGIN_NAME="storeengine"
PLUGIN_API_URL="https://api.wordpress.org/plugins/info/1.0/storeengine.json"
SOURCE_DIR="$ROOT_DIR/source"
GENERATE_SCRIPT="$SCRIPT_DIR/generate.sh"
BRANCH_NAME="main"

# Check required commands
log_step "Checking required commands..."
check_command curl
check_command jq
check_command unzip
check_command git

# Ensure the generate script is executable
[[ -x "$GENERATE_SCRIPT" ]] || error_exit "Generate script not found or not executable: $GENERATE_SCRIPT"

# Update from remote repository
log_step "Updating from remote repository..."
git fetch --all
check_result "Failed to fetch from remote repository"

git reset --hard "origin/$BRANCH_NAME"
check_result "Failed to reset to origin/$BRANCH_NAME"

# Fetch plugin information
log_step "Fetching plugin information from WordPress.org..."
WC_JSON="$(curl -s "$PLUGIN_API_URL")"
check_result "Failed to fetch plugin information from WordPress.org"

# Prepare output file
log_step "Preparing versions file: $OUTPUT_FILE"
> "$OUTPUT_FILE"

# Extract and filter versions, excluding "trunk"
log_step "Extracting versions..."
VERSIONS=$(jq -r '."versions" | keys[]' <<<"$WC_JSON" | grep -v "trunk" | sort -V)
check_result "Failed to extract versions from WordPress.org response"

# Collect all versions in the output file
log_step "Collecting versions..."
for VERSION in $VERSIONS; do
    echo "$VERSION" >> "$OUTPUT_FILE"
done

# Count total versions for progress display
TOTAL_VERSIONS=$(wc -l < "$OUTPUT_FILE")
CURRENT_VERSION=0

log_step "Found $TOTAL_VERSIONS versions"

# Remove the vtrunk tag if it exists
if git show-ref --tags | grep -q "refs/tags/vtrunk"; then
    log_step "Removing vtrunk tag..."
    git tag -d vtrunk
fi

# Process each version
while IFS= read -r VERSION; do
    CURRENT_VERSION=$((CURRENT_VERSION + 1))
    log_step "[$CURRENT_VERSION/$TOTAL_VERSIONS] Processing version ${VERSION}..."

    # Check if the tag already exists
    if git rev-parse "refs/tags/v${VERSION}" >/dev/null 2>&1; then
        echo "  - Tag exists for version ${VERSION}, skipping."
        continue
    fi

    # Clean up source directory, keeping composer.json and .gitignore
    echo "  - Cleaning up source directory..."
    find "$SOURCE_DIR/" -mindepth 1 ! -name 'composer.json' ! -name '.gitignore' -exec rm -rf {} + 2>/dev/null || true

    # Download the new version
    DOWNLOAD_URL="https://downloads.wordpress.org/plugin/$PLUGIN_NAME.${VERSION}.zip"
    DOWNLOAD_PATH="$SOURCE_DIR/${PLUGIN_NAME}.${VERSION}.zip"

    echo "  - Downloading version ${VERSION}..."
    if ! curl -s -L -o "$DOWNLOAD_PATH" "$DOWNLOAD_URL"; then
        echo "  - Failed to download version ${VERSION}, skipping."
        continue
    fi

    # Extract plugin files
    echo "  - Extracting plugin files..."
    if ! unzip -q -d "$SOURCE_DIR/" "$DOWNLOAD_PATH"; then
        echo "  - Failed to extract version ${VERSION}, skipping."
        rm -f "$DOWNLOAD_PATH"
        continue
    fi

    # Generate stubs
    echo "  - Generating stubs..."
    if ! "$GENERATE_SCRIPT"; then
        echo "  - Failed to generate stubs for version ${VERSION}, skipping."
        find "$SOURCE_DIR/" -mindepth 1 ! -name 'composer.json' ! -name '.gitignore' -exec rm -rf {} + 2>/dev/null || true
        continue
    fi

    # Check if there are any changes to commit
    if git diff-index --quiet HEAD --; then
        echo "  - No changes to commit for version ${VERSION}, skipping tag."
    else
        # Commit and tag the new version
        echo "  - Committing and tagging version ${VERSION}..."
        git add .
        git commit -m "Generate stubs for StoreEngine ${VERSION}"
        git tag "v${VERSION}"
    fi

    # Clean up the source directory
    echo "  - Cleaning up temporary files..."
    find "$SOURCE_DIR/" -mindepth 1 ! -name 'composer.json' ! -name '.gitignore' -exec rm -rf {} + 2>/dev/null || true
done < "$OUTPUT_FILE"

log_step "All versions processed successfully."
log_step "Generated stubs for $(git tag | wc -l) versions total, including $(git tag | grep -c "^v$VERSION" || echo "0") new."

# Optional: Push changes to remote
echo
echo "Run the following commands to push changes:"
echo "  git push origin $BRANCH_NAME"
echo "  git push --tags"
