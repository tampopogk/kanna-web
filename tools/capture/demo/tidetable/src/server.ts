import { createServer, type IncomingMessage, type Server, type ServerResponse } from "node:http";
import { Cache } from "./cache.ts";
import { extremes } from "./extremes.ts";
import type { Station } from "./stations.ts";
import { formatLocalTime, isDate, localDayBounds } from "./time.ts";

export interface DailyTide {
  kind: "high" | "low";
  time: string;
  local: string;
  height: number;
}

export function dailyTides(station: Station, date: string): DailyTide[] {
  const { start, end } = localDayBounds(date, station.timeZone);
  return extremes(station.datum, station.constituents, start, end).map((e) => ({
    kind: e.kind,
    time: e.time.toISOString(),
    local: formatLocalTime(e.time, station.timeZone),
    height: Math.round(e.height * 100) / 100,
  }));
}

function send(res: ServerResponse, status: number, body: unknown): void {
  res.writeHead(status, { "content-type": "application/json" });
  res.end(JSON.stringify(body));
}

export function createApp(stations: Map<string, Station>): Server {
  const cache = new Cache<DailyTide[]>(2_000, 6 * 3_600_000);

  return createServer((req: IncomingMessage, res: ServerResponse) => {
    const url = new URL(req.url ?? "/", "http://localhost");
    if (req.method !== "GET") return send(res, 405, { error: "only GET is supported" });

    if (url.pathname === "/stations") {
      return send(res, 200, [...stations.values()].map(({ id, name, timeZone }) => ({ id, name, timeZone })));
    }

    const match = url.pathname.match(/^\/stations\/([a-z0-9-]+)\/tides$/);
    if (match) {
      const station = stations.get(match[1]);
      if (!station) return send(res, 404, { error: `no station ${match[1]}` });
      const date = url.searchParams.get("date") ?? new Date().toISOString().slice(0, 10);
      if (!isDate(date)) return send(res, 400, { error: "date must be YYYY-MM-DD" });

      const key = `${station.id}/${date}`;
      let tides = cache.get(key);
      if (!tides) {
        tides = dailyTides(station, date);
        cache.set(key, tides);
      }
      return send(res, 200, { station: station.id, date, timeZone: station.timeZone, tides });
    }

    send(res, 404, { error: "not found" });
  });
}
