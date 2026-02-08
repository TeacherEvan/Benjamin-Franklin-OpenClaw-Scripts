#!/bin/bash
# Image compression stats dashboard
# Usage: ./image-stats.sh
#
# Environment:
#   OPENCLAW_WORKSPACE - Override default workspace path

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

if [ ! -f "$METADATA_STORE" ]; then
    log_error "No metadata found at: $METADATA_STORE"
    exit 1
fi

log_info "Image Compression Stats"
echo ""
echo "Total images tracked: $(jq 'length' "$METADATA_STORE")"
echo "Reviewed: $(jq '[.[] | select(.reviewed == true)] | length' "$METADATA_STORE")"
echo "Pending review: $(jq '[.[] | select(.reviewed == false)] | length' "$METADATA_STORE")"
echo ""
echo "Storage saved: $(du -sh "$WORKSPACE/media/inbound" 2>/dev/null | cut -f1) (original images deleted)"
echo ""
echo "Oldest: $(jq -r '.[] | .timestamp' "$METADATA_STORE" | sort -n | head -1 | xargs -I {} date -d @{} '+%Y-%m-%d %H:%M')"
echo "Newest: $(jq -r '.[] | .timestamp' "$METADATA_STORE" | sort -n | tail -1 | xargs -I {} date -d @{} '+%Y-%m-%d %H:%M')"
echo ""
echo "Expired (>24h): $(jq --arg now "$(date +%s)" '[.[] | select(.expiry < ($now | tonumber))] | length' "$METADATA_STORE")"

exit 0
