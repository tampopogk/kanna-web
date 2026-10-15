#!/usr/bin/env bash
# From a clean state to the AVIFs in assets/: for each theme, seed the demo
# repo, start the capture Kanna, make the tasks, stage and capture each shot;
# then convert. Each theme takes 25-35 minutes, most of it real agents
# working. Leaves the last capture Kanna running so you can look;
# ./stop.sh --clean when you're done.
#
#   ./run.sh              # light, then dark
#   ./run.sh dark         # just one theme
source "$(dirname "$0")/lib.sh"

THEMES=("$@")
[ ${#THEMES[@]} -gt 0 ] || THEMES=(light dark)

for theme in "${THEMES[@]}"; do
  export CAPTURE_THEME="$theme"
  log "== $theme =="
  if k capabilities >/dev/null 2>&1 || [ -e "$DEMO" ]; then
    log "cleaning up an earlier run"
    "$HERE/stop.sh" --clean
  fi
  "$HERE/seed.sh"
  "$HERE/start.sh"
  "$HERE/tasks.sh"
  "$HERE/stage.sh"
done
"$HERE/convert.sh"
