#!/bin/bash
# Archive old memory files (>7 days) to memory/archive/YYYY-MM/
# Usage: ./archive-memory.sh [days_old]
#
# Arguments:
#   days_old - Number of days before archiving (default: 7)
#
# Environment:
#   OPENCLAW_WORKSPACE - Override default workspace path

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

ARCHIVE_BASE="$MEMORY_DIR/archive"
DAYS_OLD="${1:-7}"
TODAY=$(date +%s)
ARCHIVED_COUNT=0

log_info "Memory Archive System"
log_info "Archive files older than $DAYS_OLD days"
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
    ensure_dir "$archive_dir" || continue
    
    # Move file
    mv "$file" "$archive_dir/"
    log_success "Archived: $filename ($age_days days old) → archive/$year_month/"
    ARCHIVED_COUNT=$((ARCHIVED_COUNT + 1))
  fi
done

echo ""
if [ $ARCHIVED_COUNT -eq 0 ]; then
  log_info "No files to archive (all < $DAYS_OLD days old)"
else
  log_success "Archived $ARCHIVED_COUNT file(s)"
fi

exit 0
