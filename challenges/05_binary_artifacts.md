# Challenge 05: Binary Login Records

## Objective
Analyze binary login artifacts (wtmp, btmp, lastlog) to trace attacker authentication activity.

## Background
Unlike text logs, these are **binary structured files**:
- `/var/log/wtmp` - Successful logins (read with `last`)
- `/var/log/btmp` - Failed logins (read with `lastb`)
- `/var/log/lastlog` - Last login time per user (read with `lastlog`)
- `/var/run/utmp` - Currently logged in users (read with `who`)

**Key insight**: Attackers often forget to clean these, or cleaning them leaves evidence!

---

## Tasks

### Task 5.1: Analyze Successful Logins
```bash
# View all logins
last

# From specific file
last -f /var/log/wtmp

# Show IP addresses
last -i

# Show all (including still logged in)
last -a

# Specific user
last webadmin
```

**Questions**:
1. What users have logged into the system?
2. Any logins from unusual IP addresses?
3. Any logins at unusual times?

---

### Task 5.2: Analyze Failed Logins
```bash
# View failed logins (needs root)
lastb
lastb -f /var/log/btmp

# Failed logins for specific user
lastb webadmin
```

**Look for**:
- Brute force attempts (many failures)
- Failures just before success (password spray found valid creds)
- Failures from attacker IP

---

### Task 5.3: Last Login Per User
```bash
# View last login time for all users
lastlog

# This shows accounts that have NEVER logged in
# (useful for finding dormant accounts attackers might target)
```

---

### Task 5.4: Currently Logged In
```bash
# Currently logged in users
who
w

# From utmp file
who /var/run/utmp
```

---

### Task 5.5: Detect Tampering
Signs of log tampering:

```bash
# Check file timestamps
stat /var/log/wtmp
stat /var/log/btmp

# File size changes unexpectedly?
ls -la /var/log/wtmp

# Gaps in login records (use last with timestamps)
last -F  # Full timestamps

# Tool: utmpdump for raw examination
utmpdump /var/log/wtmp
```

**Signs of tampering**:
- wtmp file smaller than expected
- Gaps in login sequence
- ctime newer than expected (file was modified)

---

## Key Commands Reference

```bash
# Successful logins
last                    # Default wtmp
last -f /var/log/wtmp   # Specify file
last -F                 # Full date/time
last -i                 # Show IP addresses
last -x                 # Show shutdowns/runlevel changes
last <user>             # Specific user

# Failed logins (requires root)
lastb
lastb -f /var/log/btmp

# Last login per user
lastlog
lastlog -u <user>

# Currently logged in
who
w
who -a                  # All info

# Raw dump for analysis
utmpdump /var/log/wtmp
utmpdump /var/log/btmp

# File examination
stat /var/log/wtmp
ls -la /var/log/wtmp
file /var/log/wtmp
```

---

## Structure of utmp/wtmp Records

Each record contains:
- **ut_type**: Login type (LOGIN_PROCESS, USER_PROCESS, etc.)
- **ut_pid**: Process ID
- **ut_line**: TTY name
- **ut_user**: Username
- **ut_host**: Remote host
- **ut_time**: Timestamp

---

## Why This Matters

1. **Binary = Harder to Tamper**: Attackers can't just sed/grep these files.

2. **IP Attribution**: Source IPs of logins.

3. **Timeline**: Login/logout times help reconstruct events.

4. **Brute Force Detection**: Failed login patterns.

5. **Gap Analysis**: Missing records indicate tampering.
