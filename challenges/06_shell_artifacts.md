# Challenge 06: Shell Artifacts

## Objective
Extract attacker commands and activities from shell history and related artifacts.

## Background
Shell artifacts are goldmines for IR:
- Command history files
- Shell configuration files
- Vim/editor artifacts
- Screen/tmux sessions

---

## Tasks

### Task 6.1: Bash History Analysis
```bash
# Read bash history
cat /home/webadmin/.bash_history
cat /home/developer/.bash_history

# History with timestamps (if HISTTIMEFORMAT was set)
HISTTIMEFORMAT="%F %T " history

# Look for anti-forensics attempts
grep -E "(history|HIST)" /home/*/.bash_history
grep -E "(history|HIST)" /home/*/.bashrc
grep -E "(history|HIST)" /home/*/.bash_logout
```

**Questions**:
1. What reconnaissance did the attacker perform?
2. What tools did they download?
3. What privilege escalation attempts were made?
4. Did they try to clear history?

---

### Task 6.2: Shell Configuration Files
Attackers modify these for persistence or to disable logging:

```bash
# Check for history-disabling
cat /home/webadmin/.bashrc | grep -i hist
cat /home/webadmin/.bash_logout

# Check for aliases hiding malicious activity
grep alias /home/*/.bashrc

# Check for modified PATH
grep PATH /home/*/.bashrc /home/*/.profile
```

**Look for**:
- `unset HISTFILE`
- `HISTSIZE=0`
- `HISTFILESIZE=0`
- Malicious aliases (`alias sudo='...'`)
- Modified PATH to hijack commands

---

### Task 6.3: Vim Artifacts
Vim stores valuable forensic data:

```bash
# Viminfo - command history, search history, file marks
cat /home/webadmin/.viminfo

# Look for recently edited files
grep "^'" /home/webadmin/.viminfo

# Look for commands run from vim
grep "^:" /home/webadmin/.viminfo

# Swap files (unsaved changes)
find /home -name "*.swp" -o -name "*.swo" 2>/dev/null

# Undo files
find /home -name ".*.un~" 2>/dev/null
ls /home/webadmin/.vim/undodir/
```

**Questions**:
1. What files did the attacker edit in vim?
2. What commands did they run from vim (`:!command`)?
3. Any swap files showing incomplete edits?

---

### Task 6.4: Other Shell History Files
```bash
# Zsh history
cat /home/*/.zsh_history

# Fish history
cat /home/*/.local/share/fish/fish_history

# MySQL history
cat /home/*/.mysql_history

# Python history
cat /home/*/.python_history

# PSql history
cat /home/*/.psql_history

# Less history
cat /home/*/.lesshst
```

---

### Task 6.5: Screen/Tmux Sessions
```bash
# Screen sessions
screen -ls

# Screen config
cat /home/*/.screenrc

# Tmux sessions
tmux list-sessions 2>/dev/null

# Tmux resurrect (saved sessions)
ls /home/*/.tmux/resurrect/
```

---

## Key Commands Reference

```bash
# History files
cat ~/.bash_history
cat ~/.zsh_history

# With timestamps (if configured)
HISTTIMEFORMAT="%F %T " history

# Check history settings
grep HIST ~/.bashrc
echo $HISTSIZE $HISTFILESIZE

# Vim artifacts
cat ~/.viminfo
find / -name "*.swp" 2>/dev/null

# Search all history files
find /home -name ".*history*" -exec cat {} \; 2>/dev/null

# Anti-forensics detection
grep -r "HISTFILE\|HISTSIZE\|history -c" /home/ 2>/dev/null
```

---

## Anti-Forensics Techniques to Detect

```bash
# Attacker commands that indicate cleanup
history -c              # Clear current session history
history -w              # Write history then clear
unset HISTFILE          # Don't save history
export HISTSIZE=0       # No history
export HISTFILESIZE=0   # No history file
ln -sf /dev/null ~/.bash_history  # Redirect to null
shred ~/.bash_history   # Secure delete
```

---

## Why This Matters

1. **Command Reconstruction**: See exactly what attacker did.

2. **Tool Identification**: What attack tools were used.

3. **Credential Discovery**: Passwords typed on command line.

4. **Lateral Movement**: SSH commands to other systems.

5. **Anti-Forensics Detection**: Cleanup attempts are themselves evidence.
