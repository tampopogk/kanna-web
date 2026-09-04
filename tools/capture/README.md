# Marketing capture harness

Produces the product screenshots on the homepage from a real Kanna build,
seeded with data written for public display.

## Why this exists rather than the kanna repo's e2e seed

The Kanna repo has an e2e seed at `apps/desktop/tests/e2e/seed.sql`. Its task
titles are good, but its three repositories are named `example-app`,
`example-api` and `example-docs` under `/Users/test`. Repository names are the
most prominent text in the Kanna sidebar, so captures from that seed put the
word "example" in front of every visitor. `seed.sql` here is the same idea with
names chosen for a homepage.

## What these captures are

Real application UI. The harness drives an actual Kanna build and asks it for
its own screenshot; nothing is mocked, hand-built, or composited, and no state
is shown that the app does not genuinely produce. That distinction is a
standing rule for this site: never present a simulated or hand-built interface
as if it were a screenshot.

## Requirements

A **debug** build of Kanna. The WebDriver server comes from
`tauri-plugin-webdriver`, which `apps/desktop/src-tauri/src/lib.rs` initialises
under `#[cfg(debug_assertions)]` only — so the installed release app in
`/Applications` cannot be driven, and `avifenc` (`brew install libavif`) is
needed for the conversion step.

## Running it

Everything below is isolated from the running Kanna instance: its own database,
its own daemon directory, and its own ports. `kd` additionally refuses to start,
reset or seed against the production database (`kanna-v2.db`).

**Never run `kd dev down --kill-daemon` here.** Stop the instance with
`kd dev down`. The kill path reaps daemons, and on a machine where Kanna is
running your own work, that can take out the session you are working in.

```sh
SCRATCH="$PWD/.tmp/cap"
mkdir -p "$SCRATCH/daemon"

cd /path/to/kanna
env KANNA_DB_NAME=kanna-capture.db \
    KANNA_DB_PATH="$SCRATCH/kanna-capture.db" \
    KANNA_DAEMON_DIR="$SCRATCH/daemon" \
    KANNA_DEV_PORT=1520 \
    KANNA_WEBDRIVER_PORT=4555 \
    KANNA_RELAY_PORT=9180 \
    KANNA_MOBILE_SERVER_PORT=48220 \
    KANNA_MOBILE_PORT=8181 \
    KANNA_TRANSFER_PORT=4655 \
    ./kd dev up --db kanna-capture.db --delete-db --daemon-dir "$SCRATCH/daemon"
```

The app creates its schema on first run. Then seed and capture:

```sh
sqlite3 "$SCRATCH/kanna-capture.db" < tools/capture/seed.sql
KANNA_WEBDRIVER_PORT=4555 node tools/capture/capture.mjs
tools/capture/convert.sh .tmp/capture assets
```

`seed.sql` is INSERT-only by design, so it runs against a database the shipped
app created and cannot drift from the real schema.

## After capturing

`convert.sh` writes AVIF and prints each intrinsic size. The markup must carry
that exact `width`/`height`, plus `loading="lazy"` and `decoding="async"`
(`fetchpriority="high"` on the hero image instead of `loading`), and alt text
describing what is actually on screen.

Check every capture for text that should not be public before committing it.
