#!/bin/bash
# Title: MEOW Forensics Toolkit - Keyword Search Module
# Description: Searches the entire system or a specific path for suspicious keywords in text-based files. Outputs a single consolidated match report and hit path list.
# Author: Simon .I
# Version: 2025.04.20r4-menu-clean

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
echo "[ MEOW Forensics Toolkit ] Module: Keyword Search - START"
echo "------------------------------------------------------------"

# ------------------------------------------------------------
# SETUP VARIABLES
# ------------------------------------------------------------
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
OUTPUT_DIR="/private/var/tmp/meow-forensics-toolkit/keyword-search/$TIMESTAMP"
PARENT_DIR="$(dirname "$OUTPUT_DIR")"
ARCHIVE_NAME="macOS_keyword_hits_$TIMESTAMP.tar.gz"
mkdir -p "$OUTPUT_DIR"

# ------------------------------------------------------------
# GET KEYWORDS FROM USER
# ------------------------------------------------------------
echo
read -p "Enter comma-separated keywords to search (e.g., smb,python,ftp): " INPUT_KEYWORDS
if [[ -z "$INPUT_KEYWORDS" ]]; then
  echo "[!] No keywords entered. Exiting."
  exit 1
fi

IFS=',' read -r -a KEYWORDS <<< "$INPUT_KEYWORDS"
PATTERN=$(IFS="|"; echo "${KEYWORDS[*]}")
echo "Keywords pattern: $PATTERN"

# ------------------------------------------------------------
# SELECT SEARCH LOCATION
# ------------------------------------------------------------
echo
echo "Choose where to search:"
echo "  1) Entire system (/)"
echo "  2) Specific folder (recursive)"
read -p "Enter option [1-2]: " LOCATION_OPTION

if [[ "$LOCATION_OPTION" == "1" ]]; then
  SEARCH_ROOT="/"
elif [[ "$LOCATION_OPTION" == "2" ]]; then
  read -p "Enter full path to folder to search: " SEARCH_ROOT
  if [[ ! -d "$SEARCH_ROOT" ]]; then
    echo "[!] Path does not exist. Exiting."
    exit 1
  fi
else
  echo "[!] Invalid option. Exiting."
  exit 1
fi

echo
echo "[*] Scanning path: $SEARCH_ROOT"
echo "[*] Output will be saved to: $OUTPUT_DIR"
echo

# ------------------------------------------------------------
# SEARCH FILESYSTEM FOR MATCHES
# ------------------------------------------------------------
find "$SEARCH_ROOT" \
  -type f -size -5M \
  -not -path "*/Library/Caches/*" \
  -not -path "*/private/tmp/*" \
  -not -path "*/Volumes/*" \
  -not -path "*/System/Volumes/*" \
  -not -path "*/.Trash/*" \
  2>/dev/null | while read -r file; do

  if file "$file" | grep -qE 'text'; then
    MATCHES=$(grep -iE "$PATTERN" "$file" 2>/dev/null)
    if [[ -n "$MATCHES" ]]; then
      FILEHASH="$(shasum -a 256 "$file" | awk '{print $1}')"

      {
        echo "=== FILE: $file ==="
        echo "SHA256: $FILEHASH"
        echo "$MATCHES" | sed 's/^/  > /'
        echo
      } >> "$OUTPUT_DIR/keyword_matches.txt"
    fi
  fi

done

# ------------------------------------------------------------
# CREATE COMPRESSED ARCHIVE
# ------------------------------------------------------------
echo
echo "Creating compressed archive: $ARCHIVE_NAME"
tar -czf "$PARENT_DIR/$ARCHIVE_NAME" -C "$OUTPUT_DIR" .

# ------------------------------------------------------------
# END
# ------------------------------------------------------------
echo
echo "Keyword search complete."
echo "Match report: $OUTPUT_DIR/keyword_matches.txt"
echo "Compressed archive saved to: $PARENT_DIR/$ARCHIVE_NAME"
echo "[!] Note: This location persists after reboot. Remember to manually clean it up if needed."

echo "------------------------------------------------------------"
echo "[ MEOW Forensics Toolkit ] Module: Keyword Search - END"
echo "------------------------------------------------------------"
