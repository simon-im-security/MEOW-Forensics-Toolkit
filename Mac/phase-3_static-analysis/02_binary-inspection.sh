#!/bin/bash
# Title: MEOW Forensics Toolkit - Binary Inspection Module
# Description: Performs static analysis on binaries without execution. Outputs include SHA256, file info, codesign, otool, nm, strings, and vtool.
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
echo "[ MEOW Forensics Toolkit ] Module: Binary Inspection - START"
echo "------------------------------------------------------------"

# ------------------------------------------------------------
# SETUP
# ------------------------------------------------------------
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
MODULE_NAME="binary-inspection"
OUTPUT_DIR="/private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$TIMESTAMP"
mkdir -p "$OUTPUT_DIR"

# ------------------------------------------------------------
# PROMPT FOR INPUT PATH
# ------------------------------------------------------------
read -p "Enter path to a binary or directory to scan recursively: " TARGET_PATH
if [[ ! -e "$TARGET_PATH" ]]; then
  echo "Target does not exist. Exiting."
  exit 1
fi

# ------------------------------------------------------------
# SCAN TARGETS
# ------------------------------------------------------------
get_binaries() {
  local path="$1"
  if [[ -f "$path" ]]; then
    file "$path" | grep -q "Mach-O" && echo "$path"
  elif [[ -d "$path" ]]; then
    find "$path" -type f -exec file {} \; | grep "Mach-O" | cut -d: -f1
  fi
}

analyze_binary() {
  local binary="$1"
  local bname
  bname=$(basename "$binary")
  local bdir="$OUTPUT_DIR/$bname"
  mkdir -p "$bdir"

  local sha256
  sha256=$(shasum -a 256 "$binary" | awk '{print $1}')
  echo "SHA256: $sha256" > "$bdir/sha256.txt"

  echo "# Output of 'file'" > "$bdir/file.txt"
  file "$binary" >> "$bdir/file.txt"

  echo "# Output of 'codesign -dvvv'" > "$bdir/codesign.txt"
  codesign -dvvv "$binary" >> "$bdir/codesign.txt" 2>&1

  echo "# Output of 'otool -L'" > "$bdir/otool.txt"
  otool -L "$binary" >> "$bdir/otool.txt" 2>&1

  echo "# Output of 'nm -g'" > "$bdir/nm.txt"
  nm -g "$binary" >> "$bdir/nm.txt" 2>&1

  echo "# Output of 'strings'" > "$bdir/strings.txt"
  strings "$binary" >> "$bdir/strings.txt"

  if command -v vtool &>/dev/null; then
    echo "# Output of 'vtool -show'" > "$bdir/vtool.txt"
    vtool -show "$binary" >> "$bdir/vtool.txt" 2>&1
  fi
}

# ------------------------------------------------------------
# PROCESS
# ------------------------------------------------------------
BINARIES=$(get_binaries "$TARGET_PATH")

if [[ -z "$BINARIES" ]]; then
  echo "No Mach-O binaries found."
  echo "------------------------------------------------------------"
  echo "[ MEOW Forensics Toolkit ] Module: Binary Inspection - END"
  echo "------------------------------------------------------------"
  exit 0
fi

for bin in $BINARIES; do
  echo "Analyzing: $bin"
  analyze_binary "$bin"
done

# ------------------------------------------------------------
# ARCHIVE
# ------------------------------------------------------------
ARCHIVE_NAME="macOS_${MODULE_NAME}_$TIMESTAMP.tar.gz"
tar -czf "$OUTPUT_DIR/../$ARCHIVE_NAME" -C "$OUTPUT_DIR" .

# ------------------------------------------------------------
# FINAL MESSAGE
# ------------------------------------------------------------
cat <<EOF

Static binary analysis complete.
Results saved to: $OUTPUT_DIR
Archive saved to: /private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$ARCHIVE_NAME
[!] Note: This location persists after reboot. Remember to manually clean it up if needed.
EOF

# ------------------------------------------------------------
# END
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "[ MEOW Forensics Toolkit ] Module: Binary Inspection - END"
echo "------------------------------------------------------------"

exit 0
