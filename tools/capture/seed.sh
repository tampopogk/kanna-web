#!/usr/bin/env bash
# Make the demo repo: tidetable, a small TypeScript tide-prediction service
# (demo/tidetable), committed as a short history whose last commits landed in
# the past day, so the planning agent offers a quiz and the quiz has something
# to ask about. Dates are relative to now, so a re-run is always "today".
#
#   ./seed.sh            # makes $DEMO (default ~/work/tidetable)
#   ./seed.sh --force    # replaces a demo repo an earlier run made
source "$(dirname "$0")/lib.sh"

SRC="$HERE/demo/tidetable"

if [ -e "$DEMO" ]; then
  [ "${1:-}" = "--force" ] || die "$DEMO exists; pass --force to replace it (only a repo seed.sh made is removed)"
  [ -e "$DEMO/$MARKER" ] || die "$DEMO wasn't made by seed.sh (no $MARKER); not touching it"
  git -C "$DEMO" worktree list --porcelain | awk '/^worktree /{print $2}' | tail -n +2 | while read -r wt; do
    git -C "$DEMO" worktree remove --force "$wt" || true
  done
  rm -rf "$DEMO"
fi

mkdir -p "$DEMO"
git -C "$DEMO" init -q -b main
touch "$DEMO/$MARKER"
git -C "$DEMO" config user.name "Tidetable"
git -C "$DEMO" config user.email "dev@tidetable.dev"
git -C "$DEMO" config commit.gpgsign false

# commit HOURS_AGO MESSAGE FILE...: copy FILEs from the source tree and commit them.
commit() {
  local ago="$1" msg="$2"; shift 2
  for f in "$@"; do
    mkdir -p "$DEMO/$(dirname "$f")"
    cp "$SRC/$f" "$DEMO/$f"
    git -C "$DEMO" add "$f"
  done
  local when; when="$(date -v-"${ago}"H '+%Y-%m-%dT%H:%M:%S')"
  GIT_AUTHOR_DATE="$when" GIT_COMMITTER_DATE="$when" git -C "$DEMO" commit -q -m "$msg"
}

commit 214 "Station registry and harmonic tide prediction" \
  package.json tsconfig.json .gitignore .claude/settings.json .kanna/config.json \
  data/stations.json src/stations.ts src/harmonics.ts test/harmonics.test.ts test/stations.test.ts
commit 150 "Find high and low water where the predicted curve turns" \
  src/extremes.ts test/extremes.test.ts
commit 75 "Add an LRU cache whose entries expire" \
  src/cache.ts test/cache.test.ts
commit 9 "Report each station's tides for its local day" \
  src/time.ts test/time.test.ts
commit 6 "HTTP API: list stations and serve a day's tides, cached" \
  src/server.ts src/main.ts test/server.test.ts
commit 3 "README: the API and how a prediction is made" \
  README.md

# Everything in the source tree is committed.
missing="$(cd "$SRC" && find . -type f | sed 's|^\./||' | while read -r f; do git -C "$DEMO" ls-files --error-unmatch "$f" >/dev/null 2>&1 || echo "$f"; done)"
[ -z "$missing" ] || die "not committed by seed.sh: $missing"

log "seeded $DEMO"
git -C "$DEMO" log --format='  %h %ar  %s' >&2
