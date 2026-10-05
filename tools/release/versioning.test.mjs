import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { createHash } from "node:crypto";
import { analyzeCommits } from "@semantic-release/commit-analyzer";
import { generateNotes } from "@semantic-release/release-notes-generator";
import { analyzer, notes } from "../../release.config.mjs";
import { assets, prepare, verifyRelease } from "./publish-plugin.mjs";

const logger = { log() {} };
for (const [message, expected] of [
  ["feat: add a mechanic", "minor"], ["fix: preserve loot", "patch"],
  ["perf: reduce snapshots", "patch"], ["ci: improve exports", "patch"],
  ["build: package game", "patch"], ["feat!: change saves", "major"],
  ["fix: migrate\n\nBREAKING CHANGE: old format removed", "major"],
  ["docs: explain controls", null], ["chore(release): 0.2.0 [skip ci]", null],
]) {
  test(`release type: ${message.split("\n")[0]}`, async () => {
    assert.equal(await analyzeCommits(analyzer, { cwd: process.cwd(), commits: [{ message }], logger }), expected);
  });
}

test("changelog includes version, sections and commit links", async () => {
  const text = await generateNotes(notes, {
    cwd: process.cwd(), logger,
    options: { repositoryUrl: "https://github.com/matheus013/torre-das-cem-marcas.git" },
    commits: [{ message: "feat: add support", hash: "a".repeat(40) }, { message: "fix: keep loot", hash: "b".repeat(40) }],
    lastRelease: { version: "0.1.0", gitTag: "v0.1.0" },
    nextRelease: { version: "0.2.0", gitTag: "v0.2.0" },
  });
  assert.match(text, /0\.2\.0/);
  assert.match(text, /Novidades/);
  assert.match(text, /Correcoes/);
  assert.match(text, /compare\/v0\.1\.0\.\.\.v0\.2\.0/);
});

test("publication verifies tested source/version and checksums every asset", async () => {
  const cwd = await mkdtemp(path.join(tmpdir(), "aresta-version-test-"));
  try {
    for (const folder of [".release", "dist", "docs"]) await mkdir(path.join(cwd, folder));
    const plan = { publish: true, version: "0.2.0", sourceCommit: "a".repeat(40) };
    await writeFile(path.join(cwd, ".release/plan.json"), JSON.stringify(plan));
    await writeFile(path.join(cwd, "CHANGELOG.md"), "# Changelog\n0.2.0\n");
    await writeFile(path.join(cwd, "docs/playtest-publico.md"), "Playtest only.\n");
    for (const file of assets) await writeFile(path.join(cwd, "dist", file), file + "\n");
    await writeFile(path.join(cwd, "dist/release-manifest.json"), JSON.stringify(plan));
    await writeFile(path.join(cwd, "dist/version.txt"), plan.version + "\n");
    const context = { cwd, nextRelease: { version: plan.version, gitHead: plan.sourceCommit, notes: "Changes." } };
    await verifyRelease({}, context);
    await assert.rejects(verifyRelease({}, { ...context, nextRelease: { ...context.nextRelease, version: "0.3.0" } }));
    await assert.rejects(verifyRelease({}, { ...context, nextRelease: { ...context.nextRelease, gitHead: "b".repeat(40) } }));
    await prepare({}, context);
    assert.equal(await readFile(path.join(cwd, "VERSION"), "utf8"), "0.2.0\n");
    assert.match(await readFile(path.join(cwd, ".release/publish-notes.md"), "utf8"), /Changes\.[\s\S]*Playtest only/);
    const lines = (await readFile(path.join(cwd, "dist/SHA256SUMS.txt"), "utf8")).trim().split("\n");
    assert.equal(lines.length, assets.length);
    for (const line of lines) {
      const [hash, file] = line.split("  ");
      assert.equal(hash, createHash("sha256").update(await readFile(path.join(cwd, "dist", file))).digest("hex"));
    }
  } finally {
    await rm(cwd, { recursive: true, force: true });
  }
});
