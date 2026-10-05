import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(new URL("./import.sh", import.meta.url));
for (const [name, output, exitCode, expected] of [
  ["clean import", "Import complete", 0, 0],
  ["warning only", "WARNING: optional resource", 0, 0],
  ["resource error with zero status", "ERROR: resource missing", 0, 1],
  ["parser error with zero status", "SCRIPT ERROR: Parse Error", 0, 1],
  ["colored error with zero status", "\u001b[31mERROR: resource missing\u001b[0m", 0, 1],
  ["nonzero status", "Import failed", 7, 7],
]) {
  test(`import gate: ${name}`, async () => {
    const folder = await mkdtemp(path.join(tmpdir(), "aresta-import-test-"));
    try {
      const binary = path.join(folder, "godot");
      await writeFile(binary, `#!/bin/sh\nprintf '%s\\n' '${output}'\nexit ${exitCode}\n`, { mode: 0o700 });
      const result = spawnSync("sh", [script], { env: { ...process.env, GODOT_BIN: binary }, encoding: "utf8" });
      assert.equal(result.status, expected, result.stderr);
      assert.ok(result.stdout.includes(output));
    } finally {
      await rm(folder, { recursive: true, force: true });
    }
  });
}
