import { heightAt, predict, type Constituent } from "./harmonics.ts";

export interface Extreme {
  kind: "high" | "low";
  time: Date;
  height: number;
}

/**
 * High and low water between `start` and `end`: where the predicted curve turns.
 * Sampled every six minutes, then each turn is refined by fitting a parabola
 * through the sample and its neighbours, which puts it within a few seconds.
 */
export function extremes(datum: number, constituents: Constituent[], start: Date, end: Date): Extreme[] {
  const step = 6;
  // One step either side, so a turn right at the window's edge is still seen.
  const from = new Date(start.getTime() - step * 60_000);
  const to = new Date(end.getTime() + step * 60_000);
  const samples = predict(datum, constituents, from, to, step);
  const found: Extreme[] = [];
  for (let i = 1; i < samples.length - 1; i++) {
    const [a, b, c] = [samples[i - 1].height, samples[i].height, samples[i + 1].height];
    const high = b > a && b >= c;
    const low = b < a && b <= c;
    if (!high && !low) continue;
    // Vertex of the parabola through (−1, a), (0, b), (1, c), in steps from b.
    const offset = (a - c) / (2 * (a - 2 * b + c));
    const time = new Date(samples[i].time.getTime() + offset * step * 60_000);
    if (time < start || time >= end) continue;
    found.push({ kind: high ? "high" : "low", time, height: heightAt(datum, constituents, time) });
  }
  return found;
}
