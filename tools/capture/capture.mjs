#!/usr/bin/env node
/**
 * Marketing capture harness for the Kanna homepage.
 *
 * Drives a Kanna *debug* build over the WebDriver server that
 * tauri-plugin-webdriver exposes (compiled in under #[cfg(debug_assertions)]
 * only, which is why the installed release app cannot be driven).
 *
 * This captures the real application UI. Nothing is mocked, hand-built or
 * composited: every pixel comes from the shipped frontend rendering state the
 * app genuinely produces, over a real daemon PTY session in a real git
 * worktree. Run prepare.mjs first.
 *
 * Usage:
 *   KANNA_WEBDRIVER_PORT=4447 node capture.mjs [shot-name ...]
 */
import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { open, focusWindow, sleep, CLOSE_OVERLAYS } from "./wd.mjs";

const OUT = process.env.CAPTURE_OUT || ".tmp/capture";
const TASK = process.env.CAPTURE_TASK_ID || "cap-auth-middleware";

/**
 * Refuse to capture the task view while the agent composer holds text nobody
 * typed.
 *
 * An idle Claude CLI fills its composer with a tab-to-accept suggestion. That
 * text is provider chrome, and on a homepage it would read as an instruction
 * somebody gave. The check below is why captures are taken while the agent is
 * working: a busy session leaves its composer empty.
 */
const COMPOSER_TEXT = `
  const tb = window.__KANNA_E2E__.terminalBuffers;
  if (!tb || !tb.sessionIds().includes(${JSON.stringify(TASK)})) return "";
  const lines = tb.lines(${JSON.stringify(TASK)});
  const composer = lines.map((l) => l.trim()).filter((l) => l.startsWith("\\u276f"));
  return composer.length ? composer[composer.length - 1].slice(1).trim() : "";
`;

const SHOTS = [
  {
    name: "tasks",
    description:
      "Task list across three repositories with a live agent session in the right pane",
    setup: CLOSE_OVERLAYS,
    settle: 1500,
    guard: COMPOSER_TEXT,
  },
  {
    name: "command-palette",
    description: "Command palette open over the task view",
    setup: `
      const s = window.__KANNA_E2E__.setupState;
      s.showShortcutsModal = false;
      s.keyboardActions.commandPalette();
      return s.showCommandPalette === true;
    `,
    settle: 1400,
    teardown: `window.__KANNA_E2E__.setupState.showCommandPalette = false; return true;`,
  },
  {
    name: "diff",
    description: "Diff view of the agent's changes on the task branch",
    setup: `window.__KANNA_E2E__.setupState.showDiffModal = true; return true;`,
    settle: 4000,
    // Land on a file with edits rather than the first added file, so the shot
    // shows a real before/after rather than a wall of green.
    beforeShot: `
      const scroller = [...document.querySelectorAll("*")]
        .filter((el) => el.scrollHeight > el.clientHeight + 100 && el.clientHeight > 300)
        .sort((a, b) => b.clientHeight - a.clientHeight)[0];
      if (scroller) scroller.scrollTop = Number(${JSON.stringify(process.env.CAPTURE_DIFF_SCROLL || "2600")});
      return scroller ? scroller.scrollTop : -1;
    `,
    teardown: `window.__KANNA_E2E__.setupState.showDiffModal = false; return true;`,
  },
  {
    name: "commit-graph",
    description: "Commit graph for the selected repository",
    setup: `window.__KANNA_E2E__.setupState.showCommitGraphModal = true; return true;`,
    settle: 4000,
    teardown: `window.__KANNA_E2E__.setupState.showCommitGraphModal = false; return true;`,
  },
];

const only = process.argv.slice(2);
await mkdir(OUT, { recursive: true });

const wd = await open();
try {
  const dbName = await wd.eval(`return window.__KANNA_E2E__ ? window.__KANNA_E2E__.dbName : null;`);
  if (!dbName || !/capture/.test(dbName)) {
    throw new Error(`refusing to capture: app is on database "${dbName}", not a capture database`);
  }
  console.log(`database: ${dbName}`);
  console.log(`window: ${await focusWindow(wd)}`);

  for (const shot of SHOTS) {
    if (only.length && !only.includes(shot.name)) continue;
    if (shot.setup) await wd.eval(shot.setup);
    await sleep(shot.settle ?? 800);
    if (shot.guard) {
      const composer = await wd.eval(shot.guard);
      if (composer) {
        throw new Error(
          `refusing to capture "${shot.name}": the agent composer holds untyped text (${JSON.stringify(composer)}). ` +
            `Capture while the agent is working.`,
        );
      }
    }
    if (shot.beforeShot) {
      await wd.eval(shot.beforeShot);
      await sleep(1200);
    }
    const png = await wd.screenshot();
    const file = join(OUT, `${shot.name}.png`);
    await writeFile(file, png);
    console.log(`captured ${file}  (${shot.description})`);
    if (shot.teardown) await wd.eval(shot.teardown);
    await sleep(400);
  }
} finally {
  await wd.close();
}
