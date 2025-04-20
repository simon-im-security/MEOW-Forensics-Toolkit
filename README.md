# MEOW Forensics Toolkit

<div align="center">
  <img src="https://github.com/simon-im-security/MEOW-Forensics-Toolkit/blob/main/Images/meow_ft_logo.png?raw=true" width="50%">
</div>

**MEOW** stands for **Mystery Event Origin Workflow** — a collection of forensics and incident response (DFIR) scripts built for macOS. It helps you figure out what's going on when your system acts strangely or something suspicious is happening.

```
 /\_/\  
( o.o ) MEOW Forensics Toolkit
 > ^ <  
```

Whether you're preserving evidence, monitoring processes, or analysing after an incident — MEOW has you covered.

---

## 💾 Phase 0: Preservation & Deep Scan

1. **Disk Copy**  
   Backs up the entire system (or parts of it), compresses and hashes everything for integrity.

2. **Log Backup**  
   Grabs system and user logs, then neatly archives them.

3. **File Timeline**  
   Lists files that were modified recently — great for spotting unusual changes.

4. **Keyword Search**  
   Looks through text files for any suspicious terms and shows you where they popped up.

---

## ⚡ Phase 1: Live System Snapshot

1. **System Overview**  
   Captures everything from SIP status, cron jobs, persistence mechanisms, to active processes and system usage.

2. **Network Snapshot**  
   Takes a snapshot of the current network setup — no traffic capture, just configs, routes, and ports.

3. **CPU Dump**  
   Pulls detailed CPU stats (but skips thermal sensors to avoid crashes).

---

## 🕵️‍♂️ Phase 2: Runtime Monitoring

1. **Process Tracker**  
   Watches and logs all process activity live — successful and failed launches.

2. **Process Memory Dump**  
   Captures memory from processes you specify, optionally disassembles the binary too.

---

## 🧪 Phase 3: Post-Incident Analysis

1. **Browser History**  
   Extracts browsing history and metadata from all common macOS browsers.

2. **Binary Inspection**  
   Analyses binaries using tools like `file`, `otool`, `strings`, and `codesign`. Tells you what a file is really made of.

---

## 🚀 Getting Started

Some scripts need **System Integrity Protection (SIP)** to be turned off — you’ll get a warning if that’s the case.

Make sure to run all scripts as **root** (`sudo`).

**Download the toolkit:**  
👉 [MEOW Toolkit Releases](https://github.com/simon-im-security/MEOW-Forensics-Toolkit/releases/tag/main)

---

## 🛠 Contribute

Got a feature idea or found a bug?  
Open an issue or submit a pull request — all help is welcome!

---

## 📄 Licence

This toolkit is released under the **MIT Licence**. Feel free to use, modify, and share it.
