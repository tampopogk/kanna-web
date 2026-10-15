// Tide height as a sum of cosines, one per tidal constituent:
//
//   h(t) = Z0 + Σ A·cos(ω·t − g)
//
// t is hours since EPOCH, ω the constituent's speed in degrees per hour, and
// A and g the station's amplitude and phase lag for it. Phases in
// data/stations.json are referred to EPOCH, and nodal corrections (the 18.6-year
// modulation of each constituent) are left out, which keeps a prediction within
// about 10 cm for the next few years.

export const EPOCH = Date.UTC(2000, 0, 1);

/** Speeds in degrees per mean solar hour. */
export const SPEEDS: Record<string, number> = {
  M2: 28.9841042, // principal lunar, semidiurnal
  S2: 30.0, // principal solar, semidiurnal
  N2: 28.4397295, // larger lunar elliptic
  K2: 30.0821373, // lunisolar semidiurnal
  K1: 15.0410686, // lunisolar diurnal
  O1: 13.9430356, // lunar diurnal
  P1: 14.9589314, // solar diurnal
};

export interface Constituent {
  name: string;
  /** Metres. */
  amplitude: number;
  /** Degrees, referred to EPOCH. */
  phase: number;
}

const RAD = Math.PI / 180;
const HOUR = 3_600_000;

export function heightAt(datum: number, constituents: Constituent[], time: Date): number {
  const hours = (time.getTime() - EPOCH) / HOUR;
  let height = datum;
  for (const c of constituents) {
    const speed = SPEEDS[c.name];
    if (speed === undefined) throw new Error(`unknown constituent: ${c.name}`);
    height += c.amplitude * Math.cos(((speed * hours - c.phase) % 360) * RAD);
  }
  return height;
}

export interface Sample {
  time: Date;
  height: number;
}

/** Heights every `stepMinutes` from `start` up to and including `end`. */
export function predict(datum: number, constituents: Constituent[], start: Date, end: Date, stepMinutes = 6): Sample[] {
  const samples: Sample[] = [];
  const step = stepMinutes * 60_000;
  for (let t = start.getTime(); t <= end.getTime(); t += step) {
    const time = new Date(t);
    samples.push({ time, height: heightAt(datum, constituents, time) });
  }
  return samples;
}
