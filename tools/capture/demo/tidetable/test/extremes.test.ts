import assert from "node:assert/strict";
import { test } from "node:test";
import { extremes } from "../src/extremes.ts";
import { loadStations } from "../src/stations.ts";

const HOUR = 3_600_000;

test("a pure M2 tide has two highs and two lows a day, alternating", () => {
  const m2 = [{ name: "M2", amplitude: 1, phase: 0 }];
  const start = new Date("2026-10-15T00:00:00Z");
  const found = extremes(0, m2, start, new Date(start.getTime() + 24 * HOUR));
  assert.ok(found.length === 3 || found.length === 4, `${found.length} turns`);
  for (let i = 1; i < found.length; i++) assert.notEqual(found[i].kind, found[i - 1].kind);
  for (let i = 2; i < found.length; i++) {
    const gap = found[i].time.getTime() - found[i - 2].time.getTime();
    assert.ok(Math.abs(gap - 12.42 * HOUR) < 60_000, `high to high ${gap / HOUR}h`);
  }
});

test("Golden Gate has a higher high water and a lower high water", () => {
  const sf = loadStations().get("sf-golden-gate")!;
  const start = new Date("2026-10-15T07:00:00Z");
  const highs = extremes(sf.datum, sf.constituents, start, new Date(start.getTime() + 24 * HOUR)).filter((e) => e.kind === "high");
  assert.equal(highs.length, 2);
  assert.ok(Math.abs(highs[0].height - highs[1].height) > 0.1, "mixed tide: the two highs differ");
});

test("turns outside the window are left out", () => {
  const m2 = [{ name: "M2", amplitude: 1, phase: 0 }];
  const start = new Date("2026-10-15T00:00:00Z");
  for (const e of extremes(0, m2, start, new Date(start.getTime() + 6 * HOUR))) {
    assert.ok(e.time >= start && e.time.getTime() < start.getTime() + 6 * HOUR);
  }
});
