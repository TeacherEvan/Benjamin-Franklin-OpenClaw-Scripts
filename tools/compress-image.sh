#!/bin/bash
# Image compression and auto-cleanup workflow
# Usage: ./compress-image.sh <image_path>
#
# Arguments:
#   image_path - Path to image file to compress
#
# Environment:
#   OPENCLAW_WORKSPACE - Override default workspace path
#   GEMINI_API_KEY - Required for image analysis

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

IMAGE_PATH="${1:-}"

# Validate inputs
if [ -z "${IMAGE_PATH:-}" ]; then
    log_error "Usage: $0 <image_path>"
    exit 1
fi

validate_file_exists "$IMAGE_PATH" "Image" || exit 1
validate_env_var "GEMINI_API_KEY" "Gemini API key" || exit 1
validate_api_key "$GEMINI_API_KEY" "Gemini" || exit 1

# Sanitize path
IMAGE_PATH=$(sanitize_path "$IMAGE_PATH")

# Create image store if needed
ensure_dir "$IMAGE_STORE" || exit 1

# Generate summary using Gemini
log_info "Analyzing image: $IMAGE_PATH"

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

log_success "Image compressed and deleted"
log_info "Summary: $SUMMARY"
log_info "Expiry: $(date -d @$EXPIRY)"
log_info "Metadata: $METADATA_STORE"

exit 0
