#!/bin/bash
# Title: MEOW Forensics Toolkit - Network Snapshot Module
# Description: Captures current network configuration and state for forensic analysis. Does not perform live traffic capture.
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
echo "[ MEOW Forensics Toolkit ] Module: Network Snapshot - START"
echo "------------------------------------------------------------"

# ------------------------------------------------------------
# SETUP OUTPUT DIRECTORY
# ------------------------------------------------------------
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
MODULE_NAME="network-capture"
OUTPUT_DIR="/private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$TIMESTAMP"
mkdir -p "$OUTPUT_DIR"
ARCHIVE_NAME="macOS_${MODULE_NAME}_$TIMESTAMP.tar.gz"

echo "[*] Output directory: $OUTPUT_DIR"

# ------------------------------------------------------------
# CAPTURE NETWORK STATE
# ------------------------------------------------------------
echo "[*] Capturing current network state..."

ifconfig -a > "$OUTPUT_DIR/ifconfig.txt" 2>/dev/null
netstat -anv > "$OUTPUT_DIR/netstat_connections.txt" 2>/dev/null
netstat -rn > "$OUTPUT_DIR/netstat_routes.txt" 2>/dev/null
lsof -i > "$OUTPUT_DIR/lsof_ports.txt" 2>/dev/null
scutil --dns > "$OUTPUT_DIR/dns_config.txt" 2>/dev/null
networksetup -listallhardwareports > "$OUTPUT_DIR/hardware_ports.txt" 2>/dev/null
arp -a > "$OUTPUT_DIR/arp_table.txt" 2>/dev/null

echo "✔ Network configuration and state captured."

# ------------------------------------------------------------
# ARCHIVE RESULTS
# ------------------------------------------------------------
echo "[*] Creating compressed archive..."
tar -czf "/private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$ARCHIVE_NAME" -C "$OUTPUT_DIR" .

echo "✔ Archive saved: /private/var/tmp/meow-forensics-toolkit/$MODULE_NAME/$ARCHIVE_NAME"
echo "[!] Note: This location persists after reboot. Remember to manually clean it up if needed."

# ------------------------------------------------------------
# END
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "[ MEOW Forensics Toolkit ] Module: Network Snapshot - END"
echo "------------------------------------------------------------"

exit 0
