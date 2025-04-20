#!/bin/bash
# Title: MEOW Forensics Toolkit - Browser History Collector
# Description: Collects browser history DBs including WAL/SHM files from Chromium browsers. Logs paths and metadata. Archives output.
# Author: Simon .I
# Version: 2025.04.20r1-persist

# ------------------------------------------------------------
# CHECK ROOT
# ------------------------------------------------------------
if [[ "$(id -u)" -ne 0 ]]; then
  echo "This script must be run as root (use sudo)."
  exit 1
fi

# ------------------------------------------------------------
# START
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "[ MEOW Forensics Toolkit ] Module: Browser History - START"
echo "------------------------------------------------------------"

# ------------------------------------------------------------
# SETUP
# ------------------------------------------------------------
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
MODULE_NAME="browser-history"
OUTPUT_DIR="/private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$TIMESTAMP"
ARCHIVE_NAME="macOS_${MODULE_NAME}_$TIMESTAMP.tar.gz"
SUMMARY_FILE="$OUTPUT_DIR/discovery_summary.txt"
mkdir -p "$OUTPUT_DIR"

EXCLUDED_USERS="Shared Guest"

CHROME_PATH="Library/Application Support/Google/Chrome"
EDGE_PATH="Library/Application Support/Microsoft Edge"
BRAVE_PATH="Library/Application Support/BraveSoftware/Brave-Browser"
ISLAND_PATH="Library/Application Support/Island"
FIREFOX_PATH="Library/Application Support/Firefox/Profiles"
SAFARI_DB="Library/Safari/History.db"

FOUND_HISTORY_DBS=()

# ------------------------------------------------------------
# METADATA LOGGING
# ------------------------------------------------------------
log_file_metadata() {
  local src="$1"
  local label="$2"
  local file_size=$(stat -f%z "$src" 2>/dev/null)
  local size_hr=$(du -sh "$src" 2>/dev/null | awk '{print $1}')
  local mod_epoch=$(stat -f "%m" "$src" 2>/dev/null)
  local mod_date=$(date -r "$mod_epoch" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)

  FOUND_HISTORY_DBS+=("$label
  Path     : $src
  Size     : $size_hr ($file_size bytes)
  Modified : $mod_date")
}

# ------------------------------------------------------------
# CHROMIUM HISTORY
# ------------------------------------------------------------
process_chromium_history() {
  local base_path="$1"
  local browser="$2"
  local user="$3"
  local profile="$4"
  local dest_dir="$OUTPUT_DIR/$user/$browser/$profile"

  mkdir -p "$dest_dir"

  for suffix in "" "-wal" "-shm"; do
    local src="$base_path/History$suffix"
    local dest="$dest_dir/History$suffix"
    if [[ -f "$src" ]]; then
      cp "$src" "$dest"
      echo "$dest" >> "$SUMMARY_FILE"
      log_file_metadata "$src" "$user | $browser | $profile | History$suffix"
    fi
  done
}

# ------------------------------------------------------------
# NON-CHROMIUM HISTORY
# ------------------------------------------------------------
copy_history_file() {
  local src="$1"
  local browser="$2"
  local user="$3"
  local profile="$4"
  local dest="$OUTPUT_DIR/$user/$browser/$profile/$(basename "$src")"

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "$dest" >> "$SUMMARY_FILE"
  log_file_metadata "$src" "$user | $browser | $profile | $(basename "$src")"
}

# ------------------------------------------------------------
# MAIN USER LOOP
# ------------------------------------------------------------
for user_dir in /Users/*; do
  user=$(basename "$user_dir")
  [[ ! -d "$user_dir" || "$user" == _* ]] && continue
  echo "$EXCLUDED_USERS" | grep -qw "$user" && continue

  # Chrome
  for profile in "$user_dir/$CHROME_PATH"/*; do
    [[ -f "$profile/History" ]] || continue
    process_chromium_history "$profile" "Chrome" "$user" "$(basename "$profile")"
  done

  # Edge
  for profile in "$user_dir/$EDGE_PATH"/*; do
    [[ -f "$profile/History" ]] || continue
    process_chromium_history "$profile" "Edge" "$user" "$(basename "$profile")"
  done

  # Brave
  for profile in "$user_dir/$BRAVE_PATH"/*; do
    [[ -f "$profile/History" ]] || continue
    process_chromium_history "$profile" "Brave" "$user" "$(basename "$profile")"
  done

  # Island
  for profile in "$user_dir/$ISLAND_PATH"/*; do
    [[ -f "$profile/History" ]] || continue
    process_chromium_history "$profile" "Island" "$user" "$(basename "$profile")"
  done

  # Firefox
  for profile in "$user_dir/$FIREFOX_PATH"/*.default*; do
    [[ -f "$profile/places.sqlite" ]] || continue
    copy_history_file "$profile/places.sqlite" "Firefox" "$user" "$(basename "$profile")"
  done

  # Safari
  safari_path="$user_dir/$SAFARI_DB"
  if [[ -f "$safari_path" ]]; then
    copy_history_file "$safari_path" "Safari" "$user" "N/A"
  fi
done

# ------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------
{
  echo "============================================================"
  echo " BROWSER HISTORY DATABASES FOUND"
  echo "============================================================"
  for entry in "${FOUND_HISTORY_DBS[@]}"; do
    echo "$entry"
    echo "------------------------------------------------------------"
  done
} | tee "$SUMMARY_FILE"

# ------------------------------------------------------------
# ARCHIVE
# ------------------------------------------------------------
ARCHIVE_PATH="/private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$ARCHIVE_NAME"
tar -czf "$ARCHIVE_PATH" -C "$OUTPUT_DIR" .

# ------------------------------------------------------------
# END
# ------------------------------------------------------------
cat <<EOF

All copied files saved under: $OUTPUT_DIR
Summary saved to: $SUMMARY_FILE
Archive saved to: $ARCHIVE_PATH
[!] Note: This location persists after reboot. Remember to manually clean it up if needed.

To open and view browser history database files, you may need to manually move them to a folder like your Desktop.
This avoids macOS sandboxing issues that may restrict access or lock files copied by root.

Browser history collection complete.
EOF

echo "------------------------------------------------------------"
echo "[ MEOW Forensics Toolkit ] Module: Browser History - END"
echo "------------------------------------------------------------"

exit 0
