#!/bin/bash
# Search compressed images by content
# Usage: ./search-images.sh "query"
#
# Arguments:
#   query - Search term to find in image summaries
#
# Environment:
#   OPENCLAW_WORKSPACE - Override default workspace path

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

QUERY="${1:-}"

if [ -z "$QUERY" ]; then
    log_error "Usage: $0 '<search query>'"
    exit 1
fi

if [ ! -f "$METADATA_STORE" ]; then
    log_error "No metadata found at: $METADATA_STORE"
    exit 1
fi

log_info "Searching images for: $QUERY"
echo ""

jq -r --arg query "$QUERY" '.[] | select(.summary | ascii_downcase | contains($query | ascii_downcase)) | "📸 \(.filename)\n📅 \(.timestamp | strftime("%Y-%m-%d %H:%M"))\n📝 \(.summary)\n---"' "$METADATA_STORE"

exit 0
