# Linux Forensics Command Cheat Sheet

## Quick Reference Card

### Timestamp Analysis
```bash
# View all timestamps (mtime, atime, ctime)
stat <file>

# List with full timestamps
ls -la --full-time

# Find timestomped files (ctime much newer than mtime)
find / -type f -exec sh -c 'M=$(stat -c %Y "$1"); C=$(stat -c %Z "$1"); [ $((C-M)) -gt 86400 ] && stat "$1"' _ {} \; 2>/dev/null

# Files modified in time range
find / -newermt "2024-01-15 00:00" -not -newermt "2024-01-16 00:00" 2>/dev/null

# Birth time (ext4 only, needs debugfs)
debugfs -R "stat <$(stat -c %i file)>" /dev/sda1
```

### Extended Attributes
```bash
# View extended attributes
getfattr -d <file>
getfattr -d -m- <file>          # All namespaces

# Find files with capabilities
getcap -r / 2>/dev/null

# View SELinux context
ls -Z <file>
```

### Inode Analysis
```bash
# Show inode number
ls -i <file>
stat <file>

# Find file by inode
find / -inum <number> 2>/dev/null

# Find hard links (link count > 1)
find / -type f -links +1 -ls 2>/dev/null

# Find all hard links to a file
find / -samefile <file> 2>/dev/null
```

### Process Forensics (/proc)
```bash
# Recover deleted executable
ls -la /proc/*/exe 2>/dev/null | grep deleted
cp /proc/<pid>/exe /tmp/recovered

# View deleted-but-open files
ls -la /proc/<pid>/fd/
cat /proc/<pid>/fd/<num>

# Environment variables
cat /proc/<pid>/environ | tr '\0' '\n'

# Command line
cat /proc/<pid>/cmdline | tr '\0' ' '; echo

# Memory maps
cat /proc/<pid>/maps

# Login UID (survives sudo/su!)
cat /proc/<pid>/loginuid

# Current working directory
readlink /proc/<pid>/cwd

# Find open deleted files system-wide
lsof +L1
```

### Binary Login Records
```bash
# Successful logins
last
last -F                    # Full timestamps
last -i                    # Show IPs

# Failed logins (requires root)
lastb

# Last login per user
lastlog

# Currently logged in
who
w

# Raw dump for analysis
utmpdump /var/log/wtmp
```

### Shell Artifacts
```bash
# Bash history
cat ~/.bash_history

# All history files
find /home -name ".*history*" 2>/dev/null

# Vim artifacts
cat ~/.viminfo

# Find swap files
find / -name "*.swp" -o -name "*.swo" 2>/dev/null

# Anti-forensics detection
grep -r "HISTFILE\|history -c" /home/ 2>/dev/null
```

### Persistence Locations
```bash
# Cron
cat /var/spool/cron/crontabs/*
cat /etc/cron.d/*
crontab -l -u <user>

# Systemd
find /home -path "*/.config/systemd/user/*.service" 2>/dev/null
ls /etc/systemd/system/
systemctl list-unit-files --type=service

# SSH keys
find / -name "authorized_keys" 2>/dev/null

# Library hijacking
cat /etc/ld.so.preload
ldd /bin/ls

# Shell profiles
cat /home/*/.bashrc /home/*/.profile /home/*/.bash_logout

# Init scripts
cat /etc/rc.local
ls /etc/init.d/
```

### SUID/SGID & Capabilities
```bash
# Find SUID binaries
find / -perm -4000 -type f 2>/dev/null

# Find SGID binaries
find / -perm -2000 -type f 2>/dev/null

# Find capabilities
getcap -r / 2>/dev/null

# Check sudo rules
sudo -l
cat /etc/sudoers
```

### ELF Binary Analysis
```bash
# File type
file <binary>

# Strings
strings <binary>
strings -n 10 <binary>      # Min 10 chars
strings <binary> | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}"  # IPs

# ELF headers
readelf -h <binary>         # Header
readelf -S <binary>         # Sections
readelf -s <binary>         # Symbols
readelf -d <binary>         # Dynamic

# Dependencies
ldd <binary>

# Disassembly
objdump -d <binary>

# Hash
sha256sum <binary>
md5sum <binary>
```

### Network Artifacts
```bash
# Current connections
ss -tunapl
netstat -tunapl

# Hosts file
cat /etc/hosts

# DNS configuration
cat /etc/resolv.conf

# ARP cache
arp -a
ip neigh

# Routing
ip route
route -n
```

### File Recovery Concepts
```bash
# Deleted file still open
lsof +L1
cat /proc/<pid>/fd/<num>

# Sleuthkit (for disk images)
fls image.dd               # List files
icat image.dd <inode>      # Cat by inode
ils image.dd               # List inodes

# Foremost/photorec (carving)
foremost -i image.dd -o output/
```

### Log Locations
```bash
# System logs
/var/log/syslog
/var/log/messages
/var/log/auth.log
/var/log/secure

# Binary logs
/var/log/wtmp              # last
/var/log/btmp              # lastb
/var/log/lastlog           # lastlog

# Application logs
/var/log/apache2/
/var/log/nginx/
/var/log/mysql/

# Audit logs
/var/log/audit/audit.log

# Journal
journalctl
```

### Hidden/Suspicious Locations
```bash
# Common hiding spots
/tmp/.*
/var/tmp/.*
/dev/shm/.*
/run/.*

# Find hidden files
find /tmp /var/tmp /dev/shm -name ".*" 2>/dev/null

# World-writable directories
find / -type d -perm -002 2>/dev/null
```
