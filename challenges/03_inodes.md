# Challenge 03: Inode Analysis

## Objective
Use inode analysis to detect hard links, find deleted files, and identify suspicious file relationships.

## Background
Every file on Linux has an **inode** - a data structure containing:
- File size, permissions, ownership
- Timestamps
- Pointers to data blocks
- **Link count** (how many filenames point to this inode)

**Key insight**: Hard links share the same inode. If you find the same inode in two locations, it's the SAME file!

---

## Tasks

### Task 3.1: Detect Hard Links
Attackers create hard links to:
- Have the same malware accessible from multiple paths
- Survive deletion (file exists until ALL links are removed)
- Confuse investigators

```bash
# List files with inode numbers
ls -lai /tmp/.hidden/
ls -lai /var/tmp/.cache/

# Find all files with same inode
find / -inum <inode_number> 2>/dev/null

# Find files with more than one hard link
find / -type f -links +1 2>/dev/null
```

**Questions**:
1. Find two files that are actually the same file (same inode).
2. What are their paths?
3. Why would an attacker do this?

---

### Task 3.2: Inode Number Analysis
Inodes are assigned sequentially. Large gaps in inode numbers in the same directory can indicate:
- Deleted files
- File system manipulation
- Evidence of cleanup

```bash
# List inodes in a directory
ls -lai /tmp/

# Check inode allocation
stat <file>  # Shows inode in output

# On ext4, view inode table
# debugfs -R "ls -l" /dev/sda1
```

---

### Task 3.3: Deleted File Recovery Concepts
When a file is deleted:
1. Directory entry is removed
2. Inode is marked as free
3. **Data blocks are NOT immediately overwritten**

Recovery tools:
- `extundelete` - ext3/ext4 recovery
- `photorec` - file carving
- `foremost` - file carving
- `sleuthkit` - comprehensive forensics suite

```bash
# List deleted inodes (requires unmounted or read-only FS)
# debugfs -R "lsdel" /dev/sda1

# In this lab, we demonstrate the concept
cat /forensics_note_inode_gaps
```

---

## Key Commands Reference

```bash
# Show inode number
ls -i <file>
stat <file>

# Find file by inode
find / -inum <number> 2>/dev/null

# Find all hard links (files with link count > 1)
find / -type f -links +1 -ls 2>/dev/null

# Find all hard links to a specific file
find / -samefile /path/to/file 2>/dev/null

# Low-level inode examination (ext4)
# debugfs -R "stat <inode>" /dev/sda1
# debugfs -R "cat <inode>" /dev/sda1  # Dump file content by inode

# Sleuthkit tools
# istat image.dd <inode>  # Inode statistics
# icat image.dd <inode>   # Cat file by inode
```

---

## Why This Matters

1. **Hard Link Detection**: Same file, different names = suspicious

2. **Timeline Gaps**: Deleted files leave inode gaps

3. **Data Recovery**: Deleted ≠ Gone. Data persists until overwritten.

4. **Evidence Correlation**: Same inode = same file, even if renamed/moved
