#!/usr/bin/env bash
# Give every window of the capture Kanna the capture size ($WIN_W x $WIN_H
# points). Kanna has no command that sizes a window; it restores each window's
# frame from layout.json when it starts. So: quit the app (its daemon, keeper
# and terminals, agents included, keep running), set the frames in its saved
# layout, and start it again. It reattaches to the same panes.
source "$(dirname "$0")/lib.sh"

pid="$(app_pid)"
[ -n "$pid" ] || die "the capture app isn't running"
sleep 1 # the layout is saved half a second after a change
kill -TERM "$pid"
for _ in $(seq 20); do kill -0 "$pid" 2>/dev/null || break; sleep 0.5; done
kill -0 "$pid" 2>/dev/null && die "the capture app ($pid) didn't quit"

python3 - "$STATE/layout.json" "$WIN_W" "$WIN_H" <<'PY'
import json, sys
path, w, h = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
layout = json.load(open(path))
for i, window in enumerate(layout["windows"]):
    # Cascade a little so windows don't sit exactly on top of each other.
    window["frame"] = {"x": 60 + 30 * i, "y": 60 + 30 * i, "w": w, "h": h}
json.dump(layout, open(path, "w"))
PY
launch
log "windows are ${WIN_W}x${WIN_H}"
