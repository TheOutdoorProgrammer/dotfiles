#!/bin/bash
set -u

# Clear OBS's stale run marker before launching: OBS segfaults on quit and never
# removes it, which is what triggers the safe-mode prompt. Crashes are still
# recorded in ~/Library/Logs/DiagnosticReports/OBS-*.ips.
if ! pgrep -x OBS >/dev/null; then
	rm -f "$HOME/Library/Application Support/obs-studio/.sentinel"/run_*
fi

shortcuts run "Open OBS"
