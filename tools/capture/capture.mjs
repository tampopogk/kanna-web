#!/usr/bin/env node
/**
 * Marketing capture harness for the Kanna homepage.
 *
 * Drives a Kanna *debug* build over the WebDriver server that
 * tauri-plugin-webdriver exposes (it is compiled in under
 * #[cfg(debug_assertions)] only, which is why the installed release app
 * cannot be driven and a dev build is required).
 *
 * This captures the real application UI. It is not a mock, a facsimile, or a
 * composite: every pixel comes from the shipped frontend rendering state the
 * app genuinely produces, seeded from ./seed.sql.
 *
 * Usage:
 *   KANNA_WEBDRIVER_PORT=4555 node tools/capture/capture.mjs
 *
 * Writes PNGs to .tmp/capture/. Run convert.sh afterwards to produce the
 * AVIF files that the page actually references.
 */
import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";

const PORT = process.env.KANNA_WEBDRIVER_PORT || "4555";
const BASE = `http://127.0.0.1:${PORT}`;
const OUT = process.env.CAPTURE_OUT || ".tmp/capture";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function wd(method, path, body) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: { "Content-Type": "application/json" },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch {
    throw new Error(`${method} ${path} -> non-JSON: ${text.slice(0, 200)}`);
  }
  if (!res.ok) throw new Error(`${method} ${path} -> ${res.status} ${text.slice(0, 200)}`);
  return json;
}

/**
 * Each shot names the file it produces and the UI state to reach first.
 * `setup` runs in the page; keep it to things a user can actually do.
 */
/**
 * The app opens a keyboard-shortcuts overlay on a fresh profile. Dismiss it
 * before capturing, the same way a person would.
 */
const DISMISS_OVERLAYS = `
  for (let i = 0; i < 3; i += 1) {
    document.dispatchEvent(new KeyboardEvent('keydown', {
      key: 'Escape', code: 'Escape', bubbles: true, cancelable: true
    }));
  }
`;

const SHOTS = [
  {
    name: "tasks",
    description: "Task list across repositories with an agent working",
    setup: `window.scrollTo(0,0);`,
    settle: 1200,
  },
  {
    name: "command-palette",
    description: "Command palette open over the task view",
    setup: `
      const ev = new KeyboardEvent('keydown', {
        key: 'k', code: 'KeyK', metaKey: true, bubbles: true, cancelable: true
      });
      document.dispatchEvent(ev);
    `,
    settle: 900,
  },
];

async function main() {
  await mkdir(OUT, { recursive: true });

  const status = await fetch(`${BASE}/status`).catch(() => null);
  if (!status?.ok) {
    console.error(
      [
        `No WebDriver on ${BASE}.`,
        "Start a Kanna debug build with an isolated database and daemon dir, e.g.",
        "  KANNA_WEBDRIVER_PORT=4555 \\",
        "  KANNA_DAEMON_DIR=<scratch>/daemon \\",
        "  ./kd dev up --db kanna-capture.db --delete-db --daemon-dir <scratch>/daemon",
        "then seed it (see README.md) and re-run this script.",
      ].join("\n")
    );
    process.exit(1);
  }

  const session = await wd("POST", "/session", { capabilities: {} });
  const sid = session.value?.sessionId || session.sessionId;
  if (!sid) throw new Error("no sessionId in /session response");

  try {
    await wd("POST", `/session/${sid}/execute/sync`, { script: DISMISS_OVERLAYS, args: [] });
    await sleep(600);
    for (const shot of SHOTS) {
      if (shot.setup) {
        await wd("POST", `/session/${sid}/execute/sync`, { script: shot.setup, args: [] });
      }
      await sleep(shot.settle ?? 800);
      const res = await wd("GET", `/session/${sid}/screenshot`);
      const b64 = res.value ?? res;
      const file = join(OUT, `${shot.name}.png`);
      await writeFile(file, Buffer.from(b64, "base64"));
      console.log(`captured ${file}  (${shot.description})`);
    }
  } finally {
    await wd("DELETE", `/session/${sid}`).catch(() => undefined);
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
