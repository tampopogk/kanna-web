#!/usr/bin/env node
/**
 * Bring the seeded capture instance to the state the screenshots are taken in:
 * the feature task selected and a real agent session running in its worktree.
 *
 * Nothing here fabricates UI. It reloads the app, brings its window forward,
 * selects a task through the app's own store, and starts the task's agent
 * through the same store call the app uses when a task begins. The agent then
 * does real work in a real git worktree.
 */
import { open, focusWindow, sleep, CLOSE_OVERLAYS } from "./wd.mjs";

const TASK = process.env.CAPTURE_TASK_ID || "cap-auth-middleware";
const REPO = process.env.CAPTURE_REPO_ID || "cap-orchard-web";

const wd = await open();
try {
  await wd.eval(`location.reload(); return true;`);
  for (let i = 0; i < 40; i += 1) {
    await sleep(1000);
    const ready = await wd.eval(`return !!(window.__KANNA_E2E__ && window.__KANNA_E2E__.ready);`).catch(() => false);
    if (ready) break;
  }
  console.log("app ready");

  console.log("window:", await focusWindow(wd));

  const dbName = await wd.eval(`return window.__KANNA_E2E__.dbName;`);
  if (!/capture/.test(dbName || "")) throw new Error(`refusing: app is on database "${dbName}"`);
  console.log("database:", dbName);

  await wd.eval(CLOSE_OVERLAYS);
  await sleep(500);

  const worktree = await wd.evalAsync(`
    const s = window.__KANNA_E2E__.setupState;
    await s.store.selectRepo(${JSON.stringify(REPO)});
    await s.store.selectItem(${JSON.stringify(TASK)});
    const item = s.store.items.find((i) => i.id === ${JSON.stringify(TASK)});
    const repo = s.store.repos.find((r) => r.id === item.repo_id);
    return repo.path + "/.kanna-worktrees/" + item.branch;
  `);
  console.log("worktree:", worktree);
  await sleep(1500);
  await wd.eval(CLOSE_OVERLAYS);

  await wd.evalAsync(`
    const s = window.__KANNA_E2E__.setupState;
    const item = s.store.items.find((i) => i.id === ${JSON.stringify(TASK)});
    await s.store.spawnPtySession(${JSON.stringify(TASK)}, ${JSON.stringify(worktree)},
      item.prompt, 150, 40, { agentProvider: item.agent_provider || "claude" });
    return true;
  `);
  console.log("agent session spawned");

  // The agent CLI asks once whether the folder is trusted. Answer it the way a
  // person would — arrow down to "Yes, I trust this folder", then Enter.
  const trustDeadline = Date.now() + 60_000;
  let trusted = false;
  while (Date.now() < trustDeadline) {
    await sleep(2000);
    const lines = await wd.eval(
      `return window.__KANNA_E2E__.terminalBuffers.lines(${JSON.stringify(TASK)}).join("\\n");`,
    ).catch(() => "");
    if (/I trust this folder/.test(lines)) {
      await wd.eval(`window.__KANNA_E2E__.terminalBuffers.input(${JSON.stringify(TASK)}, "\\u001b[B"); return true;`);
      await sleep(600);
      await wd.eval(`window.__KANNA_E2E__.terminalBuffers.input(${JSON.stringify(TASK)}, "\\r"); return true;`);
      trusted = true;
      console.log("answered the workspace trust prompt");
      break;
    }
    if (/bypass permissions|esc to interrupt|❯\s*$/m.test(lines)) break;
  }
  if (!trusted) console.log("no trust prompt (already trusted)");

  console.log("waiting for the agent to produce output…");
  const deadline = Date.now() + 180_000;
  while (Date.now() < deadline) {
    await sleep(5000);
    const lines = await wd.eval(
      `return window.__KANNA_E2E__.terminalBuffers.lines(${JSON.stringify(TASK)}).filter((l) => l.trim()).length;`,
    ).catch(() => 0);
    process.stdout.write(`  ${lines} non-empty lines\n`);
    if (lines > 25) break;
  }
} finally {
  await wd.close();
}
