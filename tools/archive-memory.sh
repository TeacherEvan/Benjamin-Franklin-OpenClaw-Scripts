#!/bin/bash
# Archive old memory files (>7 days) to memory/archive/YYYY-MM/
# Usage: ./archive-memory.sh

WORKSPACE="/home/ubuntu/.openclaw/clawd"
MEMORY_DIR="$WORKSPACE/memory"
ARCHIVE_BASE="$MEMORY_DIR/archive"

DAYS_OLD=7
TODAY=$(date +%s)
ARCHIVED_COUNT=0

echo "📦 Memory Archive System"
echo "Archive files older than $DAYS_OLD days"
echo ""

# Find daily memory files
for file in "$MEMORY_DIR"/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
  [ -f "$file" ] || continue
  
  # Extract date from filename
  filename=$(basename "$file")
  file_date=$(date -d "${filename%.md}" +%s 2>/dev/null)
  
  if [ -z "$file_date" ]; then
    continue
  fi
  
  # Calculate age in days
  age_seconds=$((TODAY - file_date))
  age_days=$((age_seconds / 86400))
  
  if [ $age_days -gt $DAYS_OLD ]; then
    # Extract year-month for archive directory
    year_month=$(echo "$filename" | cut -d'-' -f1,2)
    archive_dir="$ARCHIVE_BASE/$year_month"
    
    # Create archive directory if needed
    mkdir -p "$archive_dir"
    
    # Move file
    mv "$file" "$archive_dir/"
    echo "✅ Archived: $filename ($age_days days old) → archive/$year_month/"
    ARCHIVED_COUNT=$((ARCHIVED_COUNT + 1))
  fi
done

echo ""
if [ $ARCHIVED_COUNT -eq 0 ]; then
  echo "ℹ️  No files to archive (all < $DAYS_OLD days old)"
else
  echo "📊 Archived $ARCHIVED_COUNT file(s)"
fi
