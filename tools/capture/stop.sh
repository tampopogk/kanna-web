#!/usr/bin/env bash
# Stop the capture Kanna: its app, daemon, keeper and every terminal it kept,
# including the agents. Touches only processes this capture Kanna started: the
# app is found by the socket it was launched with, the daemon and keeper by the
# PID files in $STATE.
#
#   ./stop.sh           # stop it, keep $STATE (its kanna.db, layout, logs)
#   ./stop.sh --clean   # also delete $STATE and the demo repo
source "$(dirname "$0")/lib.sh"

# kill_checked PID PATTERN: TERM, then KILL, a process whose command matches PATTERN.
kill_checked() {
  local pid="$1" pattern="$2" cmd
  cmd="$(ps -o command= -p "$pid" 2>/dev/null)" || return 0
  [[ "$cmd" == *$pattern* ]] || { log "pid $pid isn't $pattern ($cmd); leaving it"; return 0; }
  kill -TERM "$pid" 2>/dev/null || true
  for _ in 1 2 3 4 5; do kill -0 "$pid" 2>/dev/null || return 0; sleep 0.5; done
  kill -KILL "$pid" 2>/dev/null || true
}

for pid in $(app_pid); do log "app $pid"; kill_checked "$pid" "Contents/MacOS/Kanna"; done

if [ -f "$STATE/keeper.pid" ]; then
  keeper="$(cat "$STATE/keeper.pid")"
  # The keeper's children are the terminals; hang them up before it goes.
  for child in $(pgrep -P "$keeper" 2>/dev/null); do kill -HUP "$child" 2>/dev/null || true; done
fi
[ -f "$STATE/daemon.pid" ] && { log "daemon $(cat "$STATE/daemon.pid")"; kill_checked "$(cat "$STATE/daemon.pid")" kanna-daemon; }
[ -f "$STATE/keeper.pid" ] && { log "keeper $(cat "$STATE/keeper.pid")"; kill_checked "$(cat "$STATE/keeper.pid")" kanna-keeper; }

if [ "${1:-}" = "--clean" ]; then
  case "$STATE" in */kanna-capture*) rm -rf "$STATE"; log "deleted $STATE" ;; *) log "not deleting $STATE: not a kanna-capture folder" ;; esac
  if [ -e "$DEMO/$MARKER" ]; then
    rm -rf "$DEMO"; log "deleted $DEMO"
  fi
fi
