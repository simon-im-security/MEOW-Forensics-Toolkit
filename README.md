# MEOW Forensics Toolkit 🐱

<img src="https://github.com/simon-im-security/MEOW-Forensics-Toolkit/blob/main/Images/meow_ft_logo.png?raw=true" width="50%" />

**Mystery Event Origin Workflow (MEOW)** is a set of forensic scripts designed for macOS systems to facilitate detailed system analysis, event tracing, and forensic data capture. The toolkit assists in uncovering and understanding mysterious or suspicious events occurring within macOS environments.

```
 /\_/\  
( o.o ) MEOW Forensics Toolkit
 > ^ <  
```

## Toolkit Modules

### Phase 0: Preservation & Deep Scan

1. **Disk Copy (`01_disk-copy.sh`)**
   - Creates full or partial system backups using `ditto`, then archives and hashes.

2. **Log Backup (`02_log-backup.sh`)**
   - Collects macOS system, global, and user logs; archives output.

3. **File Timeline (`03_file-timeline.sh`)**
   - Identifies recently modified files; filters by minutes or days.

4. **Keyword Search (`04_keyword-search.sh`)**
   - Searches text files for suspicious keywords across the system.

---

### Phase 1: Volatile Capture (Live System Data)

1. **System Overview (`01_system-overview.sh`)**
   - Captures SIP status, persistence artefacts, cron jobs, processes, and system resources.

2. **Network Snapshot (`02_network-snapshot.sh`)**
   - Records network configurations and active network states without capturing live traffic.

3. **CPU Dump (`03_cpu-dump.sh`)**
   - Collects detailed CPU usage, sysctl data, and CPU features; excludes thermal/power metrics to prevent system freezes.

---

### Phase 2: Runtime Monitoring

1. **Process Tracker (`01_process-tracker.sh`)**
   - Monitors and logs process launches in real-time using DTrace; provides process lists and failure tracking.

2. **Process Memory Dump (`02_process-memory-dump.sh`)**
   - Captures memory snapshots of user-specified processes with LLDB; optionally disassembles binaries.

---

### Phase 3: Post-Incident Static Analysis

1. **Browser History (`01_browser-history.sh`)**
   - Collects browser history databases from Chrome, Edge, Brave, Island, Firefox, and Safari with metadata.

2. **Binary Inspection (`02_binary-inspection.sh`)**
   - Performs static analysis on Mach-O binaries, extracting SHA256, file information, codesign details, and more using tools like `otool`, `nm`, and `strings`.

---

## Quick Start

To download, visit: [MEOW Forensics Toolkit Releases](https://github.com/simon-im-security/MEOW-Forensics-Toolkit/releases/tag/main)

All scripts must run with root privileges.

---

## Contributions

Contributions, issue reports, and enhancements are welcomed. Please submit pull requests or issues directly on GitHub.

---

## License

Licensed under the MIT License. See `LICENSE` for more details.

---

🐱 **Stay curious and forensic!** 🐱
