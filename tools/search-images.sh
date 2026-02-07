#!/bin/bash
# Search compressed images by content
# Usage: ./search-images.sh "query"

QUERY="$1"
METADATA="/home/ubuntu/.openclaw/clawd/memory/images/metadata.json"

if [ -z "$QUERY" ]; then
    echo "Usage: $0 '<search query>'"
    exit 1
fi

echo "🔍 Searching images for: $QUERY"
echo ""

jq -r --arg query "$QUERY" '.[] | select(.summary | ascii_downcase | contains($query | ascii_downcase)) | "📸 \(.filename)\n📅 \(.timestamp | strftime("%Y-%m-%d %H:%M"))\n📝 \(.summary)\n---"' "$METADATA"
