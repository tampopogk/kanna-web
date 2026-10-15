#!/usr/bin/env bash
# Start the capture Kanna on the demo repo: a fresh Desk whose planning
# terminal starts in $DEMO. Run seed.sh first.
source "$(dirname "$0")/lib.sh"

[ -e "$DEMO/$MARKER" ] || die "no demo repo at $DEMO; run ./seed.sh first"
[ -x "$KANNA" ] || die "no Kanna at $APP"
if k capabilities >/dev/null 2>&1; then die "a capture Kanna is already running on $SOCKET; ./stop.sh first"; fi

mkdir -p "$STATE/xdg/ghostty"
# The terminal's colours. Kanna's terminals are Ghostty, which reads its config
# from $XDG_CONFIG_HOME/ghostty/config. With no config it draws the same dark
# terminal whatever the system's appearance, so a light window gets a dark
# panel in it; and the dark default doesn't match Kanna's dark window either.
# This file is only the capture app's: XDG_CONFIG_HOME is set for the app alone
# (the daemon it starts passes on only KANNA_* variables, so agents and shells
# never see it).
cp "$HERE/ghostty-$THEME.conf" "$STATE/xdg/ghostty/config"

launch --fresh
has_planner() { k list | grep -q "planner.sh"; }
wait_for 30 "the Desk's planning terminal" has_planner
# Claude asks once whether to trust the demo repo's folder (its worktrees
# inherit the answer). Answer it as a user would.
pl="$(k list --json | python3 -c 'import json,sys; print(next(w["planner"]["pane"] for w in json.load(sys.stdin)["windows"] if w.get("planner")))')"
for _ in $(seq 30); do
  screen="$(k read "$pl" 2>/dev/null || true)"
  if grep -q "trust this folder" <<<"$screen"; then log "trusting $DEMO in Claude"; k send-key "$pl" down return >/dev/null; break; fi
  grep -q "Kanna planning agent" <<<"$screen" && break
  sleep 2
done
"$HERE/size-windows.sh"
log "capture Kanna running on $SOCKET"
