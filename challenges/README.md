# Linux Forensics & IR Lab - Challenges

## Scenario Background

You are responding to an incident at a web hosting company. Their monitoring detected suspicious outbound connections from a web server. Initial triage suggests the `webadmin` account was compromised.

**Your mission**: Investigate the system, reconstruct the attack timeline, identify persistence mechanisms, and determine the scope of compromise.

---

## Challenge Categories

### Category 1: Filesystem Timestamps (MAC Times)
### Category 2: Extended Attributes
### Category 3: Inode Analysis
### Category 4: Process Forensics (/proc)
### Category 5: Binary Artifacts (wtmp/btmp/lastlog)
### Category 6: Shell Artifacts
### Category 7: Persistence Mechanisms
### Category 8: ELF Binary Analysis
### Category 9: Privilege Escalation Artifacts
### Category 10: Anti-Forensics Detection

---

## Start Here

1. Start the lab container:
   ```bash
   docker build -t forensics-lab ./lab
   docker run -it --name ir-investigation forensics-lab
   ```

2. Once inside, run the runtime artifacts script:
   ```bash
   /plant_artifacts.sh
   ```

3. Begin with Challenge 01 and work through them in order.

Good luck, investigator!
