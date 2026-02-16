# Challenge 09: Privilege Escalation Artifacts

## Objective
Identify evidence of privilege escalation techniques used by the attacker.

## Background
Privilege escalation = gaining higher privileges than initially obtained.
Types:
- **Vertical**: User → Root
- **Horizontal**: User A → User B

---

## Tasks

### Task 9.1: SUID/SGID Binaries
SUID/SGID bits allow execution with owner's privileges:

```bash
# Find all SUID binaries
find / -perm -4000 -type f 2>/dev/null

# Find all SGID binaries
find / -perm -2000 -type f 2>/dev/null

# Find both
find / -perm /6000 -type f 2>/dev/null

# Check for unusual SUID binaries
find / -perm -4000 -type f -exec ls -la {} \; 2>/dev/null | grep -v "/usr/bin\|/bin\|/sbin"
```

**Questions**:
1. Find the suspicious SUID binary.
2. Where is it located?
3. What binary was copied to create it?

---

### Task 9.2: Capabilities
```bash
# Find files with capabilities
getcap -r / 2>/dev/null

# Check specific suspicious binary
getcap /usr/local/bin/syshealth

# Dangerous capabilities:
# cap_setuid - become any user
# cap_setgid - become any group
# cap_dac_override - bypass file permissions
# cap_sys_admin - everything
```

---

### Task 9.3: Sudo Configuration
```bash
# Check sudo rules
cat /etc/sudoers
cat /etc/sudoers.d/*

# Look for NOPASSWD entries
grep NOPASSWD /etc/sudoers /etc/sudoers.d/* 2>/dev/null

# Look for dangerous wildcards
grep -E "\*|ALL" /etc/sudoers 2>/dev/null
```

**Dangerous sudo rules**:
- `user ALL=(ALL) NOPASSWD: ALL`
- `user ALL=(root) /usr/bin/vim *`
- `user ALL=(root) /usr/bin/python*`

---

### Task 9.4: Writable Sensitive Files
```bash
# World-writable files in sensitive locations
find /etc -perm -002 -type f 2>/dev/null
find /usr -perm -002 -type f 2>/dev/null

# Writable by current user
find /etc -writable -type f 2>/dev/null

# /etc/passwd writable = add root user
# /etc/shadow writable = change passwords
# /etc/sudoers writable = grant sudo
```

---

### Task 9.5: Exploit Artifacts
```bash
# Look for exploit source code
find / -name "*.c" -newer /etc/passwd 2>/dev/null
find /home -name "*exploit*" -o -name "*priv*" 2>/dev/null

# Check common exploit locations
ls -la /home/*/exploits/
cat /home/webadmin/exploits/*.c
```

**Questions**:
1. Find the exploit source code.
2. What CVE is it exploiting (if mentioned)?

---

### Task 9.6: GTFOBins Check
Many legitimate binaries can be abused for privesc:

```bash
# Python
python3 -c 'import os; os.setuid(0); os.system("/bin/bash")'

# Vim
vim -c ':!/bin/bash'

# Find interpreters
which python3 perl ruby

# Check their capabilities/SUID
getcap /usr/bin/python3* 2>/dev/null
ls -la /usr/bin/python3*
```

---

### Task 9.7: Kernel Exploit Indicators
```bash
# Check kernel version
uname -a

# Look for kernel exploit attempts in logs
grep -i "exploit\|overflow\|privilege" /var/log/* 2>/dev/null

# Check dmesg for unusual activity
dmesg | tail -50
```

---

## Key Commands Reference

```bash
# SUID/SGID
find / -perm -4000 2>/dev/null      # SUID
find / -perm -2000 2>/dev/null      # SGID
find / -perm /6000 2>/dev/null      # Both

# Capabilities
getcap -r / 2>/dev/null

# Sudo
sudo -l                              # What can I run?
cat /etc/sudoers
cat /etc/sudoers.d/*

# Writable files
find /etc -writable 2>/dev/null

# Exploit artifacts
find / -name "*.c" -newer /etc/passwd 2>/dev/null
find / -name "*exploit*" 2>/dev/null

# Kernel
uname -a
cat /proc/version
```

---

## Privesc Checklist

| Vector | Check | Command |
|--------|-------|---------|
| SUID binaries | Unusual SUID files | `find / -perm -4000` |
| Capabilities | cap_setuid, etc. | `getcap -r /` |
| Sudo rules | NOPASSWD, wildcards | `cat /etc/sudoers` |
| Writable /etc | passwd, shadow | `find /etc -writable` |
| Kernel exploits | Version + exploits | `uname -a` |
| Cron as root | Writable scripts | `cat /etc/crontab` |
| PATH hijacking | Writable PATH dirs | `echo $PATH` |

---

## Why This Matters

1. **Attack Path**: How did attacker get root?

2. **Vulnerability Identification**: What needs patching?

3. **Other Compromised Accounts**: Horizontal movement?

4. **Remediation**: Remove SUID, fix sudo, patch kernel.
