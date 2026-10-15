# Shared settings and helpers for the capture scripts. Sourced, not run.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The Kanna the captures run in: its own app, daemon, keeper, terminals and
# kanna.db, all in one folder. Not `--instance NAME`: an instance with a name
# puts it in every window's title ("Shelf · capture"). A daemon in a folder
# that isn't a channel's (kanna-prod-NAME, ...) names itself `default`, and the
# default instance's title has no suffix.
APP="${CAPTURE_APP:-/Applications/Kanna.app}"
KANNA="$APP/Contents/Helpers/kanna"
STATE="${CAPTURE_STATE:-$HOME/Library/Application Support/kanna-capture}"
SOCKET="$STATE/kanna.sock"

# The demo repo. Its path shows in the planning terminal's header and the
# agents' prompts, so it lives somewhere that reads naturally, not in a temp
# folder.
DEMO="${CAPTURE_DEMO:-$HOME/work/tidetable}"
MARKER=".git/kanna-capture-demo" # seed.sh writes it; nothing is deleted without it

# Window size in points. Screenshots come out at the screen's scale (2x on a
# retina display), so 1280x800 gives 2560x1600 PNGs.
WIN_W="${CAPTURE_W:-1280}"
WIN_H="${CAPTURE_H:-800}"

OUT="${CAPTURE_OUT:-$HERE/.out}" # PNGs, kept out of git

# Every kanna command goes to the capture Kanna, never the one this shell may
# be running in. With KANNA_SOCKET set the CLI never starts an app itself;
# start.sh does that.
k() { env -u KANNA_PANE -u KANNA_INSTANCE KANNA_SOCKET="$SOCKET" "$KANNA" "$@"; }

log() { printf '\033[2m[capture]\033[0m %s\n' "$*" >&2; }
die() { printf 'capture: %s\n' "$*" >&2; exit 1; }

# wait_for SECONDS DESCRIPTION COMMAND...: run COMMAND every 2s until it succeeds.
wait_for() {
  local secs="$1" what="$2"; shift 2
  local end=$((SECONDS + secs))
  log "waiting for $what"
  until "$@" >/dev/null 2>&1; do
    ((SECONDS < end)) || die "timed out after ${secs}s waiting for $what"
    sleep 2
  done
}

# launch [--fresh]: start Kanna.app on $SOCKET and wait until it's attached.
launch() {
  /usr/bin/open -n -g \
    --env "KANNA_SOCKET=$SOCKET" \
    --env "KANNA_START_DIR=$DEMO" \
    --env "XDG_CONFIG_HOME=$STATE/xdg" \
    --env KANNA_DEBUG=1 \
    -a "$APP" --args --bg "$@"
  wait_for 30 "Kanna.app to attach" attached
  # Light mode, through the app's own debug hook (KANNA_DEBUG=1): the same
  # NSApp.appearance a light system gives it. The terminals follow it.
  k raw '{"cmd":"debug.app","args":{"appearance":"light"}}' >/dev/null
}
attached() { k capabilities 2>/dev/null | grep -q 'Kanna.app: attached'; }

# app_pid: the capture app, found by the socket in its environment.
app_pid() {
  ps -axww -o pid=,command= -E 2>/dev/null | awk -v s="KANNA_SOCKET=$SOCKET" '
    index($0, "/Contents/MacOS/Kanna ") && index($0, s) { print $1 }'
}

# pane_field PANE FIELD: a field of a pane (by ID or name) from `kanna list --json`.
pane_field() {
  k list --json | python3 -c '
import json, sys
ref, field = sys.argv[1], sys.argv[2]
for p in json.load(sys.stdin)["panes"]:
    if ref in (p["id"], p.get("name")):
        print(p.get(field) or "")
' "$1" "$2"
}

# turn_over PANE: the agent has stopped working (idle or needs you) and has
# stayed so for 5s: its turn is over, as Kanna's backlog runners judge it.
# Kanna judges the status of tasks' agents only; for any other terminal (the
# planning agent, the quiz) it's empty, and the sign is Claude's own line at
# the end of a turn ("✻ Baked for 8s · done 8:05 PM") or its question menu,
# with nothing working below it.
turn_over() {
  local s
  for _ in 1 2 3; do
    s="$(pane_field "$1" status)"
    case "$s" in
      idle | needs-you) ;;
      "") claude_waiting "$1" || return 1 ;;
      *) return 1 ;;
    esac
    sleep 2
  done
}
claude_waiting() {
  k read "$1" | python3 -c '
import re, sys
lines = [l for l in sys.stdin.read().splitlines() if l.strip()]
tail = "\n".join(lines[-25:])
working = re.search(r"esc to interrupt", tail)
done = re.search(r"for \d+(m \d+)?s · done", tail) or re.search(r"Enter to select", tail)
sys.exit(0 if done and not working else 1)'
}

# wait_turn PANE SECONDS: wait for the agent to start working, then to finish its turn.
wait_turn() {
  local end=$((SECONDS + 60))
  until [ "$(pane_field "$1" status)" = working ] || ! claude_waiting "$1"; do ((SECONDS < end)) || break; sleep 1; done
  wait_for "$2" "$1 ($(pane_field "$1" name)) to finish its turn" turn_over "$1"
}

# shot NAME WINDOW: the whole window as drawn, to $OUT/NAME.png.
shot() {
  mkdir -p "$OUT"
  k screenshot --window "$2" -o "$OUT/$1.png" --force >/dev/null
  log "captured $OUT/$1.png"
}

# desk: the Desk window (the one with the planning terminal).
desk_window() { k list --json | python3 -c 'import json,sys; print(next(w["id"] for w in json.load(sys.stdin)["windows"] if w.get("planner")))'; }
