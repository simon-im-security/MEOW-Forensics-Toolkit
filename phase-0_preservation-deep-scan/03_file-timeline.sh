#!/bin/bash
# Title: MEOW Forensics Toolkit - File Timeline Module
# Description: Finds recently modified files with timestamps. Supports minute/day filtering. Silent and clean output.
# Author: Simon .I
# Version: 2025.04.20r1-persist

# ------------------------------------------------------------
# ROOT CHECK
# ------------------------------------------------------------
if [[ "$(id -u)" -ne 0 ]]; then
  echo "This script must be run as root (use sudo)."
  exit 1
fi

# ------------------------------------------------------------
# START
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "[ MEOW Forensics Toolkit ] Module: File Timeline - START"
echo "------------------------------------------------------------"

# ------------------------------------------------------------
# SETUP
# ------------------------------------------------------------
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
MODULE_NAME="file-timeline"
OUTPUT_DIR="/private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$TIMESTAMP"
mkdir -p "$OUTPUT_DIR"
ARCHIVE_NAME="macOS_${MODULE_NAME}_$TIMESTAMP.tar.gz"
MATCH_FILE="$OUTPUT_DIR/modified_files.txt"

# ------------------------------------------------------------
# TIME FILTER
# ------------------------------------------------------------
echo "Choose time filter for recently modified files:"
echo "  1) Last 1 minute"
echo "  2) Last 5 minutes"
echo "  3) Last 15 minutes"
echo "  4) Last 60 minutes"
echo "  5) Last 1 day"
echo "  6) Last 7 days"
read -p "Enter option [1-6]: " TIME_OPTION

case "$TIME_OPTION" in
  1) MINS=1 ;;
  2) MINS=5 ;;
  3) MINS=15 ;;
  4) MINS=60 ;;
  5) DAYS=1 ;;
  6) DAYS=7 ;;
  *) echo "Invalid option. Exiting."; exit 1 ;;
esac

# ------------------------------------------------------------
# PATH INPUT
# ------------------------------------------------------------
echo
echo "Scanning the root folder '/' may take a long time."
read -p "Enter base path to search (default is '/'): " SEARCH_PATH
SEARCH_PATH=${SEARCH_PATH:-/}
echo "Scanning path: $SEARCH_PATH"

# ------------------------------------------------------------
# BUILD FIND COMMAND
# ------------------------------------------------------------
if [[ -n "$MINS" ]]; then
  FIND_CMD=(find "$SEARCH_PATH" -type f -mmin "-$MINS")
  echo "Time window: last $MINS minute(s)"
else
  FIND_CMD=(find "$SEARCH_PATH" -type f -mtime "-$DAYS")
  echo "Time window: last $DAYS day(s)"
fi

FIND_CMD+=(
  -not -path "*/Library/Caches/*"
  -not -path "*/private/tmp/*"
  -not -path "*/Volumes/*"
  -not -path "*/System/Volumes/*"
  -not -path "*/.Trash/*"
)

# ------------------------------------------------------------
# FILE SCAN
# ------------------------------------------------------------
echo "Scanning for modified files..."
FILE_COUNT=0
while IFS= read -r file; do
  ((FILE_COUNT++))
  MOD_TIME=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null)
  echo "$MOD_TIME | $file" >> "$MATCH_FILE"
done < <("${FIND_CMD[@]}" 2>/dev/null)

echo "Matched files: $FILE_COUNT"

# ------------------------------------------------------------
# ARCHIVE
# ------------------------------------------------------------
tar -czf "/private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$ARCHIVE_NAME" -C "$OUTPUT_DIR" .

echo
echo "Results saved:"
echo " - $MATCH_FILE"
echo " - Archive: /private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$ARCHIVE_NAME"
echo "[!] Note: This location persists after reboot. Remember to manually clean it up if needed."

# ------------------------------------------------------------
# END
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "[ MEOW Forensics Toolkit ] Module: File Timeline - END"
echo "------------------------------------------------------------"

exit 0
