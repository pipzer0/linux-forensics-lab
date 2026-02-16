# Challenge 01: Filesystem Timestamps

## Objective
Use filesystem timestamps to reconstruct the attack timeline.

## Background
Linux filesystems (ext4) track multiple timestamps:
- **mtime**: Last modification time (content changed)
- **atime**: Last access time (content read)
- **ctime**: Last status change (metadata changed - permissions, ownership, rename)
- **crtime/birth**: Creation time (ext4 only, requires debugfs)

**Key insight**: `touch` can modify mtime/atime, but **ctime cannot be faked** (requires filesystem-level access).

---

## Tasks

### Task 1.1: Find Timestomped Files
An attacker often uses `touch` to make malicious files appear old. Find files where:
- The mtime looks "too old" compared to ctime
- The file content doesn't match its apparent age

**Hint**: Use `stat` to view all timestamps.

```bash
# Your commands here
stat /etc/app.conf
```

**Questions**:
1. What file has been timestomped?
2. What is the real creation/change time vs the faked modification time?

---

### Task 1.2: Birth Time Analysis
On ext4, you can find the true creation time (crtime/birth) using debugfs.

```bash
# Find which device the filesystem is on
df -h /

# Use debugfs to get birth time (requires root)
# Find inode first
ls -i /path/to/file

# Then query debugfs
debugfs -R "stat <inode>" /dev/sda1

#Without block device 
stat -c 'path=%n inode=%i btime=%w mtime=%y ctime=%z atime=%x' ./path/to/file
```
**Note**: Note: In Docker, / is commonly overlayfs (e.g., SOURCE=overlay, FSTYPE=overlay) and you typically won’t have access to the host’s raw backing storage (or a stable 1:1 inode mapping) from inside the container. The concept is what matters; run low-level filesystem queries from the host against the backing storage.

**ZFS caveat**: debugfs only works on ext2/3/4 block devices. If df -T shows Type=zfs and SOURCE looks like a dataset (e.g., rpool/...), use stat/zdb instead of debugfs to inspect creation/metadata timestamps.

---

### Task 1.3: Timeline Construction
Using timestamps, put these events in chronological order:
- Webshell creation
- Reconnaissance script download
- Privilege escalation
- Persistence installation
- Cleanup attempts

```bash
# Find files modified on the attack date
find / -newermt "2024-01-15 00:00:00" -not -newermt "2024-01-16 00:00:00" 2>/dev/null

# Or use stat on suspicious files
stat /var/www/html/.shell.php
stat /tmp/linpeas.sh
stat /tmp/.hidden/beacon
```

---

## Key Commands Reference

```bash
# View all timestamps
stat <file>

# Find files by time ranges
find / -mtime -7          # Modified in last 7 days
find / -newermt "date"    # Modified after date
find / -cmin -60          # Changed in last 60 minutes

# List with full timestamps
ls -la --full-time

# Compare mtime and ctime (find timestomping)
find <location> -type f -exec sh -c 'M=$(stat -c %Y "$1"); C=$(stat -c %Z "$1"); [ $((C - M)) -gt 86400 ] && echo "$1"' _ {} \; 2>/dev/null
```
