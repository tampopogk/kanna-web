import assert from "node:assert/strict";
import { test } from "node:test";
import { EPOCH, heightAt, predict } from "../src/harmonics.ts";

const M2_PERIOD = (360 / 28.9841042) * 3_600_000;

test("a single constituent peaks at its phase lag", () => {
  const m2 = [{ name: "M2", amplitude: 1, phase: 0 }];
  assert.ok(Math.abs(heightAt(2, m2, new Date(EPOCH)) - 3) < 1e-9);
  assert.ok(Math.abs(heightAt(2, m2, new Date(EPOCH + M2_PERIOD / 2)) - 1) < 1e-9);
});

test("M2 repeats every 12.42 hours", () => {
  const m2 = [{ name: "M2", amplitude: 0.6, phase: 205.4 }];
  const t = new Date("2026-10-15T09:00:00Z");
  const later = new Date(t.getTime() + M2_PERIOD);
  assert.ok(Math.abs(heightAt(1, m2, t) - heightAt(1, m2, later)) < 1e-6);
});

test("an unknown constituent is an error, not a silent zero", () => {
  assert.throws(() => heightAt(0, [{ name: "Q9", amplitude: 1, phase: 0 }], new Date()), /unknown constituent: Q9/);
});

test("predict samples both ends of the window", () => {
  const samples = predict(0, [{ name: "K1", amplitude: 1, phase: 0 }], new Date(EPOCH), new Date(EPOCH + 3_600_000));
  assert.equal(samples.length, 11);
  assert.equal(samples.at(-1)!.time.getTime(), EPOCH + 3_600_000);
});
