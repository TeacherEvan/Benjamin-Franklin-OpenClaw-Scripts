#!/bin/bash
# Get image context for AI conversations
# Returns recent image summaries for context

METADATA="/home/ubuntu/.openclaw/clawd/memory/images/metadata.json"
HOURS="${1:-24}"  # Default: last 24 hours

CUTOFF=$(($(date +%s) - (HOURS * 3600)))

echo "Recent images (last ${HOURS}h):"
jq -r --arg cutoff "$CUTOFF" '.[] | select(.timestamp > ($cutoff | tonumber)) | "- \(.filename | split(".")[0]): \(.summary[:100])..."' "$METADATA"
