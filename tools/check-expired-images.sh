#!/bin/bash
# Check expired image summaries and prompt for retention
# Run this via cron or heartbeat
#
# Environment:
#   OPENCLAW_WORKSPACE - Override default workspace path

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Ensure image store exists
ensure_dir "$IMAGE_STORE" || exit 1

if [ ! -f "$METADATA_STORE" ]; then
    log_info "No image metadata found"
    exit 0
fi

NOW=$(date +%s)

# Read metadata and check for expired entries (use process substitution to preserve EXPIRED_COUNT)
EXPIRED_COUNT=0
while read -r entry; do
    EXPIRED_COUNT=$((EXPIRED_COUNT + 1))
    
    ID=$(echo "$entry" | jq -r '.id')
    FILENAME=$(echo "$entry" | jq -r '.filename')
    SUMMARY=$(echo "$entry" | jq -r '.summary')
    TIMESTAMP=$(echo "$entry" | jq -r '.timestamp')
    
    log_warning "Image summary expired: $FILENAME"
    log_info "Summary: $SUMMARY"
    log_info "Created: $(date -d @$TIMESTAMP)"
    echo ""
done < <(jq -c '.[] | select(.expiry < '"$NOW"' and .reviewed == false)' "$METADATA_STORE")

if [ "$EXPIRED_COUNT" -gt 0 ]; then
    log_info "Found $EXPIRED_COUNT expired image summaries"
    log_info "Review needed: Check $METADATA_STORE"
fi

exit 0
