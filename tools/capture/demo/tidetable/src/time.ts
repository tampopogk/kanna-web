const DAY = 86_400_000;

/** Minutes the zone is ahead of UTC at `instant`. */
function offsetMinutes(timeZone: string, instant: Date): number {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  }).formatToParts(instant);
  const get = (type: string) => Number(parts.find((p) => p.type === type)!.value);
  const local = Date.UTC(get("year"), get("month") - 1, get("day"), get("hour"), get("minute"), get("second"));
  return Math.round((local - instant.getTime()) / 60_000);
}

/** The instant local midnight starts `date` (YYYY-MM-DD) in `timeZone`. */
export function localMidnight(date: string, timeZone: string): Date {
  const [y, m, d] = date.split("-").map(Number);
  const utcMidnight = Date.UTC(y, m - 1, d);
  // Guess with the offset at UTC midnight, then correct once in case the
  // zone's offset at local midnight is different.
  let guess = utcMidnight - offsetMinutes(timeZone, new Date(utcMidnight)) * 60_000;
  guess = utcMidnight - offsetMinutes(timeZone, new Date(guess)) * 60_000;
  return new Date(guess);
}

/** The window a station's daily tides are reported for: its local day. */
export function localDayBounds(date: string, timeZone: string): { start: Date; end: Date } {
  const start = localMidnight(date, timeZone);
  return { start, end: new Date(start.getTime() + DAY) };
}

/** "06:42", in the station's local time. */
export function formatLocalTime(instant: Date, timeZone: string): string {
  return new Intl.DateTimeFormat("en-GB", { timeZone, hour: "2-digit", minute: "2-digit", hourCycle: "h23" }).format(instant);
}

export function isDate(value: string): boolean {
  return /^\d{4}-\d{2}-\d{2}$/.test(value) && !Number.isNaN(Date.parse(value));
}
