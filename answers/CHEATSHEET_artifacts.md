# Linux Forensic Artifacts Reference

## Comparison: Linux vs Windows Artifacts

| Category | Windows Artifact | Linux Equivalent | Location/Command |
|----------|-----------------|------------------|------------------|
| **Prefetch** | Prefetch files | None native | Use process accounting, eBPF, or auditd |
| **Amcache** | Amcache.hve | Package manager logs | `/var/log/apt/history.log`, `/var/log/dpkg.log` |
| **Shimcache** | SYSTEM hive | None native | Binary analysis + process execution logs |
| **Recent Docs** | RecentDocs, JumpLists | recently-used.xbel | `~/.local/share/recently-used.xbel` |
| **BAM/DAM** | SYSTEM hive | loginuid + auditd | `/proc/[pid]/loginuid` |
| **Event Logs** | .evtx files | Text + binary logs | `/var/log/`, `journalctl` |
| **Registry** | NTUSER.DAT, SYSTEM | Config files | `/etc/`, `~/.config/` |
| **MFT** | $MFT | Inode table | `debugfs`, `sleuthkit` |
| **$UsnJrnl** | $UsnJrnl | None native | inotify logs if configured |
| **LNK files** | .lnk files | recently-used.xbel | `~/.local/share/recently-used.xbel` |
| **RDP Cache** | bcache*.bmc | None native | SSH known_hosts: `~/.ssh/known_hosts` |
| **Browser History** | Various | Various | `~/.mozilla/`, `~/.config/chromium/` |

---

## Artifact Categories Deep Dive

### 1. Execution Artifacts

| Artifact | Location | Purpose | Command |
|----------|----------|---------|---------|
| Shell History | `~/.bash_history` | Commands executed | `cat ~/.bash_history` |
| Vim History | `~/.viminfo` | Vim commands, files edited | `cat ~/.viminfo` |
| Recently Used | `~/.local/share/recently-used.xbel` | GUI file access | `cat recently-used.xbel` |
| Audit Logs | `/var/log/audit/audit.log` | Syscall auditing | `ausearch -m EXECVE` |
| Process Acct | `/var/log/pacct` | Process accounting | `lastcomm` |

### 2. Persistence Artifacts

| Artifact | Location | Purpose | Command |
|----------|----------|---------|---------|
| User Crontab | `/var/spool/cron/crontabs/` | User scheduled tasks | `crontab -l` |
| System Cron | `/etc/cron.d/`, `/etc/crontab` | System scheduled tasks | `cat /etc/crontab` |
| Systemd User | `~/.config/systemd/user/` | User services | `systemctl --user list-units` |
| Systemd System | `/etc/systemd/system/` | System services | `systemctl list-units` |
| SSH Keys | `~/.ssh/authorized_keys` | SSH persistence | `cat authorized_keys` |
| Shell RC | `~/.bashrc`, `~/.profile` | Shell startup | `cat ~/.bashrc` |
| ld.so.preload | `/etc/ld.so.preload` | Library injection | `cat /etc/ld.so.preload` |
| Init Scripts | `/etc/init.d/`, `/etc/rc.local` | Boot scripts | `ls /etc/init.d/` |

### 3. Privilege Escalation Artifacts

| Artifact | Location | Purpose | Command |
|----------|----------|---------|---------|
| SUID Binaries | Various | Privilege escalation | `find / -perm -4000` |
| Capabilities | Various | Fine-grained privs | `getcap -r /` |
| Sudoers | `/etc/sudoers`, `/etc/sudoers.d/` | Sudo rules | `cat /etc/sudoers` |
| Polkit Rules | `/etc/polkit-1/` | PolicyKit rules | `ls /etc/polkit-1/` |

### 4. Network Artifacts

| Artifact | Location | Purpose | Command |
|----------|----------|---------|---------|
| SSH Known Hosts | `~/.ssh/known_hosts` | Outbound SSH | `cat ~/.ssh/known_hosts` |
| SSH Auth Keys | `~/.ssh/authorized_keys` | Inbound SSH | `cat authorized_keys` |
| Hosts File | `/etc/hosts` | DNS overrides | `cat /etc/hosts` |
| Resolv.conf | `/etc/resolv.conf` | DNS servers | `cat /etc/resolv.conf` |
| Network Configs | `/etc/network/`, `/etc/netplan/` | Network setup | Varies |
| IPTables Rules | Runtime + saved | Firewall rules | `iptables -L -n` |

### 5. Authentication Artifacts

| Artifact | Location | Purpose | Command |
|----------|----------|---------|---------|
| wtmp | `/var/log/wtmp` | Successful logins | `last` |
| btmp | `/var/log/btmp` | Failed logins | `lastb` |
| lastlog | `/var/log/lastlog` | Per-user last login | `lastlog` |
| auth.log | `/var/log/auth.log` | Auth events | `cat auth.log` |
| secure | `/var/log/secure` | Auth (RHEL) | `cat secure` |
| shadow | `/etc/shadow` | Password hashes | `cat /etc/shadow` |

### 6. Filesystem Artifacts

| Artifact | Location | Purpose | Command |
|----------|----------|---------|---------|
| MAC Times | Inode | File timestamps | `stat <file>` |
| Birth Time | Inode (ext4) | Creation time | `debugfs` |
| Extended Attrs | Inode | Hidden metadata | `getfattr` |
| Hard Links | Inode | Shared files | `find -links +1` |
| Deleted Files | /proc/[pid]/fd | Open but deleted | `lsof +L1` |

### 7. Memory Artifacts (via /proc)

| Artifact | Location | Purpose | Command |
|----------|----------|---------|---------|
| Executable | `/proc/[pid]/exe` | Binary (even if deleted) | `ls -la /proc/*/exe` |
| File Descriptors | `/proc/[pid]/fd/` | Open files | `ls -la /proc/*/fd/` |
| Memory Maps | `/proc/[pid]/maps` | Loaded libraries | `cat /proc/*/maps` |
| Command Line | `/proc/[pid]/cmdline` | Original args | `cat cmdline` |
| Environment | `/proc/[pid]/environ` | Env variables | `cat environ` |
| CWD | `/proc/[pid]/cwd` | Working directory | `readlink cwd` |
| Login UID | `/proc/[pid]/loginuid` | Original user | `cat loginuid` |

---

## Artifact Locations by Directory

### /home/user/
```
.bash_history      - Command history
.bashrc            - Shell config (persistence)
.bash_logout       - Logout script (anti-forensics)
.viminfo           - Vim history
.ssh/              - SSH keys and known hosts
.local/share/      - User data (recently-used.xbel, Trash)
.config/           - Application configs
.gnupg/            - GPG keys
.mozilla/          - Firefox data
```

### /var/log/
```
auth.log           - Authentication (Debian/Ubuntu)
secure             - Authentication (RHEL/CentOS)
syslog             - System events
messages           - General messages
wtmp               - Login records (binary)
btmp               - Failed logins (binary)
lastlog            - Last login per user (binary)
audit/audit.log    - Audit daemon logs
apt/               - Package manager logs
```

### /proc/[pid]/
```
exe                - Link to executable
fd/                - Open file descriptors
maps               - Memory mappings
cmdline            - Command line arguments
environ            - Environment variables
cwd                - Current working directory
root               - Root directory
status             - Process status
loginuid           - Original login UID
```

### /etc/
```
passwd             - User accounts
shadow             - Password hashes
group              - Group memberships
sudoers            - Sudo rules
crontab            - System cron
hosts              - DNS overrides
ld.so.preload      - Library preloading
systemd/system/    - Systemd units
ssh/               - SSH server config
```

---

## Quick Reference: What to Check First

### Initial Triage Checklist
1. `w` / `who` - Who's logged in now?
2. `last` - Recent logins
3. `ps auxf` - Running processes
4. `netstat -tunapl` - Network connections
5. `cat /etc/passwd` - Any new users?
6. `find / -perm -4000` - SUID binaries
7. `crontab -l` + `/etc/cron.*` - Scheduled tasks
8. `~/.ssh/authorized_keys` - SSH keys
9. `~/.bash_history` - Command history
10. `ls -la /tmp /var/tmp /dev/shm` - Hidden files
