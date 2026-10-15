import assert from "node:assert/strict";
import { test } from "node:test";
import { formatLocalTime, isDate, localDayBounds, localMidnight } from "../src/time.ts";

test("local midnight in a zone behind UTC", () => {
  assert.equal(localMidnight("2026-10-15", "America/Los_Angeles").toISOString(), "2026-10-15T07:00:00.000Z");
  assert.equal(localMidnight("2026-01-15", "America/New_York").toISOString(), "2026-01-15T05:00:00.000Z");
});

test("an ordinary day is 24 hours", () => {
  const { start, end } = localDayBounds("2026-10-15", "Pacific/Honolulu");
  assert.equal(start.toISOString(), "2026-10-15T10:00:00.000Z");
  assert.equal(end.getTime() - start.getTime(), 86_400_000);
});

test("times are reported in the station's zone", () => {
  assert.equal(formatLocalTime(new Date("2026-10-15T13:42:00Z"), "America/Los_Angeles"), "06:42");
});

test("dates are YYYY-MM-DD", () => {
  assert.ok(isDate("2026-10-15"));
  assert.ok(!isDate("15/10/2026"));
  assert.ok(!isDate("2026-13-01"));
});
