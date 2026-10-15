#!/usr/bin/env bash
# From a clean state to the four AVIFs in assets/: seed the demo repo, start
# the capture Kanna, make the tasks, stage and capture each shot, convert.
# Takes 15-25 minutes, most of it real agents working. Leaves the capture
# Kanna running so you can look; ./stop.sh --clean when you're done.
source "$(dirname "$0")/lib.sh"

if k capabilities >/dev/null 2>&1 || [ -e "$DEMO" ]; then
  log "cleaning up an earlier run"
  "$HERE/stop.sh" --clean
fi
"$HERE/seed.sh"
"$HERE/start.sh"
"$HERE/tasks.sh"
"$HERE/stage.sh"
"$HERE/convert.sh"
