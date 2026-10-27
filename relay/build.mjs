// Baut relay/dist/worker.js: eine einzelne Datei zum Einfügen im Cloudflare-Dashboard (ohne Terminal).
// Inhalt = src/core.js + src/worker.js (ohne dessen Import-Zeile). Aufruf: node build.mjs
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";

const core = readFileSync(new URL("./src/core.js", import.meta.url), "utf8");
const worker = readFileSync(new URL("./src/worker.js", import.meta.url), "utf8").replace(
  /^import \{[^}]+\} from "\.\/core\.js";\n/m,
  ""
);
const out =
  "// GENERIERT von relay/build.mjs – nicht von Hand bearbeiten. Quelle: relay/src/\n" +
  "// Komplett kopieren und im Cloudflare-Dashboard in den Worker-Editor einfügen.\n\n" +
  core.replace(/^export (const|function) /gm, "$1 ") +
  "\n" +
  worker;
mkdirSync(new URL("./dist/", import.meta.url), { recursive: true });
writeFileSync(new URL("./dist/worker.js", import.meta.url), out);
console.log("dist/worker.js", out.length, "Zeichen");
