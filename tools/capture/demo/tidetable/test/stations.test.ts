import assert from "node:assert/strict";
import { test } from "node:test";
import { SPEEDS } from "../src/harmonics.ts";
import { loadStations } from "../src/stations.ts";

test("every bundled station loads and uses known constituents", () => {
  const stations = loadStations();
  assert.ok(stations.size >= 5);
  for (const station of stations.values()) {
    for (const c of station.constituents) assert.ok(c.name in SPEEDS, `${station.id}: ${c.name}`);
    assert.doesNotThrow(() => new Intl.DateTimeFormat("en", { timeZone: station.timeZone }));
  }
});
