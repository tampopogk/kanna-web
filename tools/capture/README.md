# Marketing capture harness (Kanna v4)

Produces the Kanna v4 screenshots on the homepage (`assets/kanna-v4-*.avif`)
from a real Kanna, driven to each state by scripts, with real agents working
in a demo repo written for public display.

## What these captures are

Real application UI. The harness drives an actual Kanna build and asks it for
its own screenshot (`kanna screenshot --window`); nothing is mocked,
hand-built, or composited, and no state is shown that the app does not
genuinely produce. Every agent conversation on screen is a real Claude Code
session doing real work in the demo repo; the only things typed into them are
what a user would type ("go on", "Yes, quiz me on what landed today", a quiz
answer). That distinction is a standing rule for this site: never present a
simulated or hand-built interface as if it were a screenshot.

Demo content is written for public display: no "example"/"foo" names, no
personal paths, no secrets. Check every capture for text that shouldn't be
public before committing it; the agents write their own words, so each run is a
little different.

## The shots

| File | Window | What's on screen |
|---|---|---|
| `kanna-v4-desk` | the Desk, no task on it | the planning agent greeting you with what's running and waiting (and offering a quiz), beside the full Shelf (three tasks: two finished, one working) and the backlog (two waiting, one blocked) |
| `kanna-v4-presenting` | the Desk, "Fix DST gap in daily tides" | the task's agent, its work done, beside the tab it opened to present it (usually a diff) |
| `kanna-v4-code` | the Desk, "Walk through the prediction pipeline" | an agent explaining the code a step at a time: a code tab at `src/harmonics.ts` with its comment on the lines, earlier steps (a mermaid diagram, the handler, the cache, the day window) in the other tabs |
| `kanna-v4-quiz` | the Quiz window | the quiz agent after a missed question, the code opened at the line with the explanation on it |

Windows are 1280×800 points, so 2560×1600 PNGs on a retina display, in light
mode.

## The demo repo

`demo/tidetable` is **tidetable**, a small TypeScript service that predicts
tides from harmonic constants (real maths: a sum of cosines per station, high
and low water found where the curve turns) and serves them over HTTP. Tests run
on `node --test` with Node 23.6+, which runs TypeScript directly, so there's no
install step. It has one real, subtle bug left in for the agents to find:
`localDayBounds` assumes every local day is 24 hours, which is wrong on the
days clocks change.

`seed.sh` commits it to `~/work/tidetable` (`CAPTURE_DEMO`) as a short history
whose last three commits are from the past few hours, so the planning agent
offers a quiz on "what landed today". Its `.kanna/config.json` makes Claude the
planning agent and turns backlog runners off (tasks wait until the harness
starts them). Its `.claude/settings.json` gives Claude its light theme (your
global theme would otherwise apply: the dark one draws your messages as dark
bars and a question's text nearly invisible on a light terminal), turns off
prompt suggestions (ghost text in an idle composer reads as an instruction
somebody typed) and spinner tips, and lets Claude's sandbox bind local ports,
so the server tests run inside it and the agents' summaries don't spend lines
on the sandbox.

The path shows in the planning terminal's header, which is why the repo isn't
in a temp folder.

## Requirements

- **Kanna 4.0.0** at `/Applications/Kanna.app` (`CAPTURE_APP` for another
  build). Nothing needs building: the release app answers `kanna screenshot`,
  and its debug commands are on with `KANNA_DEBUG=1`.
- **Claude Code** on your `PATH`, logged in, with Kanna's skills
  (`kanna agents setup`). The agents use your account.
- **Node 23.6+** (the agents run the demo's tests), **python3**, and
  **`avifenc`** (`brew install libavif`).
- A retina display, for 2x captures.

## Running it

```sh
cd tools/capture
./run.sh            # clean state → assets/kanna-v4-*.avif, 15-25 minutes
./stop.sh --clean   # afterwards: stop the capture Kanna, delete it and the demo repo
```

`run.sh` is these steps, which also run on their own:

| Script | Does |
|---|---|
| `seed.sh [--force]` | commits the demo repo to `$DEMO` |
| `start.sh` | starts the capture Kanna on it, light, windows sized |
| `tasks.sh` | makes six backlog tasks, as the planning agent would |
| `stage.sh [SHOT...]` | drives each shot's state and captures it to `.out/` (`presenting code desk quiz`, in that order) |
| `size-windows.sh` | gives every window the capture size (`CAPTURE_W`, `CAPTURE_H`) |
| `convert.sh [IN] [OUT]` | `.out/*.png` → `assets/kanna-v4-*.avif`, printing each size for the markup's `width`/`height` |
| `stop.sh [--clean]` | stops the capture Kanna; `--clean` deletes its folder and the demo repo |

The PNGs stay in `.out/`, which git ignores. You can keep using the machine
while it runs: the capture app stays in the background, and `kanna screenshot`
captures windows behind others, terminals included.

## Gotchas

**Never point the scripts at your own Kanna.** Everything runs in a separate
Kanna: its own app process, daemon, keeper, terminals and `kanna.db`, in
`~/Library/Application Support/kanna-capture` (`CAPTURE_STATE`). Every command
goes through `k`, which sets `KANNA_SOCKET` to that folder's socket and clears
the `KANNA_PANE` a Kanna terminal would pass on, so running the harness from a
Kanna terminal never touches the Kanna you're in. `stop.sh` finds the app by the
socket in its environment and the daemon and keeper by their PID files there,
and checks each process's command before killing it.

**Not `kanna --instance NAME`.** A named instance puts its name in every
window's title ("Shelf · capture"). A daemon in a folder that isn't a channel's
(`kanna-prod-NAME`, …) names itself `default`, whose title has no suffix. The
cost: with `KANNA_SOCKET` set the CLI never starts an app, so `start.sh` starts
it with `open -n --env …` itself.

**Light mode needs two things.** The system here is dark, so `start.sh` sets
the app's appearance with its own debug hook (`debug.app {appearance: light}`,
on with `KANNA_DEBUG=1`), after every launch. And Ghostty with no config draws a
dark terminal whatever the appearance, so the app gets `XDG_CONFIG_HOME`
pointing at a folder holding `ghostty.conf` (light colours). Only the app sees
it: the daemon passes on only `KANNA_*` variables, so agents and shells don't.
Claude Code's colours are its own theme, set in the demo repo (above).

**Kanna has no command that sizes a window.** It restores each window's frame
from `layout.json` when it starts, so `size-windows.sh` quits the app (the
daemon, keeper and agents keep running), sets the frames, and starts it again;
it reattaches to the same panes. The Quiz window is new, so it's sized again
before its shot.

**A task parked on the Shelf can't present its work (Kanna 4.0.0).** A tab
it opens with `kanna open --tab` lands on whichever task is on the Desk, and
without `--tab` it's left unplaced, instead of going to the task's own tabs as
`docs/specs/presenting.md` says. The first run put the DST fix's diff in the
code tour's tabs. So `stage.sh` runs each presenting task on the Desk while it
works (`kanna task shelve TASK --window W`), one at a time, and stops the one
task that works while parked (the rate-limit task, "working" in the Desk shot)
right after that shot.

**`--after` takes backlog IDs that change.** A task's ID becomes its agent's
pane ID when it starts (`t3` → `p3`), and a task blocked on the old ID shows it
as missing: the planning agent said "t3 isn't in the task list". The blocked
demo task waits on two backlog tasks that never start.

**The planning agent and the quiz agent have no agent status.** Kanna judges
the status of tasks' agents only, so for those two the scripts read the screen
for the end of Claude's turn ("✻ Baked for 8s · done …") or its question menu.

**In 4.0.0 the Quiz window is a plain window,** not the Desk-like window the
quiz spec describes: the quiz agent is its first tab, and the code it opens on
a miss (`kanna comment --tab`, as the kanna-quiz skill says) is a second tab,
so the two are never on screen together. `stage.sh` does what a user would:
moves the code pane beside the agent (`kanna move … --to quiz --side right`)
and names the tab "Quiz" (a plain window's title is its tab's name and the
window's ID, "Quiz — w3").

**Claude asks once whether to trust the demo folder.** The prompt shows the
full path (with your username), so `start.sh` answers it before any capture;
worktrees inside inherit the answer. It's recorded in `~/.claude.json`.

**Agents decide what they show.** The scripts wait for each agent's turn to
end (its status idle or needs-you for a few seconds, as Kanna's backlog runners
judge it) and check the result (a tab opened, the tour reached
`src/harmonics.ts`, a code pane in the quiz), warning when it didn't happen
rather than faking it. Look at every PNG; if one isn't good, re-run its shot
(`./stage.sh quiz`) or the whole thing.

**What a run leaves behind:** the capture folder and demo repo until
`stop.sh --clean`, and the agents' Claude sessions under
`~/.claude/projects/-Users-…-work-tidetable*`.

## After capturing

`convert.sh` prints each image's intrinsic size. The markup must carry that
exact `width`/`height`, plus `loading="lazy"` and `decoding="async"`
(`fetchpriority="high"` on the hero image instead of `loading`), and alt text
describing what is actually on screen.
