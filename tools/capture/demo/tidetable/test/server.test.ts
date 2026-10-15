import assert from "node:assert/strict";
import type { AddressInfo } from "node:net";
import { after, before, test } from "node:test";
import { createApp } from "../src/server.ts";
import { loadStations } from "../src/stations.ts";

const app = createApp(loadStations());
let base = "";

before(async () => {
  await new Promise<void>((resolve) => app.listen(0, resolve));
  base = `http://localhost:${(app.address() as AddressInfo).port}`;
});
after(() => app.close());

test("GET /stations lists every station", async () => {
  const res = await fetch(`${base}/stations`);
  assert.equal(res.status, 200);
  const body = (await res.json()) as { id: string }[];
  assert.ok(body.some((s) => s.id === "the-battery"));
});

test("GET /stations/:id/tides gives the day's highs and lows in local time", async () => {
  const res = await fetch(`${base}/stations/seattle/tides?date=2026-10-15`);
  assert.equal(res.status, 200);
  const body = (await res.json()) as { tides: { kind: string; local: string }[] };
  assert.ok(body.tides.length >= 3 && body.tides.length <= 5);
  for (const tide of body.tides) assert.match(tide.local, /^\d{2}:\d{2}$/);
});

test("bad requests say what's wrong", async () => {
  assert.equal((await fetch(`${base}/stations/atlantis/tides`)).status, 404);
  assert.equal((await fetch(`${base}/stations/boston/tides?date=tomorrow`)).status, 400);
});
