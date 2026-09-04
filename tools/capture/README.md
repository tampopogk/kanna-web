# Marketing capture harness

Produces the product screenshots on the homepage from a real Kanna build,
seeded with data written for public display.

## What these captures are

Real application UI. The harness drives an actual Kanna build and asks it for
its own screenshot; nothing is mocked, hand-built, or composited, and no state
is shown that the app does not genuinely produce. That distinction is a
standing rule for this site: never present a simulated or hand-built interface
as if it were a screenshot.

## Why this exists rather than the kanna repo's e2e seed

The Kanna repo has an e2e seed at `apps/desktop/tests/e2e/seed.sql`. Its task
titles are good, but its three repositories are named `example-app`,
`example-api` and `example-docs` under `/Users/test`. Repository names are the
most prominent text in the Kanna sidebar, so captures from that seed put the
word "example" in front of every visitor. `seed.sql` here is the same idea with
names chosen for a homepage.

## Requirements

A **debug** build of Kanna. The WebDriver server comes from
`tauri-plugin-webdriver`, which `apps/desktop/src-tauri/src/lib.rs` initialises
under `#[cfg(debug_assertions)]` only — so the installed release app in
`/Applications` cannot be driven. `avifenc` (`brew install libavif`) is needed
for the conversion step.

## The three things that make or break a run

**1. The app window must be visible and focused, or every terminal pane
screenshots blank.** macOS suspends `requestAnimationFrame` for an occluded
webview, and xterm only paints on a frame. The rest of the UI is plain DOM and
renders anyway, which is why the failure looks like "the task list is fine but
the right pane is empty" rather than like a hang. `wd.mjs` exports
`focusWindow()`, which calls the app's own `plugin:window|set_focus` and then
asserts `document.visibilityState === "visible"`; every script here calls it
first. Nothing else about the run needs the window to stay frontmost, but
`prepare.mjs` and `capture.mjs` both re-focus, so leave the machine alone while
they run.

**2. Give the app the database you meant to give it.** `KANNA_DB_PATH` is
honoured by `kd` *and* by the app (`resolved_db_path` checks it first), but only
if the path is absolute. `kd dev up --db kanna-capture.db` — a bare name —
resolves into the app's Application Support directory instead, which for a debug
build is the **production** `~/Library/Application Support/build.kanna/`. Always
pass an absolute path, and verify what actually got opened before seeding:

```sh
lsof -nP | grep kanna-capture.db      # the live path
# and ask the app itself, through the E2E hook:
#   window.__KANNA_E2E__.dbName
```

`capture.mjs` and `prepare.mjs` both refuse to run unless the app reports a
database whose name contains "capture".

**3. Fixtures before seed, and fixtures with real code in them.** Kanna
reconciles against the filesystem on load: a task whose worktree is missing is
closed and moved to the done stage within seconds. `fixtures.sh` also gives each
repository a small but real source tree and real history, because the hero shot
is an agent actually working in one of them — against an empty repository the
agent correctly reports there is nothing to do, which is honest and useless.
Tests run on `node --test`, so a fixture needs no install step.

## Running it

Everything below is isolated from any other Kanna instance: its own database,
its own daemon directory, its own transfer root, and its own ports. Pick ports
that are free; a dev machine runs several Kanna instances side by side.

**Never run `kd dev down --kill-daemon`.** It reaps daemons by workspace, and on
a machine running other Kanna tasks that takes out sessions you do not own. Stop
with `kd dev down`, then kill your own daemon PID after confirming its path.

```sh
SCRATCH="$PWD/.tmp/cap"
mkdir -p "$SCRATCH/daemon"

env KANNA_DEV_PORT=1422 KANNA_WEBDRIVER_PORT=4447 KANNA_RELAY_PORT=9082 \
    KANNA_MOBILE_SERVER_PORT=48122 KANNA_MOBILE_PORT=8090 KANNA_TRANSFER_PORT=4457 \
./kd dev up --db "$SCRATCH/kanna-capture.db" --delete-db \
    --daemon-dir "$SCRATCH/daemon" --transfer-root "$SCRATCH/transfer"
```

The app creates its schema on first run. Then:

```sh
./fixtures.sh "$SCRATCH/repos"
./seed.sh "$SCRATCH/kanna-capture.db" "$SCRATCH/repos"
sqlite3 "$SCRATCH/kanna-capture.db" < seed-fixup.sql

KANNA_WEBDRIVER_PORT=4447 node prepare.mjs        # reload, focus, start the agent
KANNA_WEBDRIVER_PORT=4447 node capture.mjs        # all four shots
./convert.sh .tmp/capture out
```

`seed.sql` is INSERT-only by design, so it runs against a database the shipped
app created and cannot drift from the real schema. It is also therefore the
first thing to break when the schema changes: the `tags` column it used is gone,
and `seed-fixup.sql` carries the two corrections the app's rendering requires —

- `agent_type` is the *session kind* the app renders with, `pty` or `agent`.
  `MainPanel.vue` passes it straight to `TerminalTabs.vue`, which renders
  nothing at all for any other value, so seeding a provider name like `claude`
  into that column is a second, independent cause of a blank right-hand pane.
  The provider belongs in `agent_provider`.
- Stage names are display strings and must match `DEFAULT_STAGE_ORDER`
  (`pr`, `review`, `in progress`). `in_progress` renders literally, underscore
  and all, as a sidebar section label.

## Getting real content into the right-hand pane

A task terminal is **attach-only**: `getTerminalRecoveryMode()` never lets the
desktop spawn an agent for an existing task, because the server owns that. So a
seeded task shows an empty pane until something creates a daemon session under
the task's id. `prepare.mjs` starts one through `store.spawnPtySession` — the
same store call the app makes when a task begins — and then answers the agent
CLI's workspace-trust prompt the way a person would.

**Capture while the agent is working.** An idle Claude CLI fills its composer
with a tab-to-accept suggestion; that text is provider chrome, not something
anybody typed, and on a homepage it reads as an instruction somebody gave.
`capture.mjs` refuses to take the task shot when the composer is non-empty.
`nudge.mjs` sends a follow-up instruction so the session is busy — and its
composer empty — when the shot is taken.

## After capturing

`convert.sh` writes AVIF and prints each intrinsic size. The markup must carry
that exact `width`/`height`, plus `loading="lazy"` and `decoding="async"`
(`fetchpriority="high"` on the hero image instead of `loading`), and alt text
describing what is actually on screen.

Check every capture for text that should not be public before committing it.
