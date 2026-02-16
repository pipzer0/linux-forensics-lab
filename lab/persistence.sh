#!/bin/bash
# Simulated persistence mechanism for forensics training
# This creates ARTIFACTS only - no actual persistence

# Marker that this ran
echo "[$(date -Iseconds)] Persistence script executed" >> /tmp/.persistence_log

# Simulated actions (these create forensic artifacts)
echo "# Simulated malicious cron entry" > /dev/null
echo "*/5 * * * * /tmp/.hidden/beacon >/dev/null 2>&1" > /dev/null

# Would modify these files (we'll create artifacts showing this)
# - /etc/cron.d/
# - ~/.ssh/authorized_keys
# - /etc/ld.so.preload
# - systemd user services

exit 0
