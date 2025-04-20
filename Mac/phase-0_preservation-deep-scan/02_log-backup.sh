#!/bin/bash
# Title: MEOW Forensics Toolkit - Log Backup Module
# Description: Backs up all macOS system, global, and user logs into a standardised output directory, then compresses them outside the directory.
# Author: Simon .I
# Version: 2025.04.20r1-persist

# ------------------------------------------------------------
# CHECK FOR ROOT PRIVILEGES
# ------------------------------------------------------------
if [[ "$(id -u)" -ne 0 ]]; then
  echo "This script must be run as root (use sudo)."
  exit 1
fi

# ------------------------------------------------------------
# START
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "[ MEOW Forensics Toolkit ] Module: Log Backup - START"
echo "------------------------------------------------------------"

# ------------------------------------------------------------
# VARIABLES AND SETUP
# ------------------------------------------------------------
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
OUTPUT_DIR="/private/var/tmp/meow-forensics-toolkit/log-backup/$TIMESTAMP"
PARENT_DIR="$(dirname "$OUTPUT_DIR")"
ARCHIVE_NAME="macOS_logs_backup_$TIMESTAMP.tar.gz"

# ------------------------------------------------------------
# DETECT CONSOLE USER & HOME PATH
# ------------------------------------------------------------
CONSOLE_USER=$(stat -f%Su /dev/console)
CONSOLE_HOME=$(eval echo "~$CONSOLE_USER")

echo "Output directory: $OUTPUT_DIR"
echo "Detected console user: $CONSOLE_USER"
echo "Resolved home path: $CONSOLE_HOME"
mkdir -p "$OUTPUT_DIR"

# ------------------------------------------------------------
# COPY SYSTEM LOGS (/var/log)
# ------------------------------------------------------------
echo "Copying system logs from /var/log..."
cp -R /var/log "$OUTPUT_DIR/system_logs" 2>/dev/null

# ------------------------------------------------------------
# COPY GLOBAL LIBRARY LOGS (/Library/Logs)
# ------------------------------------------------------------
echo "Copying global logs from /Library/Logs..."
cp -R /Library/Logs "$OUTPUT_DIR/global_logs" 2>/dev/null

# ------------------------------------------------------------
# COPY USER LIBRARY LOGS
# ------------------------------------------------------------
echo "Copying user logs from $CONSOLE_HOME/Library/Logs..."
cp -R "$CONSOLE_HOME/Library/Logs" "$OUTPUT_DIR/user_logs" 2>/dev/null

# ------------------------------------------------------------
# COLLECT COMPLETE UNIFIED SYSTEM LOGS
# ------------------------------------------------------------
echo "Collecting full unified system logs..."
log collect --output "$OUTPUT_DIR/unified_log_full.logarchive"

# ------------------------------------------------------------
# CREATE COMPRESSED ARCHIVE IN PARENT FOLDER
# ------------------------------------------------------------
echo "Creating compressed archive: $ARCHIVE_NAME"
tar -czf "$PARENT_DIR/$ARCHIVE_NAME" -C "$OUTPUT_DIR" .

# ------------------------------------------------------------
# END
# ------------------------------------------------------------
echo "Log backup complete."
echo "All logs saved under: $OUTPUT_DIR"
echo "Compressed archive saved to: $PARENT_DIR/$ARCHIVE_NAME"
echo "[!] Note: This location persists after reboot. Remember to manually clean it up if needed."

echo "------------------------------------------------------------"
echo "[ MEOW Forensics Toolkit ] Module: Log Backup - END"
echo "------------------------------------------------------------"
