#!/bin/bash
# Get image context for AI conversations
# Returns recent image summaries for context
# Usage: ./recent-images-context.sh [hours]
#
# Arguments:
#   hours - Time window in hours (default: 24)
#
# Environment:
#   OPENCLAW_WORKSPACE - Override default workspace path

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

HOURS="${1:-24}"  # Default: last 24 hours
CUTOFF=$(($(date +%s) - (HOURS * 3600)))

if [ ! -f "$METADATA_STORE" ]; then
    log_error "No metadata found at: $METADATA_STORE"
    exit 1
fi

echo "Recent images (last ${HOURS}h):"
jq -r --arg cutoff "$CUTOFF" '.[] | select(.timestamp > ($cutoff | tonumber)) | "- \(.filename | split(".")[0]): \(.summary[:100])..."' "$METADATA_STORE"

exit 0
