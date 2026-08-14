#!/bin/bash
set -u

shortcuts run "Quit OBS"

# OBS segfaults on the way out, so the quit is best effort: wait for the
# process to really go, and escalate if it hangs instead of exiting.
for _ in $(seq 1 60); do
	pgrep -x OBS >/dev/null || exit 0
	sleep 0.25
done

pkill -x OBS
sleep 3
pkill -9 -x OBS 2>/dev/null || true
