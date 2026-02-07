#!/bin/bash
# Transcribe audio using Gemini API
# Usage: ./transcribe-audio.sh <audio_file>

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <audio_file>"
    exit 1
fi

AUDIO_FILE="$1"
API_KEY="${GEMINI_API_KEY}"

if [ -z "$API_KEY" ]; then
    echo "Error: GEMINI_API_KEY not set"
    exit 1
fi

if [ ! -f "$AUDIO_FILE" ]; then
    echo "Error: File not found: $AUDIO_FILE"
    exit 1
fi

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

echo "📝 Transcribing: $AUDIO_FILE" >&2
echo "🎵 MIME type: $MIME_TYPE" >&2

# Call Gemini API
curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${API_KEY}" \
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
