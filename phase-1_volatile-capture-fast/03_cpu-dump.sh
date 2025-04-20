#!/bin/bash
# Title: MEOW Forensics Toolkit - CPU Dump Module
# Description: Captures detailed CPU usage, sysctl metrics, and CPU feature data for forensic analysis. Thermal and power metrics skipped to avoid freezes.
# Author: Simon .I
# Version: 2025.04.20r1-persist

# ------------------------------------------------------------
# CHECK FOR ROOT PRIVILEGES
# ------------------------------------------------------------
if [[ "$(id -u)" -ne 0 ]]; then
  echo "[!] This script must be run as root (use sudo)."
  exit 1
fi

# ------------------------------------------------------------
# START
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "[ MEOW Forensics Toolkit ] Module: CPU Dump - START"
echo "------------------------------------------------------------"

# ------------------------------------------------------------
# SETUP OUTPUT DIRECTORY
# ------------------------------------------------------------
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
MODULE_NAME="cpu-dump"
OUTPUT_DIR="/private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$TIMESTAMP"
mkdir -p "$OUTPUT_DIR"
ARCHIVE_NAME="macOS_${MODULE_NAME}_$TIMESTAMP.tar.gz"

echo "[*] Collecting CPU snapshot at: $TIMESTAMP"

# ------------------------------------------------------------
# COLLECT CPU SNAPSHOT
# ------------------------------------------------------------
echo "[*] Running: top -l 1 -n 0"
top -l 1 -n 0 > "$OUTPUT_DIR/top_snapshot.txt"
echo "✔ top snapshot saved: $OUTPUT_DIR/top_snapshot.txt"

echo "[*] Running: sysctl -a | grep -i cpu"
sysctl -a | grep -i cpu > "$OUTPUT_DIR/sysctl_cpu.txt"
echo "✔ sysctl metrics saved: $OUTPUT_DIR/sysctl_cpu.txt"

echo "[*] Running: ps auxww"
ps auxww > "$OUTPUT_DIR/ps_full.txt"
echo "✔ ps process list saved: $OUTPUT_DIR/ps_full.txt"

# ------------------------------------------------------------
# COLLECT ADDITIONAL CPU DATA
# ------------------------------------------------------------
echo "[*] Collecting CPU feature flags and capabilities"
sysctl machdep.cpu.features > "$OUTPUT_DIR/cpu_features.txt"
sysctl machdep.cpu.leaf7_features >> "$OUTPUT_DIR/cpu_features.txt"
sysctl machdep.cpu.brand_string >> "$OUTPUT_DIR/cpu_features.txt"
echo "✔ CPU feature data saved: $OUTPUT_DIR/cpu_features.txt"

echo "[*] Capturing CPU microcode version"
sysctl machdep.cpu.microcode_version > "$OUTPUT_DIR/cpu_microcode.txt"
echo "✔ Microcode version saved: $OUTPUT_DIR/cpu_microcode.txt"

echo "[*] Checking boot arguments"
nvram boot-args > "$OUTPUT_DIR/boot_args.txt" 2>/dev/null

echo "[*] Checking hypervisor support"
sysctl kern.hv_support > "$OUTPUT_DIR/hypervisor_support.txt"
echo "✔ Hypervisor support saved: $OUTPUT_DIR/hypervisor_support.txt"

echo "[*] Checking CPU cache information"
sysctl -a | grep cache > "$OUTPUT_DIR/cpu_cache_info.txt"
echo "✔ CPU cache info saved: $OUTPUT_DIR/cpu_cache_info.txt"

# ------------------------------------------------------------
# ARCHIVE RESULTS
# ------------------------------------------------------------
echo "[*] Creating archive..."
tar -czf "/private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$ARCHIVE_NAME" -C "$OUTPUT_DIR" .
echo "✔ Archive saved: /private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$ARCHIVE_NAME"
echo "[!] Note: This location persists after reboot. Remember to manually clean it up if needed."

# ------------------------------------------------------------
# END
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "[ MEOW Forensics Toolkit ] Module: CPU Dump - END"
echo "------------------------------------------------------------"

exit 0
