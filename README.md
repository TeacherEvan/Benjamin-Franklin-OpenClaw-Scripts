# Benjamin Franklin OpenClaw Scripts

Scripts created for OpenClaw automation and maintenance.

## Contents
- `tools/` — helper scripts and tooling
- `tools/memcompress/` — modular memory compression engine
- `tools/lib/` — shared utility functions and constants

## Environment Variables

Most scripts support the following environment variables:

- `OPENCLAW_WORKSPACE` - Override default workspace path (default: `/home/ubuntu/.openclaw/clawd`)
- `GEMINI_API_KEY` - Required for image compression and audio transcription
- `ASSEMBLYAI_API_KEY` - Required for `transcribe.js` (alternative to config file)

## Notable Scripts

### Memory Management
- **`archive-memory.sh`** — Archive daily memory logs older than specified days (default: 7)
  ```bash
  ./archive-memory.sh [days_old]
  ```

- **`file-size-monitor.sh`** — Report files exceeding line limit
  ```bash
  ./file-size-monitor.sh [--auto-split] [limit]
  ```

### Memory Compression
- **`memcompress-modular.js`** — Modular memory compression CLI (recommended)
  ```bash
  node memcompress-modular.js
  ```

### Image Management
- **`compress-image.sh`** — Compress image to summary with metadata
  ```bash
  GEMINI_API_KEY=your-key ./compress-image.sh <image_path>
  ```

- **`check-expired-images.sh`** — Purge expired image summaries
  ```bash
  ./check-expired-images.sh
  ```

- **`image-stats.sh`** — Image compression dashboard
  ```bash
  ./image-stats.sh
  ```

- **`search-images.sh`** — Search images by content
  ```bash
  ./search-images.sh "search query"
  ```

- **`recent-images-context.sh`** — Show recent image summaries
  ```bash
  ./recent-images-context.sh [hours]
  ```

### Audio Transcription
- **`transcribe-audio.sh`** — Transcribe audio using Gemini API
  ```bash
  GEMINI_API_KEY=your-key ./transcribe-audio.sh <audio_file>
  ```

- **`transcribe.js`** — Advanced transcription using AssemblyAI
  ```bash
  node transcribe.js <audio_file>
  ```
  See file header for setup instructions.

## Development

### Code Quality Standards
- Maximum 200 lines per file
- Shared utilities in `tools/lib/common.sh`
- Comprehensive error handling
- Input validation for all user inputs
- JSDoc comments for all JavaScript functions
- Usage documentation in file headers

### Security Best Practices
- API key validation before use
- Path sanitization to prevent directory traversal
- Environment variable validation
- Proper exit codes for error conditions

## Architecture

The codebase follows a modular architecture:
- **Shell scripts** use shared `lib/common.sh` for consistency
- **JavaScript modules** are properly documented with JSDoc
- **Compression engine** is split into focused, reusable modules

