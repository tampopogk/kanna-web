#!/usr/bin/env node
/**
 * Send one follow-up instruction to the running agent session, the way an
 * operator does from the app, so a capture can show the agent mid-flight.
 * Keystrokes go through the terminal's own input path.
 */
import { open, focusWindow, sleep } from "./wd.mjs";

const TASK = process.env.CAPTURE_TASK_ID || "cap-auth-middleware";
const MESSAGE = process.argv[2] || "";
const BACKSPACE = "";

const wd = await open();
try {
  await focusWindow(wd);
  const send = (data) =>
    wd.eval(
      `window.__KANNA_E2E__.terminalBuffers.input(${JSON.stringify(TASK)}, ${JSON.stringify(data)}); return true;`,
    );

  // Clear whatever is sitting in the composer before typing.
  await send(BACKSPACE.repeat(240));
  await sleep(800);

  if (MESSAGE) {
    await send(MESSAGE);
    await sleep(800);
    await send("\r");
    console.log("sent:", MESSAGE);
  } else {
    console.log("composer cleared");
  }
} finally {
  await wd.close();
}
