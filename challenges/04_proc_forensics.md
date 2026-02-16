# Challenge 04: Process Forensics via /proc

## Objective
Use the /proc filesystem to investigate running processes, recover deleted executables, and find hidden data.

## Background
`/proc` is a virtual filesystem providing process and kernel information:
- Each running process has a `/proc/[pid]/` directory
- Contains executable path, memory maps, environment, open files
- **Critical**: Can recover deleted-but-running executables!

---

## Tasks

### Task 4.1: Recover a Deleted Executable
If malware deletes itself after running, you can still recover it:

```bash
# First, run the artifact planting script if not done
/plant_artifacts.sh

# Check for deleted executables (exe link shows "(deleted)")
ls -la /proc/*/* 2>/dev/null | grep deleted

# find (prints the path that containe the PID)
find /proc/[0-9]*/fd -maxdepth 1 -type l -lname '* (deleted)' -printf '%p -> %l\n' 2>/dev/null
 
# The /proc/[pid]/exe symlink still points to the binary!
# Even though it's deleted, you can copy it:
cp /proc/<pid>/exe /tmp/recovered_binary

#View contents of the deleted file
$ cat /proc/<FD_PID>/fd/<symlink>

```

**Questions**:
1. Find any process whose executable has been deleted.
2. What is the PID?
3. Recover the executable.

---

### Task 4.2: Recover Deleted Open Files
Files deleted but still open by a process can be recovered:

```bash
# Find the demo process (check /var/run/forensics_demo_pids)
cat /var/run/forensics_demo_pids

# List open file descriptors
ls -la /proc/<pid>/fd/

# Look for "(deleted)" entries
# These are deleted files still open!

# Recover the file content
cat /proc/<pid>/fd/3
```

**Questions**:
1. What credentials were in the deleted file?
2. What file descriptor number held it?

---

### Task 4.3: Environment Variable Analysis
Process environment can reveal attacker intentions:

```bash
# View environment of a process
cat /proc/<pid>/environ | tr '\0' '\n'

# Or more readable
strings /proc/<pid>/environ

# Hunt for PID with certain strings
for pid in /proc/[0-9]*; do
  env=$(strings "$pid/environ" 2>/dev/null) || continue
  echo "$env" | egrep -qi 'http|https|\.onion|c2|beacon|token|api[_-]?key|secret|encrypt|key=' || continue
  echo "PID=${pid#/proc/} CMD=$(tr '\0' ' ' < "$pid/cmdline" 2>/dev/null)"
  echo "$env" | egrep -i 'http|https|\.onion|c2|beacon|token|api[_-]?key|secret|encrypt|key='
  echo
done

```

**Questions**:
1. Find a process with suspicious environment variables.
2. What C2 server is configured?
3. What encryption key is stored?

---

### Task 4.4: Command Line and CWD
```bash
# Original command line (null-separated)
cat /proc/<pid>/cmdline | tr '\0' ' '; echo

# Current working directory
ls -la /proc/<pid>/cwd

# Root directory (chroot detection)
ls -la /proc/<pid>/root
```

---

### Task 4.5: Memory Maps
Find loaded libraries and injected code:

```bash
# Memory mappings
cat /proc/<pid>/maps

# Look for:
# - Libraries loaded from unusual paths
# - Anonymous memory regions (potential shellcode)
# - Deleted libraries still mapped
```

---

### Task 4.6: Login UID (Audit Trail)
The loginuid survives privilege escalation!

```bash
# Check loginuid of processes
cat /proc/<pid>/loginuid

# Value of 4294967295 = not set (system process)
# Other values = original login UID

# This reveals WHO originally logged in, even after sudo/su
```

---

## Key Commands Reference

```bash
# Process executable (can be deleted but recoverable!)
ls -la /proc/<pid>/exe
cp /proc/<pid>/exe /tmp/recovered

# Open file descriptors
ls -la /proc/<pid>/fd/
cat /proc/<pid>/fd/<num>

# Environment variables
cat /proc/<pid>/environ | tr '\0' '\n'

# Command line
cat /proc/<pid>/cmdline | tr '\0' ' '

# Current & root directories
readlink /proc/<pid>/cwd
readlink /proc/<pid>/root

# Memory maps
cat /proc/<pid>/maps

# Process status
cat /proc/<pid>/status

# Login UID (audit)
cat /proc/<pid>/loginuid

# Network connections per process
cat /proc/<pid>/net/tcp
cat /proc/<pid>/net/udp

# Find all processes of a user
ps aux | grep <user>
ls -la /proc/*/loginuid | xargs -I{} sh -c 'echo -n "{}: "; cat {}'
```

---

## Why This Matters

1. **Deleted Binary Recovery**: Attackers delete malware after execution. /proc saves the day.

2. **Open File Recovery**: Deleted files with open handles are 100% recoverable.

3. **Environment Secrets**: C2 configs, API keys, encryption keys in env vars.

4. **Attribution**: loginuid persists through sudo/su - traces back to original user.

5. **Memory Forensics Light**: /proc/[pid]/maps shows loaded modules without full memory dump.
