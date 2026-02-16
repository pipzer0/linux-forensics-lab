#!/bin/bash
# Additional runtime artifacts that need a running system
# Run this AFTER container is started for full experience

echo "[*] Planting runtime artifacts..."

# Create a background process that simulates deleted-but-running malware
(
    # This demonstrates /proc/[pid]/exe forensics
    while true; do
        sleep 3600
    done
) &
BEACON_PID=$!
echo "[+] Beacon simulator running as PID $BEACON_PID"

# Create a process with suspicious environment variables
(
    export C2_SERVER="198.51.100.47"
    export BEACON_KEY="s3cr3tk3y"
    export EXFIL_PATH="/tmp/data"
    while true; do
        sleep 3600
    done
) &
ENV_PID=$!
echo "[+] Process with suspicious env vars running as PID $ENV_PID"

# Open a file then delete it (recoverable via /proc/fd)
(
    exec 3>/tmp/.secret_data
    echo "Exfiltrated credentials:" >&3
    echo "admin:SuperSecret123" >&3
    echo "root:RootPassword!" >&3
    rm /tmp/.secret_data
    # File is deleted but fd 3 still has it open
    while true; do
        sleep 3600
    done
) &
FD_PID=$!
echo "[+] Deleted-but-open file demo running as PID $FD_PID"

# Save PIDs for cleanup
echo "$BEACON_PID" >> /var/run/forensics_demo_pids
echo "$ENV_PID" >> /var/run/forensics_demo_pids
echo "$FD_PID" >> /var/run/forensics_demo_pids

echo ""
echo "[*] Runtime artifacts planted. Use these PIDs for /proc forensics:"
echo "    Beacon simulator: $BEACON_PID"
echo "    Suspicious env:   $ENV_PID"
echo "    Deleted file:     $FD_PID (check /proc/$FD_PID/fd/)"
echo ""
echo "[*] Try: ls -la /proc/$FD_PID/fd/"
echo "[*] Try: cat /proc/$FD_PID/fd/3"
