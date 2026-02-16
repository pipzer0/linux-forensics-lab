# Challenge 07: Persistence Mechanisms

## Objective
Identify all persistence mechanisms established by the attacker.

## Background
Persistence = Attacker maintains access across reboots. Linux has MANY persistence vectors.

---

## Tasks

### Task 7.1: Cron Jobs
```bash
# User crontabs
ls -la /var/spool/cron/crontabs/
cat /var/spool/cron/crontabs/*

# System cron directories
ls -la /etc/cron.d/
cat /etc/cron.d/*

ls -la /etc/cron.daily/
ls -la /etc/cron.hourly/
ls -la /etc/cron.weekly/
ls -la /etc/cron.monthly/

# Main crontab
cat /etc/crontab

# Anacron
cat /etc/anacrontab
```

**Questions**:
1. What malicious cron jobs exist?
2. What do they execute?
3. How often do they run?

---

### Task 7.2: Systemd Services
```bash
# User services (sneaky!)
find /home -path "*/.config/systemd/user/*.service" 2>/dev/null
cat /home/webadmin/.config/systemd/user/*.service

# System services
ls -la /etc/systemd/system/
ls -la /lib/systemd/system/

# Look for unusual ones
find /etc/systemd /lib/systemd -name "*.service" -newer /etc/passwd 2>/dev/null

# Enabled services
systemctl list-unit-files --type=service | grep enabled
```

**Questions**:
1. Find the malicious systemd services.
2. Are they user-level or system-level?
3. What binaries do they execute?

---

### Task 7.3: SSH Authorized Keys
```bash
# Check all users' authorized_keys
find /home -name "authorized_keys" -exec echo "=== {} ===" \; -exec cat {} \; 2>/dev/null

# Root's authorized_keys
cat /root/.ssh/authorized_keys 2>/dev/null

# Look for suspicious keys
grep -r "attacker\|evil\|hack" /home/*/.ssh/ 2>/dev/null
```

**Questions**:
1. What unauthorized SSH keys exist?
2. What usernames/hosts are in the key comments?

---

### Task 7.4: Dynamic Linker Hijacking
```bash
# ld.so.preload - loads library before everything else
cat /etc/ld.so.preload

# ld.so.conf - library paths
cat /etc/ld.so.conf
cat /etc/ld.so.conf.d/*

# Check for unusual libraries
ldd /bin/ls
```

**Questions**:
1. Is anything in /etc/ld.so.preload?
2. What would this achieve?

---

### Task 7.5: Shell Profile Persistence
```bash
# System-wide
cat /etc/profile
cat /etc/profile.d/*
cat /etc/bash.bashrc

# User-level
cat /home/*/.bashrc
cat /home/*/.bash_profile
cat /home/*/.profile
```

**Look for**:
- Unusual commands
- Background processes started
- Environment manipulation

---

### Task 7.6: Init Scripts (Legacy)
```bash
# SysV init
ls -la /etc/init.d/
ls -la /etc/rc*.d/

# rc.local (often overlooked)
cat /etc/rc.local 2>/dev/null
```

---

### Task 7.7: Kernel Modules
```bash
# Loaded modules
lsmod

# Module directory (check for unusual ones)
ls /lib/modules/$(uname -r)/

# Check for unsigned modules
# modinfo <module_name>
```

---

## Key Commands Reference

```bash
# Cron
crontab -l -u <user>
cat /var/spool/cron/crontabs/*
cat /etc/cron.d/*

# Systemd
systemctl list-unit-files
systemctl cat <service>
find / -name "*.service" -newer /etc/passwd 2>/dev/null

# SSH
find / -name "authorized_keys" 2>/dev/null

# Init/startup
cat /etc/rc.local
ls /etc/init.d/

# Library hijacking
cat /etc/ld.so.preload
ldd /bin/ls

# Kernel
lsmod
modinfo <module>
```

---

## Persistence Locations Checklist

| Location | Type | Check Command |
|----------|------|---------------|
| /var/spool/cron/crontabs/ | Cron | `cat /var/spool/cron/crontabs/*` |
| /etc/cron.d/ | Cron | `ls -la /etc/cron.d/` |
| ~/.config/systemd/user/ | Systemd User | `find /home -name "*.service"` |
| /etc/systemd/system/ | Systemd System | `ls /etc/systemd/system/` |
| ~/.ssh/authorized_keys | SSH | `cat authorized_keys` |
| /etc/ld.so.preload | Library Hijack | `cat /etc/ld.so.preload` |
| ~/.bashrc, ~/.profile | Shell | `cat ~/.bashrc` |
| /etc/rc.local | Init | `cat /etc/rc.local` |

---

## Why This Matters

1. **Continued Access**: Persistence survives reboots.

2. **Remediation Failure**: Miss one = attacker returns.

3. **Multiple Vectors**: Attackers often use 2-3 persistence methods.

4. **Stealth**: User-level systemd and cron are often overlooked.
