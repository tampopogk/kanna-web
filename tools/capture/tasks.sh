#!/usr/bin/env bash
# Make the demo repo's tasks, as the planning agent would with `kanna task new`.
# All six wait in the backlog: the repo's .kanna/config.json sets
# backlog.runners to 0, so none starts by itself. stage.sh starts three of
# them, one at a time, when each shot needs it; the other three stay waiting
# (one blocked on two others). Their IDs go to $STATE/tasks.env.
source "$(dirname "$0")/lib.sh"
cd "$DEMO" # a task belongs to the repo it's made in

new() { k task new "$@" --json | python3 -c 'import json,sys; print(json.load(sys.stdin)["task"]["id"])'; }

# Started by stage.sh. Each is real work in the demo repo.
DST="$(new "Fix DST gap in daily tides" "GET /stations/:id/tides?date=... reports the wrong window on the days clocks change: localDayBounds in src/time.ts assumes every local day is 24 hours long, but 2026-11-01 in America/Los_Angeles is 25 hours and 2026-03-08 is 23, so on those days the window ends an hour early or runs an hour into the next day. Make a day run from local midnight to the next local midnight. Add tests in test/time.test.ts for both changes (and a zone without DST), plus one in test/extremes.test.ts or test/server.test.ts showing a tide in the last hour of 2026-11-01 at sf-golden-gate is reported (find a station and date where it matters, or construct one). Run npm test. Keep the fix small.")"
RATE="$(new "Rate-limit the tides endpoint" "Add per-client rate limiting to GET /stations/:id/tides in src/server.ts: a token bucket per client IP, 60 requests a minute with a burst of 10, answering 429 with a Retry-After header (whole seconds) when a client's bucket is empty. Put the bucket in a new src/ratelimit.ts with an injectable clock, test it in test/ratelimit.test.ts, add a server test for the 429, and document the limit in the README's API section. Buckets for clients idle more than ten minutes should be dropped so memory stays bounded. Run npm test.")"
TOUR="$(new "Walk through the prediction pipeline" "I'm about to review changes to how tides are predicted and I've lost track of how it works. Explain to me how a request for a day's tides becomes the list of highs and lows: from the HTTP handler in src/server.ts through the cache, the local day window, the harmonic sum in src/harmonics.ts and finding the turns in src/extremes.ts. Use a diagram and comments on the key lines of code. Don't change any code.")"

# In the backlog, waiting.
NEXT="$(new "Next high and low water endpoint" "Add GET /stations/:id/next, returning the next high and the next low water after now (or after ?from=ISO-8601), using extremes() over the next 26 hours. Tests in test/server.test.ts with a fixed from, README API table updated.")"
SEARCH="$(new "Find stations by name" "Add ?q= to GET /stations: a case-insensitive match on any word of the station's name (so 'gate' finds San Francisco, Golden Gate). Tests and README.")"
k task new "Publish the API reference" "Write docs/api.md: every endpoint with its parameters, an example request and response (run the server to get real ones) and the errors it can return. Link it from the README." --after "$NEXT,$SEARCH" >/dev/null

# --after names backlog tasks only: a task's ID changes to its agent's pane ID
# when it starts (t3 becomes p3), and a task waiting on the old ID shows it as
# missing.
printf 'DST=%s\nRATE=%s\nTOUR=%s\n' "$DST" "$RATE" "$TOUR" >"$STATE/tasks.env"
k task list >&2
