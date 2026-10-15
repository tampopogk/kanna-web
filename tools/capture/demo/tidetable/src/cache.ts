/**
 * A small LRU cache whose entries also expire. Predictions for a station and
 * day never change, but the cache is bounded so a crawler walking every date
 * can't grow it without limit.
 */
export class Cache<V> {
  private entries = new Map<string, { value: V; expires: number }>();
  private size: number;
  private ttl: number;
  private now: () => number;

  constructor(size: number, ttlMs: number, now: () => number = Date.now) {
    this.size = size;
    this.ttl = ttlMs;
    this.now = now;
  }

  get(key: string): V | undefined {
    const entry = this.entries.get(key);
    if (!entry) return undefined;
    if (entry.expires <= this.now()) {
      this.entries.delete(key);
      return undefined;
    }
    // Re-insert so iteration order is least recently used first.
    this.entries.delete(key);
    this.entries.set(key, entry);
    return entry.value;
  }

  set(key: string, value: V): void {
    this.entries.delete(key);
    this.entries.set(key, { value, expires: this.now() + this.ttl });
    while (this.entries.size > this.size) {
      const oldest = this.entries.keys().next().value as string;
      this.entries.delete(oldest);
    }
  }

  get length(): number {
    return this.entries.size;
  }
}
