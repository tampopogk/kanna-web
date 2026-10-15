# tidetable

Tide predictions for a handful of coastal stations, computed from each
station's harmonic constants and served as JSON.

```sh
npm start          # http://localhost:8080
npm test           # node --test, no install step
```

Needs Node 23.6 or later, which runs the TypeScript sources directly.

## API

| Request | Returns |
|---|---|
| `GET /stations` | Every station: `id`, `name`, `timeZone` |
| `GET /stations/:id/tides?date=YYYY-MM-DD` | That station's high and low waters for the local day (default: today, UTC), each with its UTC `time`, `local` time and `height` in metres above chart datum |

```json
{
  "station": "sf-golden-gate",
  "date": "2026-10-15",
  "timeZone": "America/Los_Angeles",
  "tides": [
    { "kind": "low", "time": "2026-10-15T08:33:22.358Z", "local": "01:33", "height": 0.44 },
    { "kind": "high", "time": "2026-10-15T15:13:17.029Z", "local": "08:13", "height": 1.96 }
  ]
}
```

## How a prediction is made

The height of the tide is a sum of cosines, one per tidal constituent (the
principal lunar M2, the solar S2, the diurnal K1 and O1, …), each with the
amplitude and phase lag measured for the station (`src/harmonics.ts`).
High and low water are where that curve turns (`src/extremes.ts`). The
constants in `data/stations.json` are approximate and leave out nodal
corrections: good for planning a walk on the beach, not for navigation.
