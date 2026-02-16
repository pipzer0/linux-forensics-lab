# Linux IR Interview - Quick Reference

## Common Interview Questions & Answers

### Q: How do you detect timestomping on Linux?

**Answer:**
Timestomping uses `touch` to modify mtime/atime, but **ctime cannot be faked** without raw disk access.

```bash
# Detection: ctime significantly newer than mtime
stat <file>
# If mtime is 2023 but ctime is 2024, file was timestomped
```

Key insight: `touch -d "old date"` changes mtime/atime but ctime becomes "now"

---

### Q: How do you recover a deleted executable that's still running?

**Answer:**
Use `/proc/[pid]/exe` symlink:

```bash
# Find deleted executables
ls -la /proc/*/exe 2>/dev/null | grep deleted

# Recover the binary
cp /proc/<pid>/exe /tmp/recovered_malware
```

The kernel maintains the executable in memory even after deletion.

---

### Q: What's the difference between mtime, atime, and ctime?

**Answer:**
| Timestamp | Meaning | Changed By |
|-----------|---------|------------|
| **mtime** | Modification time | File content changed |
| **atime** | Access time | File read (may be disabled: noatime) |
| **ctime** | Change time | Metadata changed (perms, owner, rename) |
| **crtime** | Birth/creation | File created (ext4 only, via debugfs) |

**Key:** ctime updates when mtime changes, but not vice versa. Can't fake ctime with userspace tools.

---

### Q: How do you find persistence on Linux?

**Answer:**
Check these locations:

1. **Cron:** `/var/spool/cron/crontabs/*`, `/etc/cron.d/*`, `/etc/crontab`
2. **Systemd:** `~/.config/systemd/user/`, `/etc/systemd/system/`
3. **SSH:** `~/.ssh/authorized_keys`
4. **Shell:** `~/.bashrc`, `~/.profile`, `~/.bash_logout`
5. **ld.so.preload:** `/etc/ld.so.preload`
6. **Init:** `/etc/rc.local`, `/etc/init.d/`

---

### Q: How do you detect privilege escalation?

**Answer:**
Check for:

```bash
# SUID binaries
find / -perm -4000 2>/dev/null

# Capabilities (especially cap_setuid)
getcap -r / 2>/dev/null

# Sudo misconfigurations
cat /etc/sudoers
grep NOPASSWD /etc/sudoers /etc/sudoers.d/*

# Recently compiled exploits
find / -name "*.c" -newer /etc/passwd 2>/dev/null
```

---

### Q: What's loginuid and why is it important?

**Answer:**
`/proc/[pid]/loginuid` stores the **original UID** of the user who logged in.

**Key insight:** It **survives sudo, su, and privilege changes**.

```bash
cat /proc/<pid>/loginuid
# If attacker does: ssh in → sudo su → run malware
# loginuid still shows their original UID
```

Value of 4294967295 (-1) means "unset" (kernel/system process).

---

### Q: How do you recover a deleted file that's still open?

**Answer:**
```bash
# Find deleted-but-open files
lsof +L1
# or
ls -la /proc/*/fd/ 2>/dev/null | grep deleted

# Recover content
cat /proc/<pid>/fd/<fd_number> > /tmp/recovered
```

---

### Q: What are file capabilities and why are they dangerous?

**Answer:**
Capabilities are fine-grained privileges assigned to binaries (alternative to SUID).

**Dangerous capabilities:**
- `cap_setuid` - Can change UID (become root)
- `cap_dac_override` - Bypass all file permission checks
- `cap_sys_admin` - Near-root (mount, ptrace, etc.)
- `cap_net_raw` - Raw socket access (sniffing)

```bash
# Find files with capabilities
getcap -r / 2>/dev/null

# Check specific file
getcap /usr/local/bin/suspicious
```

---

### Q: How do you detect anti-forensics?

**Answer:**
Look for evidence of cleanup:

1. **History clearing:**
   ```bash
   grep "history -c\|HISTFILE\|HISTSIZE=0" /home/*/.bash*
   ```

2. **Timestomping:** ctime vs mtime discrepancy

3. **Log truncation:** Unusually small log files, gaps in timestamps

4. **Deleted running processes:**
   ```bash
   ls -la /proc/*/exe 2>/dev/null | grep deleted
   ```

5. **Hidden files in unusual places:**
   ```bash
   find /tmp /var/tmp /dev/shm -name ".*" 2>/dev/null
   ```

---

### Q: What's the Linux equivalent of Prefetch?

**Answer:**
Linux has **no direct equivalent**. Alternatives:

1. **auditd** - Can log all execve() calls if configured
2. **Process accounting** - `lastcomm` shows executed commands
3. **eBPF/BCC tools** - execsnoop for real-time
4. **systemd journal** - Unit start/stop events
5. **Shell history** - User command history

---

### Q: How do you analyze ELF binaries?

**Answer:**
```bash
# Basic info
file <binary>

# Strings (C2 IPs, URLs)
strings <binary> | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}"

# Headers
readelf -h <binary>    # ELF header
readelf -S <binary>    # Sections
readelf -s <binary>    # Symbols

# Dependencies
ldd <binary>

# Disassembly
objdump -d <binary>

# Hash for IOC
sha256sum <binary>
```

---

### Q: What /proc entries are most useful for IR?

**Answer:**
| Path | Information |
|------|-------------|
| `/proc/[pid]/exe` | Executable (even if deleted) |
| `/proc/[pid]/fd/` | Open file descriptors |
| `/proc/[pid]/maps` | Memory mappings (loaded libs) |
| `/proc/[pid]/cmdline` | Original command line |
| `/proc/[pid]/environ` | Environment variables |
| `/proc/[pid]/cwd` | Current working directory |
| `/proc/[pid]/loginuid` | Original login UID |
| `/proc/[pid]/status` | Process status, UIDs |

---

### Q: How do you detect rootkits?

**Answer:**
1. **Compare outputs:**
   ```bash
   # ps vs /proc
   ps aux | wc -l
   ls /proc | grep -E '^[0-9]+$' | wc -l
   # If different, processes are hidden
   ```

2. **Check ld.so.preload:**
   ```bash
   cat /etc/ld.so.preload
   ```

3. **Check kernel modules:**
   ```bash
   lsmod
   cat /proc/modules
   ```

4. **Use rootkit detectors:**
   - chkrootkit
   - rkhunter
   - OSSEC

---

## Interview Tips

1. **Always mention timestamps** - MAC times, ctime immutability
2. **Know /proc** - It's the Linux equivalent of memory forensics
3. **Understand persistence vectors** - There are many, know them all
4. **Think like an attacker** - Where would YOU hide?
5. **Reference real tools** - sleuthkit, volatility, SIFT workstation
6. **Mention log sources** - wtmp, btmp, auth.log, audit.log
7. **Know anti-forensics** - And how to detect it

Good luck!
