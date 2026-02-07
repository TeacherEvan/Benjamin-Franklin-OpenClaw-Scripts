#!/bin/bash
# Check expired image summaries and prompt for retention
# Run this via cron or heartbeat

WORKSPACE="/home/ubuntu/.openclaw/clawd"
IMAGE_STORE="$WORKSPACE/memory/images"
METADATA_STORE="$IMAGE_STORE/metadata.json"

if [ ! -f "$METADATA_STORE" ]; then
    echo "No image metadata found"
    exit 0
fi

NOW=$(date +%s)
EXPIRED_COUNT=0

# Read metadata and check for expired entries
jq -c '.[] | select(.expiry < '"$NOW"' and .reviewed == false)' "$METADATA_STORE" | while read -r entry; do
    EXPIRED_COUNT=$((EXPIRED_COUNT + 1))
    
    ID=$(echo "$entry" | jq -r '.id')
    FILENAME=$(echo "$entry" | jq -r '.filename')
    SUMMARY=$(echo "$entry" | jq -r '.summary')
    TIMESTAMP=$(echo "$entry" | jq -r '.timestamp')
    
    echo "🔔 Image summary expired: $FILENAME"
    echo "📝 Summary: $SUMMARY"
    echo "📅 Created: $(date -d @$TIMESTAMP)"
    echo ""
done

if [ "$EXPIRED_COUNT" -gt 0 ]; then
    echo "Found $EXPIRED_COUNT expired image summaries"
    echo "Review needed: Check $METADATA_STORE"
fi
