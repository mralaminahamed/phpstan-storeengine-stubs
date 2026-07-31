#!/usr/bin/env bash
#
# Generate StoreEngine stubs for all available versions.
#
# This script:
# 1. Fetches all available StoreEngine versions from WordPress.org
# 2. Creates a versions file with all available versions
# 3. For each version, downloads the plugin, generates stubs, and creates a Git tag
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

# Initialize variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_FILE="$ROOT_DIR/storeengine_versions.txt"
PLUGIN_NAME="storeengine"
PLUGIN_API_URL="https://api.wordpress.org/plugins/info/1.0/storeengine.json"
SOURCE_DIR="$ROOT_DIR/source"
GENERATE_SCRIPT="$SCRIPT_DIR/generate.sh"

# Check required commands
echo "Checking required commands..."
check_command curl
check_command jq
check_command unzip
check_command git

# Ensure the generate script is executable
[[ -x "$GENERATE_SCRIPT" ]] || error_exit "Generate script not found or not executable: $GENERATE_SCRIPT"

echo "Fetching plugin information from WordPress.org..."
if ! WC_JSON="$(curl -s "$PLUGIN_API_URL")"; then
    error_exit "Failed to fetch plugin information from WordPress.org"
fi

# Prepare output file
echo "Preparing versions file: $OUTPUT_FILE"
> "$OUTPUT_FILE"

# Extract and filter versions, excluding "trunk"
echo "Extracting versions..."
if ! VERSIONS=$(jq -r '."versions" | keys[]' <<<"$WC_JSON" | grep -v "trunk" | sort -V); then
    error_exit "Failed to extract versions from WordPress.org response"
fi

# Collect all versions
echo "Collecting versions..."
for VERSION in $VERSIONS; do
    echo "$VERSION" >> "$OUTPUT_FILE"
done

# Count total versions for progress display
TOTAL_VERSIONS=$(wc -l < "$OUTPUT_FILE")
CURRENT_VERSION=0

echo "Found $TOTAL_VERSIONS versions"

# Remove the vtrunk tag if it exists
if git show-ref --tags | grep -q "refs/tags/vtrunk"; then
    echo "Removing vtrunk tag..."
    git tag -d vtrunk
fi

# Process each version
while IFS= read -r VERSION; do
    CURRENT_VERSION=$((CURRENT_VERSION + 1))
    echo "[$CURRENT_VERSION/$TOTAL_VERSIONS] Processing version ${VERSION}..."

    # Check if the tag already exists
    if git rev-parse "refs/tags/v${VERSION}" >/dev/null 2>&1; then
        echo "  - Tag exists for version ${VERSION}, skipping."
        continue
    fi

    # Clean up source directory
    echo "  - Cleaning up source directory..."
    git status --ignored --short -- "$SOURCE_DIR" | sed -n -e 's#^!! ##p' | xargs --no-run-if-empty -- rm -rf

    # Try downloading and processing the version
    DOWNLOAD_URL="https://downloads.wordpress.org/plugin/$PLUGIN_NAME.${VERSION}.zip"
    DOWNLOAD_PATH="$SOURCE_DIR/$PLUGIN_NAME.${VERSION}.zip"

    echo "  - Downloading version ${VERSION}..."
    if ! curl -s -L -o "$DOWNLOAD_PATH" "$DOWNLOAD_URL"; then
        echo "  - Failed to download version ${VERSION}, skipping."
        continue
    fi

    echo "  - Extracting plugin files..."
    if ! unzip -q -d "$SOURCE_DIR" "$DOWNLOAD_PATH"; then
        echo "  - Failed to extract version ${VERSION}, skipping."
        rm -f "$DOWNLOAD_PATH"
        continue
    fi

    # Generate stubs
    echo "  - Generating stubs..."
    if ! "$GENERATE_SCRIPT"; then
        echo "  - Failed to generate stubs for version ${VERSION}, skipping."
        rm -rf "$SOURCE_DIR"/*
        continue
    fi

    # Git operations
    echo "  - Adding files to Git..."
    git add .

    echo "  - Committing and tagging version ${VERSION}..."
    git commit -m "Generate stubs for StoreEngine ${VERSION}" || true
    git tag "v${VERSION}"

    # Clean up downloaded files
    echo "  - Cleaning up temporary files..."
    rm -rf "$SOURCE_DIR"/*
done < "$OUTPUT_FILE"

echo "All versions processed successfully."
echo "Generated stubs for $(git tag | grep -c '^v') versions."
