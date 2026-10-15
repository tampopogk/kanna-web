# Website v4 design

**Status:** chosen 2026-10-15, built in `index.html` 2026-10-16 · **Mockup:** [`docs/mockups/2026-10-v4/b.html`](../mockups/2026-10-v4/b.html) (direction B, "After hours") · **Rejected:** [`a.html`](../mockups/2026-10-v4/a.html) (Field notes: warm paper, serif), [`c.html`](../mockups/2026-10-v4/c.html) (Bars: loud gradient panels); both still carry the first draft of the copy · **Screenshots:** the "Capture v4 screenshots" task, branch `capture-harness-v4` (`tools/capture/`)

The homepage (`index.html`) for Kanna v4, replacing the page that sells the Tauri product. This spec is what the page is built from: the direction, its tokens, the sections in order with their final copy, and where each screenshot goes. The mockup is the reference model: when this spec and the mockup disagree on something visual, the mockup wins; on words, this spec wins.

## Contents

1. [The idea](#1-the-idea)
2. [Look](#2-look)
3. [Layout](#3-layout)
4. [Sections and copy](#4-sections-and-copy)
5. [Screenshots](#5-screenshots)
6. [Behaviour](#6-behaviour)
7. [Removed](#7-removed)
8. [Rules](#8-rules)

## 1. The idea

**The message (the user's words):** build software you understand, at a pace you can sustain, while having fun. Kanna is a software development platform that keeps you connected, engaged and sane.

**The story follows the workflow:** plan well-defined tasks with the planning agent → each task builds a model (mockup or prototype, plus a markdown spec) that you mark up together and approve: reference-driven development → three tasks on your Desk while the backlog works in the background, each presenting its results when you call it up → stay connected to the code with explanations on the lines and a daily quiz. It closes on "enjoy coding again", a bookend to the headline's "having fun".

**The look:** designed dark, with a light mode; the page follows the system appearance. Kanna is a terminal, so the page lives where its users do: a dark, quiet near-black, monospace headlines, a faint grid, and the app icon's five coloured bars as the system. Each chapter is labelled with one of the icon's rows; the icon's green dot means "running", as on the Shelf. Dense and technical, but calm.

## 2. Look

**Appearance:** the page follows the system (`prefers-color-scheme`): dark when the system is dark, light when it's light. Dark is the design's home and the `:root` default; browsers that report no preference report light. Every colour is a custom property on `:root` (dark), redefined under `@media (prefers-color-scheme: light)`; the screenshots switch with it ([§5](#5-screenshots)). The gradients, green and type are the same in both.

**Palette** (CSS custom properties on `:root`; light values in the last column):

| Token | Dark | Use | Light |
|---|---|---|---|
| `--bg` | `#0c0d11` | page | `#f7f7f9` |
| `--bg-2` | `#13151b` | buttons, chips, placeholders, image backing | `#eef0f3` |
| `--line` | `#262a35` | rules, card borders, card gaps, image border | `#dfe2e8` |
| `--text` | `#e9e9ee` | headings; primary button fill (its label is `--bg`) | `#15171c` |
| `--text-2` | `#a9acb8` | leads, card text, second half of the headline | `#4a4f5c` |
| `--muted` | `#6d7180` | section numbers, captions, version line, footer | `#7d8290` |
| `--green` | `#17d34c` | the status dot (icon's top-right bar) | same |
| `--hot` | `#f72b89 → #ff8a12` | icon row 1: hero bars, chapter 01 | same |
| `--pink` | `#df1fb7 → #ef2d9b` | icon row 2: chapter 02 | same |
| `--purple` | `#9630dc → #9e23dd` | icon row 3: chapter 03 (with indigo) | same |
| `--indigo` | `#1957c3 → #6940a4` | icon row 4: chapter 03 | same |
| `--bv` | `#1458c5 → #736b91` | icon row 5: chapter 04 | same |
| `--code` | `#ffb27a` | inline `code` | `#c2410c` |
| `--grid` | `rgba(255,255,255,.025)` | the background grid lines and placeholder hatching | `rgba(20,24,40,.045)` |
| `--hover-line` | `#4a5060` | nav and button border on hover | `#b9bec9` |
| `--glow` | `rgba(247,43,137,.35)` | the hero screenshot's glow | `rgba(247,43,137,.22)` |
| `--plate-1`, `--plate-2`, `--plate-line` | `#1a1d25`, `#111318`, `rgba(255,255,255,.14)` | the icon's plate and hairline | `#fff`, `#fff`, `rgba(0,0,0,.08)` (the product icon's own white plate) |

Gradients run left to right (`90deg`). The page background has a 48px grid of 1px lines in `--grid`. The hero screenshot has a soft pink glow (`0 40px 120px -40px var(--glow)`). Set `color-scheme` to match each mode.

**Type** (Google Fonts):

| Role | Face | Size |
|---|---|---|
| h1 | JetBrains Mono 500, `-.03em` | `clamp(32px, 4vw, 50px)`, line-height 1.08; breaks only between its five phrases ([§3](#3-layout)) |
| h2 | JetBrains Mono 500, `-.03em`, `text-wrap: balance` | `clamp(28px, 3.4vw, 42px)` (closing: `clamp(32px, 4.6vw, 56px)`) |
| card titles, buttons, nav, captions, labels | JetBrains Mono | 15 / 14 / 12 / 12px |
| body, leads | Inter 400 | 16px body, 18px leads and pitch (16px on phones) |
| footer | JetBrains Mono, `.12em` tracking, caps | 11px |

**Icon:** the Kanna app icon, inline SVG, bar geometry and gradients copied from the product icon (`kanna/assets/Kanna.icns`, as in the current `index.html`), on a plate coloured by `--plate-1`/`--plate-2`/`--plate-line`: dark in dark mode, the product's white in light. Used at 26px in the header and 160px (96px on phones) in the closing.

**Shapes:** buttons and cards 10–14px radius; status chip a pill; chapter labels are pill bars (14px tall) like the icon's.

## 3. Layout

- **Width:** content max 1240px, 32px side padding (18px under 620px).
- **Header:** icon + "KANNA" left; bordered mono links right: plan, model, desk, connected (hidden under 620px), github, discord.
- **Hero:** two columns, 11fr words / 13fr screenshot, 56px gap; one column under 960px (words first).
- **The headline's line breaks are fixed:** it is five `white-space: nowrap` phrases ("Build software" / "you understand," / "at a pace you" / "can sustain," / "while having fun."), so it wraps only between them: five lines in the hero column and on phones, the three clauses one per line on tablets. The size and column width are set so the longest phrase (17 characters) fits at every width; a mono headline left to wrap freely strands words ("you" alone on a line).
- **Chapters:** a 280px rail on the left (the icon-row pill bars, `01`, the label in lowercase) that sticks while the chapter scrolls; the chapter on the right: h2, lead, then cards and screenshots. Under 960px the rail sits above, not sticky. Chapters are separated by a 1px rule and 96px of padding (72px under 960px).
- **Cards:** a bordered grid with 1px gaps in `--line` (two columns; three in 02; one under 620px). A card titled with a number (`02.1`) in `--muted`.
- **Screenshots:** full width of the chapter column, one under another; 12px radius, 1px `--line` border, caption below in mono `--muted`.
- **Closing:** icon left, words right (stacked under 620px).
- **Footer:** one line, wraps on phones.
- **Checked** at 1280, 1000 and 390px, dark and light: no horizontal scroll (`min-width: 0` on the grid columns lets long words shrink). Sections set only their top and bottom padding (`padding-top`/`padding-bottom`), never `padding: X 0`, which would wipe `.wrap`'s side padding.

## 4. Sections and copy

Final copy, in order. Every claim is true of v4.

### Header

KANNA · plan · model · desk · connected · github · discord

### Hero

- **Chip** (green dot): Kanna 4 for macOS
- **h1:** Build software you understand, *(in `--text-2`:)* at a pace you can sustain, while having fun.
- **Bars:** a short and a long `--hot` bar and a green dot, as the icon's top row.
- **Pitch:** Kanna is a software development platform for working with coding agents. It keeps you connected to your code, engaged in the work, and sane.
- **Buttons:** Apple Silicon (primary) · Intel
- **Version line:** Requires macOS 15 or later (becomes `v4.0.0 · Requires macOS 15 or later`, [§6](#6-behaviour))
- **Screenshot:** desk

### 01 · plan (`--hot`)

- **h2:** Better tasks, up front.
- **Lead:** Most tools hand you a prompt box. In Kanna, the planning agent helps you write better task prompts.
- **Body:** Each task starts with enough detail to go from idea to production code, often in one go. You're still the bottleneck, but for design decisions, not for reviewing PRs.
- **Screenshot:** plan

### 02 · model (`--pink`)

- **h2:** See it before it's built.
- **Lead:** Agents are great at toy examples. Hardened code takes longer. So each task starts with a model of the feature: a mockup or a prototype, with a markdown spec beside it. We call it reference-driven development.
- **Cards** (three across):
  - **02.1 Iterate on the model.** A mockup changes in minutes, so you can try ideas fast without building them for real.
  - **02.2 Mark it up together.** Comment on the spec, the mockup or the prototype, and the agent refines it with you.
  - **02.3 Approve, then build.** Once you approve the model, the agent writes the production code to match it.
- **Screenshot:** model

### 03 · desk (`--purple`, `--purple`, `--indigo`)

- **h2:** Three tasks on your Desk. The rest in the background.
- **Lead:** Watching ten agents at once is like drinking ten shots of espresso. Jumping from task to task feels fast, but you're spinning your wheels. Real work takes real concentration, and getting into flow takes time. So Kanna keeps you on one task and keeps the switching to a minimum.
- **Cards:**
  - **03.1 A Desk of three.** The task you're on, and two more on the Shelf. That's the limit, on purpose.
  - **03.2 The backlog works while you do.** Agents work through your backlog in the background, and stop when they're done or need you.
  - **03.3 Results, presented.** *(full width)* Call a task up to your Desk and its agent has laid out what it did: the spec, the model, the diff, its notes. Agents choose which windows, tabs and docs to show you.
- **Screenshot:** presenting

### 04 · connected (`--bv` ×4)

- **h2:** Stay connected to your codebase.
- **Lead:** Even when agents write most of it, it's still your code.
- **Cards:**
  - **04.1 Explained on the lines.** Agents explain their changes with notes on the lines, shown in Kanna, never added to your code.
  - **04.2 A daily quiz.** Take a break with a daily quiz on how your codebase actually works. Your results are kept, so later quizzes focus on your weak spots.
- **Screenshots:** code, then quiz

### Closing

- **h2:** Kanna: enjoy coding again.
- **Lead:** Download it for your Mac.
- **Buttons:** Apple Silicon (primary) · Intel, and the version line
- **Small print:** Works with Claude Code, Codex and other agent CLIs. Source available under FSL-1.1-MIT: each release becomes MIT two years after it ships.
- **Links:** Source on GitHub → (`https://github.com/tampopogk/kanna`) · Join the Discord → (`https://discord.gg/WpT5N9kWa`)

### Footer

- **Left:** KANNA · SOURCE AVAILABLE · © TAMPOPO LLC, with SOURCE AVAILABLE linking `https://github.com/tampopogk/kanna/blob/main/LICENSE`
- **Right:** DISCORD · SUPPORT (`/support/`) · PRIVACY (`/privacy/`)

## 5. Screenshots

Real captures of Kanna 4.0.0 by `tools/capture` (a private Kanna running real Claude agents on a demo repo, `tidetable`), 2560×1600, AVIF, in `assets/`. Each comes in light (`kanna-v4-NAME.avif`) and dark (`kanna-v4-NAME-dark.avif`), and the page shows the one matching its appearance, with no script:

```html
<picture>
  <source srcset="assets/kanna-v4-desk-dark.avif" media="(prefers-color-scheme: dark)">
  <img src="assets/kanna-v4-desk.avif" width="2560" height="1600" alt="…">
</picture>
```

With no preference the browser reports light, so the light shot loads on a light page. `width="2560" height="1600"` on every `<img>`; the hero's loads eagerly with `fetchpriority="high"`, the rest lazily.

| Where | NAME | Shows | Caption | Captured |
|---|---|---|---|---|
| Hero | `desk` | The Desk with no task: the planning agent summing up what's running and offering a quiz, beside the Shelf (three tasks) and backlog (one blocked) | The planning agent beside the Shelf: three tasks on it, the backlog below, one task blocked. | light, dark |
| 01 plan | `plan` | The planning agent helping write a task prompt: the user asks for a king-tide heads-up, and the agent asks how it should be delivered before writing the task | The planning agent turns what you want into a task an agent can finish in one go. | light, dark |
| 02 model | `model` | "Mock up the day page" presenting its mockup, with a markup thread: the user asks where the tide is now, the agent's reply says what it added | The model, marked up: you comment, the agent answers and refines it. | light, dark |
| 03 desk | `presenting` | "Fix DST gap in daily tides" called up to the Desk: its agent's summary beside the diff it opened | Called up to the Desk: the task explains its fix, with the diff open beside it. | light, dark |
| 04 connected | `code` | A code walk-through: the agent's note above `harmonics.ts:35–44`, the rest dimmed | A walk through the code, one note at a time. | light, dark |
| 04 connected | `quiz` | The Quiz window after a miss: a spot-the-bug question, the code open at the line with the explanation | The daily quiz: miss one and the code opens at the line. | light, dark |

Alt text for each is in the mockup.

## 6. Behaviour

- **Downloads:** the existing GitHub releases fetch, unchanged in substance: `GET https://api.github.com/repos/tampopogk/kanna/releases/latest`, the `.dmg` asset matching `arm64|apple.?silicon` for every Apple Silicon button and `x86|intel` for every Intel button, and the tag prefixed to every version line (`v4.0.0 · Requires macOS 15 or later`). On failure the page keeps working: the buttons' `href` starts as `https://github.com/tampopogk/kanna/releases/latest` rather than `#`. v4.0.0 ships `Kanna-4.0.0-arm64.dmg` and `Kanna-4.0.0-x86_64.dmg`.
- **No other script.** The mockup's page switch (system, dark, light; bottom right) is for previewing, not for the page: the page follows the system only.
- **Motion:** button hover lifts 1px; nothing else moves.
- **Meta:** update `<title>` and the description to the new pitch; drop the old Tauri-era description.

## 7. Removed

From the current page: Linux downloads and install notes; Kanna Mobile and the App Store QR; pricing and the relay; stages, workflows, agent-per-stage, subtasks, the task manager, pairing Macs; the old screenshot carousel and lightbox, and its images in `assets/` (`kanna-tasks`, `-diff`, `-commit-graph`, `-command-palette`, `-file-explorer`, `-ios-notifications`, `-mobile-*`); "OPEN SOURCE" and "BRING YOUR OWN MODEL" in the footer.

Considered and cut while writing the copy: terminals that outlive the app ("a pretty standard feature these days"); a separate Fun section (fun is now the model loop and the closing line); CLI examples; the pane types list.

## 8. Rules

- **Never present a hand-built or simulated UI as a screenshot.** Only real captures; a missing one keeps a labelled placeholder until it exists.
- **Light and dark:** both, following the system (decided 2026-10-16). A new screenshot needs both captures.
- **Don't tell people what every agent does** ("reads your code"); say what Kanna does differently.
- **Order:** don't mention mockups or prototypes before 02 introduces reference-driven development.
