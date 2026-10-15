import { createApp } from "./server.ts";
import { loadStations } from "./stations.ts";

const port = Number(process.env.PORT ?? 8080);
createApp(loadStations()).listen(port, () => {
  console.log(`tidetable listening on http://localhost:${port}`);
});
