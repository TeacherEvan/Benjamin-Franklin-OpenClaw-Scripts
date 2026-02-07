#!/bin/bash
# Image compression and auto-cleanup workflow
# Usage: ./compress-image.sh <image_path>

set -e

IMAGE_PATH="$1"
WORKSPACE="/home/ubuntu/.openclaw/clawd"
IMAGE_STORE="$WORKSPACE/memory/images"
METADATA_STORE="$IMAGE_STORE/metadata.json"

if [ -z "$IMAGE_PATH" ]; then
    echo "Usage: $0 <image_path>"
    exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image not found: $IMAGE_PATH"
    exit 1
fi

# Create image store if needed
mkdir -p "$IMAGE_STORE"

# Generate summary using Gemini
echo "📸 Analyzing image: $IMAGE_PATH" >&2

# Convert image to base64
IMAGE_BASE64=$(base64 -w 0 "$IMAGE_PATH")
MIME_TYPE=$(file --mime-type -b "$IMAGE_PATH")

# Call Gemini Vision API for summary (using stdin to avoid argument list too long)
SUMMARY=$(cat <<EOF | curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}" \
  -H 'Content-Type: application/json' \
  -d @- | jq -r '.candidates[0].content.parts[0].text // "Error: No summary generated"'
{
  "contents": [{
    "parts": [
      {"text": "Provide a detailed, compressed summary of this image. Include: main content, text visible, key details, context, purpose. Keep under 200 words but capture all relevant information."},
      {
        "inline_data": {
          "mime_type": "${MIME_TYPE}",
          "data": "${IMAGE_BASE64}"
        }
      }
    ]
  }]
}
EOF
)

# Create metadata entry
TIMESTAMP=$(date +%s)
EXPIRY=$((TIMESTAMP + 86400)) # 24 hours from now
FILENAME=$(basename "$IMAGE_PATH")
IMAGE_ID=$(echo "$FILENAME" | md5sum | cut -d' ' -f1)

# Save metadata
if [ ! -f "$METADATA_STORE" ]; then
    echo "[]" > "$METADATA_STORE"
fi

# Add new entry
jq --arg id "$IMAGE_ID" \
   --arg path "$IMAGE_PATH" \
   --arg filename "$FILENAME" \
   --arg summary "$SUMMARY" \
   --arg timestamp "$TIMESTAMP" \
   --arg expiry "$EXPIRY" \
   '. += [{
     "id": $id,
     "original_path": $path,
     "filename": $filename,
     "summary": $summary,
     "timestamp": ($timestamp | tonumber),
     "expiry": ($expiry | tonumber),
     "reviewed": false
   }]' "$METADATA_STORE" > "$METADATA_STORE.tmp" && mv "$METADATA_STORE.tmp" "$METADATA_STORE"

# Delete original image
rm "$IMAGE_PATH"

echo "✅ Image compressed and deleted"
echo "📝 Summary: $SUMMARY"
echo "📅 Expiry: $(date -d @$EXPIRY)"
echo "💾 Metadata: $METADATA_STORE"
