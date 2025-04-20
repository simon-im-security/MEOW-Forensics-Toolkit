#!/bin/bash
# Title: MEOW Forensics Toolkit - Process Memory Dump Module
# Description: Monitors for a user-specified process name and captures a memory-only snapshot using LLDB when it appears. Optionally disassembles the binary with otool. Also captures NVRAM.
# Author: Simon .I
# Version: 2025.04.20r2-persist

# ------------------------------------------------------------
# START
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "[ MEOW Forensics Toolkit ] Module: Process Memory Dump - START"
echo "------------------------------------------------------------"
echo "[*] This module captures a snapshot of a specific process's memory"
echo "[*] using LLDB. It does NOT capture full RAM. Useful for examining"
echo "[*] user-space memory of a known or suspicious process."
echo

# ------------------------------------------------------------
# SIP CHECK (Hard Requirement)
# ------------------------------------------------------------
SIP_STATUS=$(csrutil status 2>/dev/null)

if echo "$SIP_STATUS" | grep -q "enabled"; then
  echo "[!] System Integrity Protection (SIP) is ENABLED."
  echo "[!] This module requires SIP to be fully disabled."
  echo
  echo "To proceed:"
  echo "1. Reboot into macOS Recovery Mode."
  echo "2. Open Terminal from the Utilities menu."
  echo "3. Run the command: csrutil disable"
  echo "4. Enter your administrator password when prompted."
  echo "5. Reboot normally and rerun this module."
  exit 1
else
  echo "[*] SIP is disabled. Proceeding..."
fi

# ------------------------------------------------------------
# CHECK FOR ROOT PRIVILEGES
# ------------------------------------------------------------
if [[ "$(id -u)" -ne 0 ]]; then
  echo "[!] This script must be run as root (use sudo)."
  exit 1
fi

# ------------------------------------------------------------
# PROMPT FOR TARGET PROCESS AND DUMP MODE
# ------------------------------------------------------------
echo
read -p "Enter exact name of the process to monitor (case-sensitive): " TARGET_NAME

if [[ -z "$TARGET_NAME" ]]; then
  echo "[!] No process name entered. Exiting."
  exit 1
fi

echo
echo "Choose when to dump memory:"
echo "  1) Dump immediately once process appears"
echo "  2) Wait until you press Ctrl+C, then dump"
read -p "Enter choice [1-2]: " DUMP_MODE

if [[ "$DUMP_MODE" != "1" && "$DUMP_MODE" != "2" ]]; then
  echo "[!] Invalid choice. Must be 1 or 2. Exiting."
  exit 1
fi

read -p "Also run otool disassembly after memory dump? (y/n): " DO_OTOOL

# ------------------------------------------------------------
# SETUP OUTPUT PATH AND CLEANUP HANDLER
# ------------------------------------------------------------
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
MODULE_NAME="process-memory-dump"
OUTPUT_DIR="/private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$TIMESTAMP"
mkdir -p "$OUTPUT_DIR"
ARCHIVE_NAME="macOS_${MODULE_NAME}_$TIMESTAMP.tar.gz"
CORE_PATH="$OUTPUT_DIR/${TARGET_NAME}_PID.core"
LOG_PATH="$OUTPUT_DIR/${TARGET_NAME}_lldb.log"
OTOOL_LOG="$OUTPUT_DIR/${TARGET_NAME}_otool.txt"
NVRAM_LOG="$OUTPUT_DIR/nvram_dump.txt"

cleanup() {
  echo "[*] Capturing NVRAM snapshot..."
  nvram -p > "$NVRAM_LOG"
  echo "✔ NVRAM dump saved: $NVRAM_LOG"

  echo "[*] Creating archive with collected artefacts..."
  tar -czf "/private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$ARCHIVE_NAME" -C "$OUTPUT_DIR" .
  echo "✔ Archive saved: /private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$ARCHIVE_NAME"
  echo "[!] Note: This location persists after reboot. Remember to manually clean it up if needed."
  echo "------------------------------------------------------------"
  echo "[ MEOW Forensics Toolkit ] Module: Process Memory Dump - END"
  echo "------------------------------------------------------------"
  exit 0
}

# ------------------------------------------------------------
# MONITOR FOR TARGET PROCESS
# ------------------------------------------------------------
echo
echo "[*] Monitoring for process: $TARGET_NAME to appear..."
while true; do
  PID=$(pgrep -x "$TARGET_NAME")
  if [[ -n "$PID" ]]; then
    echo "[+] Process detected: $TARGET_NAME (PID: $PID)"
    echo "[*] Preparing to dump process memory..."
    break
  fi
  sleep 1
done

# Update paths with actual PID
CORE_PATH="$OUTPUT_DIR/${TARGET_NAME}_${PID}.core"
LOG_PATH="$OUTPUT_DIR/${TARGET_NAME}_${PID}_lldb.log"
OTOOL_LOG="$OUTPUT_DIR/${TARGET_NAME}_${PID}_otool.txt"
BINARY_PATH=$(ps -p "$PID" -o comm=)

# ------------------------------------------------------------
# MEMORY DUMP HANDLING
# ------------------------------------------------------------
if [[ "$DUMP_MODE" == "2" ]]; then
  echo "[*] Waiting for Ctrl+C to dump memory..."
  dump_and_exit() {
    echo
    echo "[*] Capturing memory dump..."
    lldb -p $PID -o "process save-core \"$CORE_PATH\"" -o "detach" -o "quit" &> "$LOG_PATH"

    if [[ "$DO_OTOOL" == "y" || "$DO_OTOOL" == "Y" ]]; then
      if [[ -x "$BINARY_PATH" ]]; then
        echo "[*] Running otool disassembly..."
        otool -tvV "$BINARY_PATH" &> "$OTOOL_LOG" &
      else
        echo "[!] Binary path not executable. Skipping otool."
      fi
    fi

    cleanup
  }

  trap dump_and_exit SIGINT
  while true; do sleep 1; done

else
  echo "[*] Capturing memory dump now..."
  lldb -p $PID -o "process save-core \"$CORE_PATH\"" -o "detach" -o "quit" &> "$LOG_PATH"

  if [[ -f "$CORE_PATH" ]]; then
    echo "✔ Memory dump saved to: $CORE_PATH"
  else
    echo "✖ Failed to dump memory. See log: $LOG_PATH"
  fi

  if [[ "$DO_OTOOL" == "y" || "$DO_OTOOL" == "Y" ]]; then
    if [[ -x "$BINARY_PATH" ]]; then
      echo "[*] Running otool disassembly..."
      otool -tvV "$BINARY_PATH" &> "$OTOOL_LOG" &
    else
      echo "[!] Binary path not executable. Skipping otool."
    fi
  fi

  cleanup
fi
