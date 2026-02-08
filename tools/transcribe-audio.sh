#!/bin/bash
# Transcribe audio using Gemini API
# Usage: ./transcribe-audio.sh <audio_file>
#
# Arguments:
#   audio_file - Path to audio file to transcribe
#
# Environment:
#   GEMINI_API_KEY - Required API key for Gemini service

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

AUDIO_FILE="${1:-}"

# Validate inputs
if [ -z "$AUDIO_FILE" ]; then
    log_error "Usage: $0 <audio_file>"
    exit 1
fi

validate_file_exists "$AUDIO_FILE" "Audio file" || exit 1
validate_env_var "GEMINI_API_KEY" "Gemini API key" || exit 1
validate_api_key "$GEMINI_API_KEY" "Gemini" || exit 1

# Sanitize path
AUDIO_FILE=$(sanitize_path "$AUDIO_FILE")

# Convert audio to base64
AUDIO_BASE64=$(base64 -w 0 "$AUDIO_FILE")

# Detect MIME type
MIME_TYPE=$(file --mime-type -b "$AUDIO_FILE")
if [[ "$MIME_TYPE" == "audio/x-"* ]]; then
    # Generic audio types → use audio/wav or audio/mpeg
    if [[ "$AUDIO_FILE" == *.mp3 ]]; then
        MIME_TYPE="audio/mpeg"
    elif [[ "$AUDIO_FILE" == *.ogg ]]; then
        MIME_TYPE="audio/ogg"
    else
        MIME_TYPE="audio/wav"
    fi
fi

log_info "Transcribing: $AUDIO_FILE"
log_info "MIME type: $MIME_TYPE"

# Call Gemini API
curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}" \
  -H 'Content-Type: application/json' \
  -d "{
    \"contents\": [{
      \"parts\": [
        {\"text\": \"Please transcribe this audio file. Provide the transcription as plain text, without any labels or formatting.\"},
        {
          \"inline_data\": {
            \"mime_type\": \"${MIME_TYPE}\",
            \"data\": \"${AUDIO_BASE64}\"
          }
        }
      ]
    }]
  }" | jq -r '.candidates[0].content.parts[0].text // "Error: No transcription returned"'

exit 0
