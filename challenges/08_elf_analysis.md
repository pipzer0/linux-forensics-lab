# Challenge 08: ELF Binary Analysis

## Objective
Analyze suspicious ELF binaries for compilation timestamps, origin indicators, and malicious characteristics.

## Background
ELF (Executable and Linkable Format) binaries contain metadata:
- Compilation timestamps (in some cases)
- Linked libraries
- Section information
- Embedded strings
- Debug symbols (if not stripped)

---

## Tasks

### Task 8.1: Basic Binary Information
```bash
# What type of file?
file /tmp/.hidden/malware_sim
file /tmp/.hidden/beacon
file /usr/local/bin/syshealth

# Is it stripped?
file /tmp/.hidden/malware_sim | grep -i strip
```

---

### Task 8.2: Strings Analysis
Extract readable strings from binaries:

```bash
# All strings
strings /tmp/.hidden/malware_sim

# Look for IPs, URLs, paths
strings /tmp/.hidden/malware_sim | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}"
strings /tmp/.hidden/malware_sim | grep -E "https?://"
strings /tmp/.hidden/malware_sim | grep -E "^/"

# Unicode strings (wide characters)
strings -el /tmp/.hidden/malware_sim
```

**Questions**:
1. What C2 server is embedded in the binary?
2. What interesting strings indicate malicious behavior?

---

### Task 8.3: ELF Header Analysis
```bash
# ELF header details
readelf -h /tmp/.hidden/malware_sim

# Section headers
readelf -S /tmp/.hidden/malware_sim

# Program headers
readelf -l /tmp/.hidden/malware_sim

# Symbol table (if not stripped)
readelf -s /tmp/.hidden/malware_sim
```

---

### Task 8.4: Linked Libraries
```bash
# Dynamic dependencies
ldd /tmp/.hidden/malware_sim

# Dynamic section
readelf -d /tmp/.hidden/malware_sim

# Look for unusual libraries
```

**Red flags**:
- No standard libraries (statically compiled = evasion)
- Unusual library paths
- Libraries from /tmp, /dev/shm

---

### Task 8.5: Debug Information
```bash
# DWARF debug info (if available)
readelf --debug-dump /tmp/.hidden/malware_sim

# Build ID
readelf -n /tmp/.hidden/malware_sim

# Check for debug symbols
objdump -t /tmp/.hidden/malware_sim | head -20
```

---

### Task 8.6: Objdump Disassembly
```bash
# Disassemble main function
objdump -d /tmp/.hidden/malware_sim | grep -A 50 "<main>"

# All disassembly
objdump -d /tmp/.hidden/malware_sim
```

---

### Task 8.7: Compare with Known Good
```bash
# Hash the suspicious binary
sha256sum /tmp/.hidden/malware_sim

# Check against VirusTotal (concept - not in lab)
# Submit hash to: https://www.virustotal.com

# Compare file sizes
ls -la /tmp/.hidden/
```

---

## Key Commands Reference

```bash
# File type
file <binary>

# Strings
strings <binary>
strings -n 10 <binary>     # Minimum 10 chars
strings -el <binary>       # Little-endian unicode

# ELF analysis
readelf -a <binary>        # All info
readelf -h <binary>        # Header
readelf -S <binary>        # Sections
readelf -s <binary>        # Symbols
readelf -d <binary>        # Dynamic
readelf -n <binary>        # Notes (build ID)

# Dependencies
ldd <binary>

# Disassembly
objdump -d <binary>
objdump -D <binary>        # All sections
objdump -t <binary>        # Symbol table

# Hex dump
xxd <binary> | head
hexdump -C <binary> | head

# Hash
sha256sum <binary>
md5sum <binary>
```

---

## Red Flags in Binary Analysis

| Indicator | Meaning |
|-----------|---------|
| Statically linked | Trying to avoid library dependencies/detection |
| Stripped symbols | Making analysis harder |
| UPX packed | Compressed/obfuscated |
| No build ID | Possibly modified |
| Embedded IPs/URLs | C2 communication |
| /dev/shm paths | Using shared memory for hiding |
| Base64 strings | Encoded payloads |
| /proc/self | Self-modification techniques |

---

## Why This Matters

1. **Attribution**: Compiler info, language, author strings.

2. **C2 Extraction**: Find hardcoded C2 servers.

3. **Capability Assessment**: What can this malware do?

4. **IOC Generation**: Hashes, strings for detection.

5. **Comparison**: Compare to known malware families.
