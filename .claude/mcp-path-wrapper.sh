#!/bin/bash
# Prepend the dirs cmux strips from team-agent PATH so npx/bun/node resolve, load
# cached secrets (teammates can't reach 1Password), then exec the real MCP command.
# See ~/.claude/plans/dazzling-honking-nebula.md for the why.
# shellcheck disable=SC1091
[ -r "$HOME/.claude/teammate-secrets.env" ] && . "$HOME/.claude/teammate-secrets.env"
export PATH="/opt/homebrew/bin:/Users/joeystout/.bun/bin:/Users/joeystout/.local/bin:$PATH"
exec "$@"
