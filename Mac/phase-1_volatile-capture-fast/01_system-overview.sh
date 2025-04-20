#!/bin/bash
# Title: MEOW Forensics Toolkit - System Overview Module
# Description: Captures forensic system state including SIP status, launchctl state, persistence artefacts, cron jobs, privileged binaries, system resource usage, network and process data.
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
echo "[ MEOW Forensics Toolkit ] Module: System Overview - START"
echo "------------------------------------------------------------"

# ------------------------------------------------------------
# SETUP VARIABLES
# ------------------------------------------------------------
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
OUTPUT_DIR="/private/var/tmp/meow-forensics-toolkit/system-overview/$TIMESTAMP"
PARENT_DIR="$(dirname "$OUTPUT_DIR")"
ARCHIVE_NAME="macOS_system_overview_$TIMESTAMP.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "Output directory: $OUTPUT_DIR"

# ------------------------------------------------------------
# DETECT CONSOLE USER & HOME PATH
# ------------------------------------------------------------
CONSOLE_USER=$(stat -f%Su /dev/console)
CONSOLE_HOME=$(eval echo "~$CONSOLE_USER")

echo "Detected console user: $CONSOLE_USER" > "$OUTPUT_DIR/console_user.txt"
echo "Resolved home path: $CONSOLE_HOME" >> "$OUTPUT_DIR/console_user.txt"

# ------------------------------------------------------------
# SYSTEM VERSION & KERNEL INFO
# ------------------------------------------------------------
sw_vers > "$OUTPUT_DIR/system_version.txt"
uname -a >> "$OUTPUT_DIR/system_version.txt"

# ------------------------------------------------------------
# SIP STATUS
# ------------------------------------------------------------
csrutil status > "$OUTPUT_DIR/sip_status.txt" 2>&1

# ------------------------------------------------------------
# LAUNCH SERVICES
# ------------------------------------------------------------
/bin/launchctl dumpstate > "$OUTPUT_DIR/launchctl_dumpstate.txt" 2>&1
launchctl list > "$OUTPUT_DIR/launchctl_list.txt" 2>&1

# ------------------------------------------------------------
# PERSISTENCE PATHS
# ------------------------------------------------------------
cp -R /Library/LaunchAgents "$OUTPUT_DIR/Library_LaunchAgents" 2>/dev/null
cp -R /Library/LaunchDaemons "$OUTPUT_DIR/Library_LaunchDaemons" 2>/dev/null
cp -R "$CONSOLE_HOME/Library/LaunchAgents" "$OUTPUT_DIR/User_LaunchAgents" 2>/dev/null

# ------------------------------------------------------------
# SECURITY SETTINGS & BOOT-TIME MODIFIERS
# ------------------------------------------------------------
spctl --status > "$OUTPUT_DIR/gatekeeper_status.txt" 2>&1
nvram -p > "$OUTPUT_DIR/nvram.txt" 2>&1
cp /etc/fstab "$OUTPUT_DIR/fstab.txt" 2>/dev/null
cp /etc/synthetic.conf "$OUTPUT_DIR/synthetic.conf.txt" 2>/dev/null
cp /etc/hosts "$OUTPUT_DIR/hosts.txt" 2>/dev/null

# ------------------------------------------------------------
# SYSTEM PROFILE
# ------------------------------------------------------------
system_profiler -detailLevel mini > "$OUTPUT_DIR/system_profile.txt" 2>&1

# ------------------------------------------------------------
# PRIVILEGED HELPER TOOLS
# ------------------------------------------------------------
cp -R /Library/PrivilegedHelperTools "$OUTPUT_DIR/PrivilegedHelperTools" 2>/dev/null

# ------------------------------------------------------------
# CRON JOBS
# ------------------------------------------------------------
if [[ -f /etc/crontab ]]; then
  cp /etc/crontab "$OUTPUT_DIR/system_crontab.txt"
else
  echo "/etc/crontab not found." > "$OUTPUT_DIR/system_crontab.txt"
fi

crontab -l -u "$CONSOLE_USER" > "$OUTPUT_DIR/user_crontab_${CONSOLE_USER}.txt" 2>/dev/null || echo "No crontab for $CONSOLE_USER" > "$OUTPUT_DIR/user_crontab_${CONSOLE_USER}.txt"

mkdir -p "$OUTPUT_DIR/cron_dirs"
for cron_dir in cron.hourly cron.daily cron.weekly cron.monthly cron.d; do
  if [[ -d "/etc/$cron_dir" ]]; then
    ls -la "/etc/$cron_dir" > "$OUTPUT_DIR/cron_dirs/${cron_dir}_listing.txt"
    cp -R "/etc/$cron_dir" "$OUTPUT_DIR/cron_dirs/$cron_dir"
  fi
done

if [[ -d /var/at/tabs ]]; then
  cp -R /var/at/tabs "$OUTPUT_DIR/cron_raw_tabs" 2>/dev/null
else
  echo "/var/at/tabs directory not found." > "$OUTPUT_DIR/cron_raw_tabs.txt"
fi

# ------------------------------------------------------------
# SYSTEM OVERVIEW - RESOURCE & NETWORK STATE
# ------------------------------------------------------------
top -l 1 -n 0 > "$OUTPUT_DIR/cpu_memory_top.txt" 2>/dev/null
vm_stat > "$OUTPUT_DIR/vm_stat.txt" 2>/dev/null
df -h > "$OUTPUT_DIR/disk_usage.txt" 2>/dev/null
iostat -d -c 2 > "$OUTPUT_DIR/disk_io.txt" 2>/dev/null

ifconfig -a > "$OUTPUT_DIR/network_ifconfig.txt" 2>/dev/null
netstat -rn > "$OUTPUT_DIR/network_routes.txt" 2>/dev/null
netstat -an > "$OUTPUT_DIR/network_connections.txt" 2>/dev/null

ps auxww > "$OUTPUT_DIR/process_list.txt" 2>/dev/null
lsof -i > "$OUTPUT_DIR/open_ports_lsof.txt" 2>/dev/null
who > "$OUTPUT_DIR/logged_in_users.txt" 2>/dev/null
w > "$OUTPUT_DIR/user_sessions.txt" 2>/dev/null
uptime > "$OUTPUT_DIR/uptime.txt" 2>/dev/null

# ------------------------------------------------------------
# CREATE COMPRESSED ARCHIVE
# ------------------------------------------------------------
echo "Creating compressed archive: $ARCHIVE_NAME"
tar -czf "$PARENT_DIR/$ARCHIVE_NAME" -C "$OUTPUT_DIR" .

# ------------------------------------------------------------
# END
# ------------------------------------------------------------
echo "System overview complete."
echo "All output saved under: $OUTPUT_DIR"
echo "Compressed archive saved to: $PARENT_DIR/$ARCHIVE_NAME"
echo "[!] Note: This location persists after reboot. Remember to manually clean it up if needed."

echo "------------------------------------------------------------"
echo "[ MEOW Forensics Toolkit ] Module: System Overview - END"
echo "------------------------------------------------------------"
