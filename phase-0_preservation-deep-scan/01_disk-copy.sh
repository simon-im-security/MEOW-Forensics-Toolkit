#!/bin/bash
# Title: MEOW Forensics Toolkit - Disk Copy Module
# Description: Backs up disk, home folders, specific folders or files using ditto, then compresses and hashes.
# Author: Simon .I
# Version: 2025.04.20r12-persist

# ------------------------------------------------------------
# START
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "[ MEOW Forensics Toolkit ] Module: Disk Copy - START"
echo "------------------------------------------------------------"

# ------------------------------------------------------------
# ROOT CHECK
# ------------------------------------------------------------
if [[ "$(id -u)" -ne 0 ]]; then
  echo "[!] This script must be run as root (use sudo)."
  exit 1
fi

# ------------------------------------------------------------
# SETUP
# ------------------------------------------------------------
SECONDS=0
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
MODULE_NAME="disk-copy"
CONSOLE_USER=$(stat -f%Su /dev/console)
CONSOLE_HOME=$(eval echo "~$CONSOLE_USER")
echo "[*] Detected console user: $CONSOLE_USER"
echo "[*] Home path: $CONSOLE_HOME"

# ------------------------------------------------------------
# BACKUP TYPE SELECTION
# ------------------------------------------------------------
echo
echo "All backups below are created using 'ditto' for file-level copies,"
echo "followed by compression into a .tar.gz archive."
echo
echo "Choose backup type:"
echo "  1) Backup entire root volume"
echo "  2) Backup all home folders under /Users/"
echo "  3) Backup current user home folder only ($CONSOLE_HOME)"
echo "  4) Backup specific folder (recursive)"
echo "  5) Backup single file"
read -p "Enter option [1-5]: " OPTION

if [[ ! "$OPTION" =~ ^[1-5]$ ]]; then
  echo "[!] Invalid option. Exiting."
  exit 1
fi

# ------------------------------------------------------------
# BACKUP PATH PROMPTS (for options 4 and 5)
# ------------------------------------------------------------
if [[ "$OPTION" == "4" ]]; then
  read -p "Enter full path to the folder you want to back up: " FOLDER_PATH
  if [[ ! -d "$FOLDER_PATH" ]]; then
    echo "[!] The specified folder does not exist. Exiting."
    exit 1
  fi
  FOLDER_NAME=$(basename "$FOLDER_PATH")

elif [[ "$OPTION" == "5" ]]; then
  read -p "Enter full path to the file you want to back up: " FILE_PATH
  if [[ ! -f "$FILE_PATH" ]]; then
    echo "[!] File does not exist. Exiting."
    exit 1
  fi
  FILE_NAME=$(basename "$FILE_PATH")
fi

# ------------------------------------------------------------
# OUTPUT LOCATION
# ------------------------------------------------------------
echo
echo "Select output location:"
echo "  1) Default path (/private/var/tmp/meow-forensics-toolkit)"
echo "  2) Custom full path (e.g., /Volumes/USBStick)"
read -p "Enter option [1-2]: " DEST_OPTION

if [[ "$DEST_OPTION" == "2" ]]; then
  read -p "Enter full output path (must already exist): " CUSTOM_PATH
  if [[ ! -d "$CUSTOM_PATH" ]]; then
    echo "[!] Destination path does not exist. Exiting."
    exit 1
  fi
  BASE_OUTPUT="$CUSTOM_PATH/meow-forensics-toolkit/$MODULE_NAME/$TIMESTAMP"
else
  BASE_OUTPUT="/private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$TIMESTAMP"
fi

mkdir -p "$BASE_OUTPUT"
LOG_PATH="$BASE_OUTPUT/backup_log.txt"

# ------------------------------------------------------------
# BACKUP ACTIONS
# ------------------------------------------------------------

if [[ "$OPTION" == "1" ]]; then
  DEST="$BASE_OUTPUT/root_volume_backup"
  echo
  echo "[*] Backing up: / --> $DEST" >> "$LOG_PATH"
  ditto --noqtn "/" "$DEST" >> "$LOG_PATH" 2>&1

elif [[ "$OPTION" == "2" ]]; then
  echo
  echo "[*] Backing up all user home folders..." >> "$LOG_PATH"
  for USER_PATH in /Users/*; do
    USER_NAME=$(basename "$USER_PATH")
    [[ "$USER_NAME" == "Shared" || "$USER_NAME" == "Guest" ]] && continue
    DEST="$BASE_OUTPUT/home_backup_all/$USER_NAME"
    echo "[*] Copying $USER_PATH --> $DEST" >> "$LOG_PATH"
    ditto --noqtn "$USER_PATH" "$DEST" >> "$LOG_PATH" 2>&1
  done

elif [[ "$OPTION" == "3" ]]; then
  DEST="$BASE_OUTPUT/home_backup_console"
  echo
  echo "[*] Backing up: $CONSOLE_HOME --> $DEST" >> "$LOG_PATH"
  ditto --noqtn "$CONSOLE_HOME" "$DEST" >> "$LOG_PATH" 2>&1

elif [[ "$OPTION" == "4" ]]; then
  DEST="$BASE_OUTPUT/custom_folder_backup/$FOLDER_NAME"
  echo
  echo "[*] Backing up: $FOLDER_PATH --> $DEST" >> "$LOG_PATH"
  ditto --noqtn "$FOLDER_PATH" "$DEST" >> "$LOG_PATH" 2>&1

elif [[ "$OPTION" == "5" ]]; then
  DEST_DIR="$BASE_OUTPUT/single_file_backup"
  mkdir -p "$DEST_DIR"
  echo
  echo "[*] Copying $FILE_PATH --> $DEST_DIR/$FILE_NAME" >> "$LOG_PATH"
  cp "$FILE_PATH" "$DEST_DIR/$FILE_NAME" >> "$LOG_PATH" 2>&1
fi

# ------------------------------------------------------------
# ARCHIVE + HASH
# ------------------------------------------------------------
ARCHIVE_NAME="macOS_${MODULE_NAME}_$TIMESTAMP.tar.gz"
ARCHIVE_PARENT="$(dirname "$BASE_OUTPUT")"
tar -czf "$ARCHIVE_PARENT/$ARCHIVE_NAME" -C "$ARCHIVE_PARENT" "$(basename "$BASE_OUTPUT")"

if [[ -f "$ARCHIVE_PARENT/$ARCHIVE_NAME" ]]; then
  HASH=$(shasum -a 256 "$ARCHIVE_PARENT/$ARCHIVE_NAME" | awk '{print $1}')
  echo "Archive saved to: $ARCHIVE_PARENT/$ARCHIVE_NAME"
  echo "SHA256: $HASH"
  echo "SHA256: $HASH" >> "$LOG_PATH"
  [[ "$DEST_OPTION" == "1" ]] && echo "[!] Note: This location persists after reboot. Remember to manually clean it up if needed."
else
  echo "Failed to create archive."
  echo "Failed to create archive." >> "$LOG_PATH"
fi

echo "Operation took $SECONDS seconds"

# ------------------------------------------------------------
# END
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "[ MEOW Forensics Toolkit ] Module: Disk Copy - END"
echo "------------------------------------------------------------"

exit 0
