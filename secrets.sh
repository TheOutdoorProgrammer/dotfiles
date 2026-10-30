#!/bin/zsh

# Fetch all secrets in parallel to avoid serial 1Password CLI latency
setopt LOCAL_OPTIONS NO_MONITOR
_secrets_tmp=$(mktemp -d)
_secrets_pids=()
typeset -A _secrets_labels

# Usage: _fetch <outfile> <command> [args...]
# stderr is kept (not discarded) so a failure can report why, not just that.
_fetch() {
  local outfile=$1; shift
  "$@" > "$_secrets_tmp/$outfile" 2>"$_secrets_tmp/$outfile.err" &
  _secrets_pids+=($!)
  _secrets_labels[$!]=$outfile
}

# IDs avoid namespace metadata lookups before value-cache reads.
_fetch github_token  joey vault get "eti7veefjbh2lkbmmd3ii3fgta" # /github/personal-access-token
_fetch dockerhub     joey vault get "mt3hlq7gcubnmba5wdflttpndy" # /dockerhub/credentials
_fetch openai        joey vault get "3s3aqs5fbbdr4jxnoe7d4wjfgy" # /openai/api-key
_fetch cloudflare    joey vault get "ro7e5rqpggqsrbv6v52paix6h4" # /cloudflare/api-key
_fetch smithery      joey vault get "mgys56ehycapbue3pbfqjpfcaa" # /smithery/api-key
_fetch perplexity    joey vault get "gsktjnpyyjbxinv74oklcz6a4e" # /perplexity/api-key
_fetch obsidian      joey vault get "ndv6nvpgwczwydfzx7robs2t3q" # /obsidian/api-key
_fetch slack         joey vault get "bd6ikr33degbuaymfslsw6akra" # /slack/workspace-url
_fetch gemini        joey vault get "fw2dvqodudg7fo3hpgzaojmafe" # /gemini/api-key
_fetch airtrail      joey vault get "inzb3rmmzzdegjrwarjojxlmfi" # /airtrail/api-key
_fetch dusk_mcp      joey vault get "2qdtswjhsvxp43jtxru3kgxp4y" # /dusk/mcp-token
_fetch fledge        joey vault get "5fd2fop5cyo7ugyprz3lalasra" # /fledge/upload-token
_fetch posthog       joey vault get "nzbrmnoymgxw3jksqx6bwtfj3e" # /posthog/personal-api-key
#_fetch litellm       joey vault get "v7o76mv5nyougddegizm2ekdmi" # /litellm/api-key
#_fetch litellm_work  joey vault get "xaumelpfliqdt4wywakzethkhe" # /litellm/work/api-key

# Watchdog: kill any stragglers after 60s
( sleep 60; kill $_secrets_pids 2>/dev/null ) &
_secrets_watchdog=$!

# Wait for all secret fetches, recording which ones failed and with what status
_secrets_failed=()
typeset -A _secrets_rcs
for _pid in $_secrets_pids; do
  wait $_pid 2>/dev/null
  _rc=$?
  (( _rc == 0 )) && continue
  _secrets_failed+=("$_secrets_labels[$_pid]")
  _secrets_rcs[$_secrets_labels[$_pid]]=$_rc
done

# Clean up the watchdog
kill $_secrets_watchdog 2>/dev/null
wait $_secrets_watchdog 2>/dev/null

if (( $#_secrets_failed )); then
  print -P "%F{yellow}⚠ ${#_secrets_failed} of ${#_secrets_pids} secrets failed%f" >&2
  for _f in $_secrets_failed; do
    # A watchdog SIGTERM surfaces as 143; anything else is the tool's own failure.
    if (( _secrets_rcs[$_f] == 143 )); then
      _why="timed out after 60s"
    else
      _why="exit ${_secrets_rcs[$_f]}"
      _lines=()
      [[ -s "$_secrets_tmp/$_f.err" ]] && _lines=(${(f)"$(<"$_secrets_tmp/$_f.err")"})
      (( $#_lines )) && _why="${_lines[-1]}"
    fi
    print -P "%F{yellow}    ${_f}: ${_why}%f" >&2
  done
fi

export GITHUB_TOKEN=$(<"$_secrets_tmp/github_token")
export DOCKERHUB_USERNAME="apollorion"
export DOCKERHUB_PASSWORD=$(<"$_secrets_tmp/dockerhub")
export OPENAI_API_KEY=$(<"$_secrets_tmp/openai")
export CLOUDFLARE_API_TOKEN=$(<"$_secrets_tmp/cloudflare")
export SMITHERY_API_KEY=$(<"$_secrets_tmp/smithery")
export PERPLEXITY_API_KEY=$(<"$_secrets_tmp/perplexity")
export OBSIDIAN_API_KEY=$(<"$_secrets_tmp/obsidian")
export SLACK_WORKSPACE_URL=$(<"$_secrets_tmp/slack")
export GEMINI_API_KEY=$(<"$_secrets_tmp/gemini")
export AIRTRAIL_API_KEY=$(<"$_secrets_tmp/airtrail")
export DUSK_MCP_TOKEN=$(<"$_secrets_tmp/dusk_mcp")
export FLEDGE_URL=https://fledge.theoutdoorprogrammer.com
export FLEDGE_TOKEN=$(<"$_secrets_tmp/fledge")
export POSTHOG_API_KEY=$(<"$_secrets_tmp/posthog")
#export LITELLM_API_KEY=$(<"$_secrets_tmp/litellm")
#export LITELLM_WORK_API_KEY=$(<"$_secrets_tmp/litellm_work")

#export ANTHROPIC_BASE_URL=https://ai.stout.zone
#export ANTHROPIC_CUSTOM_HEADERS="x-litellm-api-key: Bearer $LITELLM_WORK_API_KEY"

# Let stripped-environment agents and MCP processes reuse fetched credentials.
# Replace the private cache atomically only after the critical token resolves;
# a failed fetch must not clobber credentials that running agents depend on.
# Derive names from exports and isolate interactive options with `emulate`.
if [[ -n "$GITHUB_TOKEN" && -d "$HOME/.claude" ]]; then
  (
    emulate -L zsh
    umask 077
    _tmp=$(mktemp "$HOME/.claude/.teammate-secrets.XXXXXX") || exit
    # Pure-zsh parse, NOT grep/awk/cat: `grep` is aliased to ripgrep (reads -E as
    # --encoding) and `cat` to bat, so those silently break in the interactive shell.
    for _line in ${(f)"$(<"$HOME/secrets.sh")"}; do
      [[ $_line == 'export '[A-Za-z_]* ]] || continue
      _v=${${_line#export }%%=*}
      print -r -- "export ${_v}=${(qq)${(P)_v}}"
    done > "$_tmp"
    if [[ -s "$_tmp" ]]; then
      mv -f "$_tmp" "$HOME/.claude/teammate-secrets.env"
    else
      rm -f "$_tmp"
    fi
  )
fi

rm -rf "$_secrets_tmp"
unset _secrets_tmp _secrets_pids _secrets_labels _secrets_failed _secrets_rcs \
      _secrets_watchdog _pid _rc _f _why _lines
