# Challenge 10: Anti-Forensics Detection

## Objective
Identify evidence of anti-forensics techniques used by the attacker.

## Background
Anti-forensics = techniques to hide, destroy, or obfuscate evidence.
Detecting anti-forensics is itself forensic evidence!

---

## Tasks

### Task 10.1: Timestamp Manipulation
```bash
# Files where mtime is much older than ctime
# (touch can change mtime but not ctime without raw disk access)

find / -type f -exec sh -c '
    M=$(stat -c %Y "$1" 2>/dev/null)
    C=$(stat -c %Z "$1" 2>/dev/null)
    if [ -n "$M" ] && [ -n "$C" ]; then
        DIFF=$((C - M))
        if [ $DIFF -gt 86400 ]; then
            echo "TIMESTOMPED: $1 (ctime $DIFF seconds after mtime)"
        fi
    fi
' _ {} \; 2>/dev/null

# Or manually check suspicious files
stat /etc/app.conf
```

**Questions**:
1. Which files show evidence of timestomping?
2. What's the time discrepancy?

---

### Task 10.2: Log Tampering
```bash
# Check for truncated logs
ls -la /var/log/

# Check for gaps in log timestamps
head -5 /var/log/syslog
tail -5 /var/log/syslog

# Unusual file sizes (too small)
find /var/log -size 0 2>/dev/null

# Binary log file tampering
stat /var/log/wtmp
stat /var/log/btmp
```

**Signs of tampering**:
- Files with 0 bytes
- Large time gaps in sequential logs
- ctime newer than expected
- Missing entries in sequences

---

### Task 10.3: History Evasion
```bash
# Check for history clearing
grep "history" /home/*/.bash_history 2>/dev/null
grep "HIST" /home/*/.bash_history 2>/dev/null

# Check bash_logout for history cleanup
cat /home/*/.bash_logout 2>/dev/null

# Check for HISTFILE manipulation
grep HISTFILE /home/*/.bashrc 2>/dev/null

# Symlinked to /dev/null
ls -la /home/*/.bash_history 2>/dev/null
```

**Questions**:
1. Did the attacker try to clear history?
2. What anti-history techniques are in place?

---

### Task 10.4: Hidden Files and Directories
```bash
# Find hidden directories in unusual places
find /tmp /var/tmp /dev/shm -name ".*" -type d 2>/dev/null

# Find hidden files
find /tmp /var/tmp /dev/shm -name ".*" -type f 2>/dev/null

# Files with leading dots in non-home directories
find /opt /usr /var -name ".*" 2>/dev/null

# Unicode tricks (look-alike characters)
ls -la /tmp/ | cat -A
```

---

### Task 10.5: Deleted File Evidence
```bash
# Check for running processes with deleted executables
ls -la /proc/*/exe 2>/dev/null | grep deleted

# Check for deleted but open files
find /proc/*/fd -type l 2>/dev/null | \
    xargs ls -la 2>/dev/null | grep deleted
```

---

### Task 10.6: Process Hiding Attempts
```bash
# Compare ps output with /proc
ps aux | wc -l
ls /proc | grep -E '^[0-9]+$' | wc -l

# Look for rootkit signs
# - Hidden processes
# - /proc files that error unexpectedly
```

---

### Task 10.7: File Wiping
```bash
# Look for secure deletion tools
which shred srm wipe 2>/dev/null

# Check history for wiping commands
grep -E "shred|srm|wipe|rm -P" /home/*/.bash_history 2>/dev/null

# Recently accessed wiping tools
stat /usr/bin/shred 2>/dev/null
```

---

### Task 10.8: Hosts File Manipulation
```bash
# Attacker might redirect security sites
cat /etc/hosts

# Look for:
# - antivirus update sites
# - security vendor sites
# - unusual entries
```

---

## Key Commands Reference

```bash
# Timestomping detection
stat <file>
find / -type f -exec stat -c "%n mtime:%Y ctime:%Z" {} \; 2>/dev/null

# Log tampering
ls -la /var/log/
stat /var/log/wtmp
utmpdump /var/log/wtmp

# History evasion
cat /home/*/.bash_logout
grep HIST /home/*/.bashrc
ls -la /home/*/.bash_history

# Hidden files
find /tmp /var -name ".*" 2>/dev/null

# Deleted files in use
ls -la /proc/*/exe 2>/dev/null | grep deleted
lsof +L1

# Secure deletion
which shred srm wipe
```

---

## Anti-Forensics Techniques Checklist

| Technique | Detection Method |
|-----------|------------------|
| Timestomping | Compare mtime vs ctime |
| Log truncation | File size, gaps |
| History clearing | .bash_logout, HISTFILE |
| File hiding | Hidden files in /tmp, /var |
| Process hiding | Compare ps vs /proc |
| Binary deletion | /proc/[pid]/exe (deleted) |
| Secure delete | shred, srm in history |
| DNS redirect | /etc/hosts entries |

---

## Why This Matters

1. **Intent**: Anti-forensics shows attacker sophistication.

2. **Evidence of Evidence**: Cleanup attempts prove malicious intent.

3. **What's Missing**: Knowing what was deleted guides recovery efforts.

4. **Timeline Reconstruction**: Even fake timestamps tell a story.
