#!/bin/bash
# Title: MEOW Forensics Toolkit - Process Tracker Module
# Description: Tracks all process launches using DTrace for real-time analysis. Outputs a snapshot of the full process list at start and end, and logs all events live. Ensures cleanup and proper saving even on Ctrl+C. Also captures failed launches.
# Author: Simon .I
# Version: 2025.04.20r1-persist

# ------------------------------------------------------------
# START
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "[ MEOW Forensics Toolkit ] Module: Process Tracker - START"
echo "------------------------------------------------------------"

# ------------------------------------------------------------
# SIP CHECK (Hard Requirement)
# ------------------------------------------------------------
SIP_STATUS=$(csrutil status 2>/dev/null)

if echo "$SIP_STATUS" | grep -q "enabled"; then
  echo "[!] System Integrity Protection (SIP) is ENABLED."
  echo "[!] This module requires SIP to be fully disabled."
  echo "[!] DTrace will not function while SIP is active."
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
# CHECK ROOT
# ------------------------------------------------------------
if [[ "$(id -u)" -ne 0 ]]; then
  echo "Please run this script with sudo."
  exit 1
fi

# ------------------------------------------------------------
# SETUP OUTPUT
# ------------------------------------------------------------
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
OUTPUT_DIR="/private/var/tmp/meow-forensics-toolkit/process-tracker/$TIMESTAMP"
mkdir -p "$OUTPUT_DIR"
DTRACE_TEMP_SUCCESS="$OUTPUT_DIR/dtrace_success_raw.log"
DTRACE_TEMP_FAILURE="$OUTPUT_DIR/dtrace_fail_raw.log"

# ------------------------------------------------------------
# USER INPUT
# ------------------------------------------------------------
echo
read -r -p "Enter duration to monitor (in seconds, or type 'infinite' to run until Ctrl+C): " DURATION
if [[ "$DURATION" == "infinite" ]]; then
  RUN_FOREVER=true
elif [[ "$DURATION" =~ ^[0-9]+$ ]]; then
  RUN_FOREVER=false
else
  echo "Invalid input. Must be a number or 'infinite'. Exiting."
  exit 1
fi

# ------------------------------------------------------------
# FUNCTION HELPERS
# ------------------------------------------------------------
snapshot_full_process_list() {
  local file_path=$1
  ps auxww > "$file_path"
}

create_archive() {
  local archive_path="$OUTPUT_DIR.tar.gz"
  tar -czf "$archive_path" -C "$(dirname "$OUTPUT_DIR")" "$(basename "$OUTPUT_DIR")"
  echo "[+] Archived all outputs to: $archive_path"
}

# ------------------------------------------------------------
# DTRACE SCRIPTS
# ------------------------------------------------------------
DTRACE_SCRIPT_SUCCESS='proc:::exec-success
{
  printf("%Y | CMD: %s[%d] | PPID: %d | UID: %d | ARGS: %s\n", walltimestamp, execname, pid, ppid, uid, curpsinfo->pr_psargs);
}'

DTRACE_SCRIPT_FAILURE='proc:::exec-failure
{
  printf("%Y | FAILED CMD: %s | UID: %d | ERRNO: %d\n", walltimestamp, copyinstr(arg0), uid, errno);
}'

echo "$DTRACE_SCRIPT_SUCCESS" > "$OUTPUT_DIR/dtrace_success_script.d"
echo "$DTRACE_SCRIPT_FAILURE" > "$OUTPUT_DIR/dtrace_failure_script.d"

# ------------------------------------------------------------
# INITIAL SYSTEM SNAPSHOT
# ------------------------------------------------------------
START_SNAPSHOT="$OUTPUT_DIR/system_snapshot_start.txt"
snapshot_full_process_list "$START_SNAPSHOT"
echo "[+] Full system process snapshot (start) saved to: $START_SNAPSHOT"

# ------------------------------------------------------------
# CLEANUP HANDLER FOR CTRL+C
# ------------------------------------------------------------
cleanup() {
  echo
  echo "[*] Caught interrupt. Cleaning up..."

  if [[ -n "$DTRACE_PID_SUCCESS" ]]; then
    kill -TERM "$DTRACE_PID_SUCCESS" 2>/dev/null
  fi
  if [[ -n "$DTRACE_PID_FAILURE" ]]; then
    kill -TERM "$DTRACE_PID_FAILURE" 2>/dev/null
  fi

  sleep 1

  END_SNAPSHOT="$OUTPUT_DIR/system_snapshot_end.txt"
  snapshot_full_process_list "$END_SNAPSHOT"
  echo "[+] Full system process snapshot (end) saved to: $END_SNAPSHOT"
  echo "[+] All successful exec logs saved to: $DTRACE_TEMP_SUCCESS"
  echo "[+] All failed exec logs saved to: $DTRACE_TEMP_FAILURE"
  echo "[*] Data saved in: $OUTPUT_DIR"
  create_archive
  echo "[!] Note: This location persists after reboot. Remember to manually clean it up if needed."
  echo "------------------------------------------------------------"
  echo "[ MEOW Forensics Toolkit ] Module: Process Tracker - END"
  echo "------------------------------------------------------------"
  exit 0
}

trap cleanup INT TERM EXIT

# ------------------------------------------------------------
# MONITORING
# ------------------------------------------------------------
echo
if [[ "$RUN_FOREVER" == true ]]; then
  echo "Tracking ALL process launches indefinitely. Press Ctrl+C to stop."
else
  echo "Tracking ALL process launches using dtrace for ${DURATION} seconds..."
fi

echo "--- Monitoring started at $(date) ---"
echo

(dtrace -n "$DTRACE_SCRIPT_SUCCESS" > "$DTRACE_TEMP_SUCCESS" 2>/dev/null) &
DTRACE_PID_SUCCESS=$!

(dtrace -n "$DTRACE_SCRIPT_FAILURE" > "$DTRACE_TEMP_FAILURE" 2>/dev/null) &
DTRACE_PID_FAILURE=$!

if [[ "$RUN_FOREVER" == true ]]; then
  wait
else
  sleep "$DURATION"
  cleanup
fi
