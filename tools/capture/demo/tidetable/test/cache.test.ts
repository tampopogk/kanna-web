import assert from "node:assert/strict";
import { test } from "node:test";
import { Cache } from "../src/cache.ts";

test("evicts the least recently used entry", () => {
  const cache = new Cache<number>(2, 1_000);
  cache.set("a", 1);
  cache.set("b", 2);
  cache.get("a");
  cache.set("c", 3);
  assert.equal(cache.get("b"), undefined);
  assert.equal(cache.get("a"), 1);
  assert.equal(cache.length, 2);
});

test("entries expire after their ttl", () => {
  let now = 0;
  const cache = new Cache<string>(10, 1_000, () => now);
  cache.set("k", "v");
  now = 999;
  assert.equal(cache.get("k"), "v");
  now = 1_000;
  assert.equal(cache.get("k"), undefined);
  assert.equal(cache.length, 0);
});
