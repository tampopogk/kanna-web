/** Minimal WebDriver client for the tauri-plugin-webdriver server. */
export const PORT = process.env.KANNA_WEBDRIVER_PORT || "4555";
export const BASE = `http://127.0.0.1:${PORT}`;
export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function call(method, path, body) {
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
  if (!res.ok) throw new Error(`${method} ${path} -> ${res.status} ${text.slice(0, 400)}`);
  return json;
}

export async function open() {
  const status = await fetch(`${BASE}/status`).catch(() => null);
  if (!status?.ok) throw new Error(`No WebDriver on ${BASE}. Start the dev build first.`);
  const session = await call("POST", "/session", { capabilities: {} });
  const sid = session.value?.sessionId || session.sessionId;
  if (!sid) throw new Error("no sessionId in /session response");

  const unwrap = (raw) => {
    const parsed = typeof raw === "string" ? JSON.parse(raw) : raw;
    if (!parsed.ok) throw new Error(`page script failed: ${parsed.error}`);
    return parsed.value;
  };

  return {
    sid,
    async eval(script) {
      const body = `
        try { const __r = (() => { ${script} })();
          return JSON.stringify({ ok: true, value: __r === undefined ? null : __r });
        } catch (e) { return JSON.stringify({ ok: false, error: String(e && e.stack || e) }); }`;
      const res = await call("POST", `/session/${sid}/execute/sync`, { script: body, args: [] });
      return unwrap(res.value ?? res);
    },
    async evalAsync(script) {
      const body = `
        const __done = arguments[arguments.length - 1];
        (async () => { ${script} })().then(
          (v) => __done(JSON.stringify({ ok: true, value: v === undefined ? null : v })),
          (e) => __done(JSON.stringify({ ok: false, error: String(e && e.stack || e) })));`;
      const res = await call("POST", `/session/${sid}/execute/async`, { script: body, args: [] });
      return unwrap(res.value ?? res);
    },
    async screenshot() {
      const res = await call("GET", `/session/${sid}/screenshot`);
      return Buffer.from(res.value ?? res, "base64");
    },
    async close() {
      await call("DELETE", `/session/${sid}`).catch(() => undefined);
    },
  };
}

/**
 * Bring the app window forward.
 *
 * macOS suspends requestAnimationFrame for an occluded webview, and xterm only
 * paints on a frame — so an unfocused window screenshots with an empty
 * terminal pane no matter how much output the session has. Every capture run
 * must do this first.
 */
export async function focusWindow(wd) {
  await wd.evalAsync(`
    const invoke = window.__TAURI_INTERNALS__.invoke;
    await invoke("plugin:window|show", { label: "main" });
    await invoke("plugin:window|set_focus", { label: "main" });
    await invoke("plugin:webview|set_webview_focus", { label: "main" });
    return true;
  `);
  await sleep(1200);
  const state = await wd.eval(`return document.visibilityState;`);
  if (state !== "visible") throw new Error(`window is still ${state}; captures would be blank`);
  return state;
}

export const CLOSE_OVERLAYS = `
  const s = window.__KANNA_E2E__.setupState;
  for (const key of ["showShortcutsModal","showCommandPalette","showAddRepoModal","showPreferencesPanel",
                     "showAnalyticsModal","showDiffModal","showShellModal","showCommitGraphModal",
                     "showTreeExplorer","showFilePickerModal","showFilePreviewModal"]) {
    if (key in s) s[key] = false;
  }
  return true;
`;
