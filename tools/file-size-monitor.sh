#!/bin/bash
# File Size Monitor - Detects files exceeding configurable line limit
# Usage: ./file-size-monitor.sh [--auto-split] [limit]
#
# Arguments:
#   --auto-split - Enable automatic split proposals (optional)
#   limit - Line limit (default: 250)
#
# Environment:
#   OPENCLAW_WORKSPACE - Override default workspace path

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

LIMIT=200
AUTO_SPLIT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --auto-split)
      AUTO_SPLIT=true
      shift
      ;;
    [0-9]*)
      LIMIT="$1"
      shift
      ;;
    *)
      log_error "Unknown argument: $1"
      log_info "Usage: $0 [--auto-split] [limit]"
      exit 1
      ;;
  esac
done

echo "📏 File Size Monitor - $(date '+%Y-%m-%d %H:%M')"
echo "Workspace: $WORKSPACE"
echo "Limit: $LIMIT lines"
echo ""

VIOLATIONS=0
TOTAL_EXCESS=0

while IFS= read -r file; do
  lines=$(wc -l < "$file" 2>/dev/null || echo 0)
  
  if [ $lines -gt $LIMIT ]; then
    over=$((lines - LIMIT))
    VIOLATIONS=$((VIOLATIONS + 1))
    TOTAL_EXCESS=$((TOTAL_EXCESS + over))
    
    rel_path="${file#$WORKSPACE/}"
    echo "⚠️  $rel_path"
    echo "   Lines: $lines (+$over over limit)"
    
    # Suggest split strategy based on file type
    case "$file" in
      *.md)
        echo "   💡 Strategy: Split by H2 headers (##)"
        if [ "$AUTO_SPLIT" = true ]; then
          echo "   🔧 Auto-split: Creating proposal..."
          # TODO: Implement auto-split logic
        fi
        ;;
      *.js)
        echo "   💡 Strategy: Extract functions into modules"
        ;;
      *.sh)
        echo "   💡 Strategy: Source shared functions from lib/"
        ;;
    esac
    echo ""
  fi
done < <(find "$WORKSPACE" -type f \( -name "*.sh" -o -name "*.js" -o -name "*.md" \) \
  ! -path "*/.venv-mcp/*" \
  ! -path "*/node_modules/*" \
  ! -path "*/archive/*" \
  ! -path "*/.git/*")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $VIOLATIONS -eq 0 ]; then
  log_success "All files within $LIMIT line limit!"
  exit 0
else
  log_info "Summary:"
  log_info "  Files exceeding limit: $VIOLATIONS"
  log_info "  Total excess lines: $TOTAL_EXCESS"
  log_info "  Average overage: $((TOTAL_EXCESS / VIOLATIONS)) lines/file"
  # Exit with 1 to indicate violations found (avoid exceeding max exit code 255)
  exit 1
fi
