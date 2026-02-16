# Challenge 02: Extended Attributes (xattrs)

## Objective
Identify data hidden in extended file attributes and detect capability-based privilege escalation.

## Background
Extended attributes are name-value pairs attached to files, invisible to normal `ls` commands:

- **user.***: User-defined attributes (can store arbitrary data)
- **security.***: SELinux labels, capabilities
- **system.***: ACLs, POSIX capabilities
- **trusted.***: Trusted namespace (root only)

**Key insight**: Malware can hide C2 info, encryption keys, or payloads in xattrs!

---

## Tasks

### Task 2.1: Find Files with User Attributes
Attackers sometimes hide data in user.* extended attributes.

```bash
# List extended attributes on a file
getfattr -d /opt/webapp/config.dat

# Search for files with any extended attributes
getfattr -R -d /opt 2>/dev/null
getfattr -R -d /var 2>/dev/null
```

**Questions**:
1. What hidden data did you find in extended attributes?
2. What C2 server is referenced?

---

### Task 2.2: File Capabilities (Privilege Escalation)
Linux capabilities allow granular privileges without full root. Attackers abuse this.

**Dangerous capabilities**:
- `cap_setuid` - Can change UID (become root)
- `cap_net_raw` - Raw socket access (packet sniffing)
- `cap_dac_override` - Bypass file permission checks
- `cap_sys_admin` - Extremely powerful, near-root

```bash
# Check capabilities on a specific file
getcap /usr/local/bin/syshealth

# Find ALL files with capabilities set
getcap -r / 2>/dev/null

# Common legitimate binaries with caps:
# /usr/bin/ping - cap_net_raw
# /usr/bin/traceroute - cap_net_raw
```

**Questions**:
1. What suspicious binary has capabilities set?
2. What capability does it have and why is it dangerous?
3. Is this binary normally supposed to have this capability?

---

### Task 2.3: SELinux/AppArmor Labels
In systems with MAC (Mandatory Access Control), check security contexts:

```bash
# View SELinux context
ls -Z /var/www/html/

# Get security extended attributes
getfattr -n security.selinux /path/to/file 2>/dev/null
```

---

## Key Commands Reference

```bash
# List all extended attributes (verbose)
getfattr -d -m- <file>

# Get specific attribute
getfattr -n user.payload <file>

# Recursively find files with xattrs
getfattr -R -d -m- /path 2>/dev/null | grep -B1 "^user\."

# Find files with capabilities
getcap -r / 2>/dev/null

# Set capability (for understanding, don't run)
# setcap cap_setuid+ep /path/to/binary

# Remove capabilities
# setcap -r /path/to/binary
```

---

## Why This Matters

1. **Hidden Data**: Xattrs are not shown by ls, cat, or most tools. Perfect for hiding C2 configs.

2. **Capability Abuse**: Unlike SUID, capabilities are fine-grained and often overlooked in security audits.

3. **Persistence**: An attacker can add cap_setuid to any binary, creating a subtle backdoor.

4. **SELinux Bypass**: Mislabeled files might bypass MAC controls.
