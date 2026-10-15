import { readFileSync } from "node:fs";
import type { Constituent } from "./harmonics.ts";

export interface Station {
  id: string;
  name: string;
  /** IANA zone the station's local day is counted in. */
  timeZone: string;
  lat: number;
  lon: number;
  /** Mean water level above chart datum (MLLW), in metres. */
  datum: number;
  constituents: Constituent[];
}

const DATA = new URL("../data/stations.json", import.meta.url);

export function loadStations(file: URL | string = DATA): Map<string, Station> {
  const list = JSON.parse(readFileSync(file, "utf8")) as Station[];
  const stations = new Map<string, Station>();
  for (const station of list) {
    if (stations.has(station.id)) throw new Error(`duplicate station id: ${station.id}`);
    if (station.constituents.length === 0) throw new Error(`${station.id} has no constituents`);
    stations.set(station.id, station);
  }
  return stations;
}
