#!/usr/bin/env bash
# Drive the capture Kanna to each shot's state and capture it. Every agent here
# is a real Claude doing real work in the demo repo; the only things typed into
# them are what a user would type ("go on", "Yes, quiz me", a quiz answer).
#
#   ./stage.sh                       # all four, in this order
#   ./stage.sh presenting code       # just those (each needs the ones before it to have run)
#
# Order matters. A task presents its work by opening tabs from its own
# terminal, and in Kanna 4.0.0 a tab opened by a task that's parked on the
# Shelf lands on whichever task is on the Desk instead (or, without --tab, is
# left unplaced). So each task runs on the Desk while it works
# (`task shelve --window`), and only one task runs while parked: the
# rate-limit task, shown "working" in the Desk shot and stopped right after.
source "$(dirname "$0")/lib.sh"
# shellcheck disable=SC1091
source "$STATE/tasks.env" # DST, RATE, TOUR from tasks.sh

W="$(desk_window)"
SHOTS=("$@")
[ ${#SHOTS[@]} -gt 0 ] || SHOTS=(presenting code desk quiz)

planner() { k list --json | python3 -c 'import json,sys; print(next(w["planner"]["pane"] for w in json.load(sys.stdin)["windows"] if w.get("planner")))'; }
task_pane() { pane_field "$1" id; } # a started task's pane, by its name
tabs_in() { k list --json | python3 -c 'import json,sys; w=next(w for w in json.load(sys.stdin)["windows"] if w["id"]==sys.argv[1]); print(len(w.get("tabs",[])))' "$1"; }
code_open() { k list --json | python3 -c 'import json,sys; sys.exit(0 if any(p["type"]=="code" and p.get("path","").endswith(sys.argv[1]) for p in json.load(sys.stdin)["panes"]) else 1)' "$1"; }

# 2. A task presenting its work: the DST fix, done on the Desk, beside the
# diff (or whatever) it opened to show what it changed.
presenting() {
  log "presenting: starting 'Fix DST gap in daily tides' on the Desk"
  k task shelve "$DST" --window "$W" >/dev/null
  sleep 3
  local p; p="$(task_pane "Fix DST gap in daily tides")"
  wait_turn "$p" 1200
  [ "$(tabs_in "$W")" -gt 0 ] || log "warning: the task opened no tabs to present its work"
  shot presenting "$W"
}

# 3. Code tour: an agent asked to explain the prediction pipeline opens a
# diagram, then the code a step at a time with comments on the lines. "go on"
# is what it asks for between steps; stop at the harmonic sum.
code() {
  log "code: starting 'Walk through the prediction pipeline' on the Desk"
  k task shelve "$TOUR" --window "$W" >/dev/null # parks the DST task, finished
  sleep 3
  local p; p="$(task_pane "Walk through the prediction pipeline")"
  wait_turn "$p" 600
  for _ in 1 2 3 4 5 6; do
    code_open harmonics.ts && break
    k send "$p" "go on" >/dev/null
    wait_turn "$p" 300
  done
  code_open harmonics.ts || log "warning: the tour hasn't reached src/harmonics.ts; capturing where it is"
  shot code "$W"
}

# 1. The Desk with no task on it: the planning agent beside the full Shelf
# (three tasks, one still working) and the backlog (two waiting, one blocked).
desk() {
  log "desk: rate-limit task to the Shelf, park the tour, restart the planner"
  k task shelve "$RATE" >/dev/null || true # (already there on a re-run)
  k task park --window "$W" >/dev/null || true
  local pl; pl="$(planner)"
  sleep 20 # let the rate-limit agent get going, so the planner sees it working
  k restart "$pl" >/dev/null # a fresh planner reads the Shelf and backlog as they are now
  wait_turn "$pl" 180
  local r; r="$(task_pane "Rate-limit the tides endpoint")"
  [ "$(pane_field "$r" status)" = working ] || log "warning: the rate-limit task isn't working any more"
  shot desk "$W"
  k task stop "$r" >/dev/null # before it presents from the Shelf (see the top)
}

# 4. Quiz: say yes to the planner's offer; it opens the Quiz window. Answer
# questions (the first choice, then the second, ...) until one is a miss: on a
# miss the quiz agent opens the code at the line, beside the next question.
quiz_open() { [ -n "$(pane_field quiz id)" ]; }
quiz_code() { k list --json | python3 -c 'import json,sys; sys.exit(0 if any(p["type"]=="code" and "kanna-worktrees" not in p.get("path","") for p in json.load(sys.stdin)["panes"]) else 1)'; }
quiz() {
  local pl; pl="$(planner)"
  log "quiz: accepting the planner's offer"
  k send "$pl" "Yes, quiz me on what landed today" >/dev/null
  wait_for 180 "the Quiz window" quiz_open
  wait_turn quiz 600 # writes question 1 and asks it with its question tool
  local keys=(return) i
  for i in 1 2 3 4; do
    k send-key quiz "${keys[@]}" >/dev/null
    wait_turn quiz 300
    quiz_code && break
    keys=(down "${keys[@]}") # a different choice next time
  done
  quiz_code || log "warning: no miss in four questions, so no code is open"
  # The skill opens the code with `kanna comment --tab`, and the Quiz window
  # in 4.0.0 is a plain window, so the code is a tab of its own and never on
  # screen with the question. Do what you'd do: drag it beside the agent, and
  # name the tab (the title of a plain window is its tab's).
  local code; code="$(k list --json | python3 -c 'import json,sys; print([p["id"] for p in json.load(sys.stdin)["panes"] if p["type"]=="code" and "kanna-worktrees" not in p.get("path","")][-1])')"
  if [ -n "$code" ]; then
    k move "$code" --to quiz --side right >/dev/null
    k resize quiz 0.45 >/dev/null
    local tab; tab="$(k list --json | python3 -c '
import json, sys
d = json.load(sys.stdin)
for w in d["windows"]:
    for t in w.get("tabs", []):
        if "quiz" in json.dumps(t): print(t["id"])')"
    [ -n "$tab" ] && k rename-tab "$tab" Quiz >/dev/null
    k focus quiz >/dev/null
  fi
  # The Quiz window is new, so it has Kanna's default size: give it ours.
  "$HERE/size-windows.sh"
  local qw; qw="$(k list --json | python3 -c '
import json, sys
d = json.load(sys.stdin)
q = next(p for p in d["panes"] if p.get("name") == "quiz")
print(next(w["id"] for w in d["windows"] if q["id"] in json.dumps(w) or "\"quiz\"" in json.dumps(w)))')"
  shot quiz "$qw"
}

for s in "${SHOTS[@]}"; do "$s"; done
