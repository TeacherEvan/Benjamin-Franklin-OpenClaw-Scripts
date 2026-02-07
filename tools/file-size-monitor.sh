#!/bin/bash
# File Size Monitor - Detects files exceeding 250 lines
# Usage: ./file-size-monitor.sh [--auto-split]

WORKSPACE="/home/ubuntu/.openclaw/clawd"
LIMIT=250
AUTO_SPLIT=false

if [ "$1" = "--auto-split" ]; then
  AUTO_SPLIT=true
fi

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
  echo "✅ All files within $LIMIT line limit!"
else
  echo "📊 Summary:"
  echo "   Files exceeding limit: $VIOLATIONS"
  echo "   Total excess lines: $TOTAL_EXCESS"
  echo "   Average overage: $((TOTAL_EXCESS / VIOLATIONS)) lines/file"
fi

exit $VIOLATIONS
