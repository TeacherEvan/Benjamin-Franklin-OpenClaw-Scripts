#!/bin/bash
# Image compression stats

METADATA="/home/ubuntu/.openclaw/clawd/memory/images/metadata.json"

echo "📊 Image Compression Stats"
echo ""
echo "Total images tracked: $(jq 'length' "$METADATA")"
echo "Reviewed: $(jq '[.[] | select(.reviewed == true)] | length' "$METADATA")"
echo "Pending review: $(jq '[.[] | select(.reviewed == false)] | length' "$METADATA")"
echo ""
echo "Storage saved: $(du -sh /home/ubuntu/.openclaw/media/inbound 2>/dev/null | cut -f1) (original images deleted)"
echo ""
echo "Oldest: $(jq -r '.[] | .timestamp' "$METADATA" | sort -n | head -1 | xargs -I {} date -d @{} '+%Y-%m-%d %H:%M')"
echo "Newest: $(jq -r '.[] | .timestamp' "$METADATA" | sort -n | tail -1 | xargs -I {} date -d @{} '+%Y-%m-%d %H:%M')"
echo ""
echo "Expired (>24h): $(jq --arg now "$(date +%s)" '[.[] | select(.expiry < ($now | tonumber))] | length' "$METADATA")"
