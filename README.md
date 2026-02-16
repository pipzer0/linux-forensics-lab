# Linux Forensics & Incident Response Lab

> **Note:** This project is a work in progress. Challenges, lab setup, and documentation may change as the project evolves. Contributions and feedback are welcome!

A hands-on training environment for practicing Linux forensics and IR skills, focused on **low-level filesystem artifacts** rather than log analysis.

## Quick Start

```bash
# Build the container
cd lab
docker build -t forensics-lab .

# Run the investigation environment
docker run -it --rm --name ir-investigation forensics-lab

# Inside the container, activate runtime artifacts
/plant_artifacts.sh
```

## What's Covered

This lab focuses on artifacts similar to Windows forensics concepts but for Linux:

| Windows Concept | Linux Equivalent | Challenge |
|-----------------|------------------|-----------|
| NTFS Timestamps | MAC times + birth time | Challenge 01 |
| NTFS ADS | Extended attributes | Challenge 02 |
| MFT Analysis | Inode analysis | Challenge 03 |
| Memory/Handle Analysis | /proc filesystem | Challenge 04 |
| Event Logs (binary) | wtmp/btmp/lastlog | Challenge 05 |
| Prefetch/Shimcache | Shell history, recently-used | Challenge 06 |
| Registry Run Keys | Systemd, cron, SSH keys | Challenge 07 |
| PE Analysis | ELF analysis | Challenge 08 |
| Token Manipulation | SUID/Capabilities | Challenge 09 |
| USN Journal tampering | Timestamp/log manipulation | Challenge 10 |

## Directory Structure

```
linux_forensics/
├── README.md              # This file
├── lab/                   # Docker lab environment
│   ├── Dockerfile
│   ├── setup_compromise.sh
│   ├── plant_artifacts.sh
│   ├── malware_sim.c
│   └── persistence.sh
├── challenges/            # Challenge exercises
│   ├── README.md
│   ├── 01_timestamps.md
│   ├── 02_extended_attributes.md
│   ├── 03_inodes.md
│   ├── 04_proc_forensics.md
│   ├── 05_binary_artifacts.md
│   ├── 06_shell_artifacts.md
│   ├── 07_persistence.md
│   ├── 08_elf_analysis.md
│   ├── 09_privesc_artifacts.md
│   └── 10_anti_forensics.md
├── answers/               # Answer key and cheat sheets
│   ├── 00_ANSWER_KEY.md
│   ├── CHEATSHEET_commands.md
│   ├── CHEATSHEET_artifacts.md
│   └── CHEATSHEET_interview.md
└── tools/                 # Additional tools (optional)
```

## Scenario

A web hosting company detected suspicious outbound connections from a server. The `webadmin` account appears compromised.

**Your mission:**
1. Reconstruct the attack timeline
2. Identify all persistence mechanisms
3. Determine attacker infrastructure (C2)
4. Document IOCs for remediation

**Attack Timeline (for reference):**
- 2024-01-15 02:34 - Initial access (webshell)
- 2024-01-15 02:35 - Reconnaissance
- 2024-01-15 02:41 - Privilege escalation
- 2024-01-15 02:43 - Malware deployment
- 2024-01-15 02:45 - Persistence
- 2024-01-15 02:52 - Data exfiltration
- 2024-01-15 02:55 - Anti-forensics

## Key Skills Practiced

- **Timestamp forensics**: Detecting timestomping, using ctime for truth
- **Extended attributes**: Finding hidden data in xattrs, capability abuse
- **Inode analysis**: Hard link detection, deleted file concepts
- **/proc forensics**: Recovering deleted executables, environment analysis
- **Binary record analysis**: wtmp, btmp, lastlog interpretation
- **Shell artifact analysis**: History, vim artifacts, anti-forensics detection
- **Persistence hunting**: Cron, systemd, SSH, ld.so.preload
- **ELF analysis**: Strings, headers, symbols, C2 extraction
- **Privesc artifact detection**: SUID, capabilities, sudo misconfig
- **Anti-forensics detection**: Timestomping, log gaps, history clearing

## Interview Prep

The `answers/CHEATSHEET_interview.md` file contains common interview Q&A for Linux forensics roles.

## Tools Available in Lab

- `stat`, `find`, `ls` - Filesystem analysis
- `getfattr`, `getcap` - Extended attributes
- `strings`, `readelf`, `objdump`, `ldd` - Binary analysis
- `last`, `lastb`, `lastlog`, `who` - Login analysis
- `lsof`, `ss`, `netstat` - Network/process analysis
- `sleuthkit` (fls, icat, ils) - Disk forensics

## Notes

- This is a training environment with simulated malicious artifacts
- All "malware" is harmless simulation code
- The container is ephemeral - restart to reset
- Some artifacts require root (run as root inside container)
