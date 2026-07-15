# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

## Meta Commands (always use rtk directly)

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```

## Installation Verification

```bash
rtk --version         # Should show: rtk X.Y.Z
rtk gain              # Should work (not "command not found")
which rtk             # Verify correct binary
```

⚠️ **Name collision**: If `rtk gain` fails, you may have reachingforthejack/rtk (Rust Type Kit) installed instead.

## Hook-Based Usage

All other commands are automatically rewritten by the Claude Code hook.
Example: `go test ./...` → `rtk go test ./...` (transparent, 0 tokens overhead)

`git`, `yadm`, and `diff` are excluded from rewriting (`exclude_commands` in
`~/Library/Application Support/rtk/config.toml`): RTK's rewrite ran yadm
against the cwd repo instead of the yadm repo and masked diff exit codes —
unacceptable for verification work. Don't remove them from the exclude list.
`rtk hook check "<cmd>"` dry-runs the rewrite; `rtk proxy <cmd>` bypasses
filtering for any command.

Refer to CLAUDE.md for full command reference.
