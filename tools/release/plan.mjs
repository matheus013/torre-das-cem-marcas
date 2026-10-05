import { appendFile, mkdir, readFile, writeFile } from "node:fs/promises";
import { execFileSync } from "node:child_process";
import semanticRelease from "semantic-release";
import { prepare as prepareChangelog } from "@semantic-release/changelog";
import config, { analyzer, notes } from "../../release.config.mjs";

const result = await semanticRelease({
  ...config,
  dryRun: true,
  plugins: [
    ["@semantic-release/commit-analyzer", analyzer],
    ["@semantic-release/release-notes-generator", notes],
  ],
});
const sourceCommit = execFileSync("git", ["rev-parse", "HEAD"], { encoding: "utf8" }).trim();
const version = result ? result.nextRelease.version : (await readFile("VERSION", "utf8")).trim();
const plan = { publish: Boolean(result), version, tag: `v${version}`, sourceCommit };
await mkdir(".release", { recursive: true });
if (result) {
  await prepareChangelog({ changelogFile: "CHANGELOG.md", changelogTitle: "# Changelog" }, {
    ...result,
    cwd: process.cwd(),
    logger: { log: () => {} },
  });
}
await writeFile(".release/plan.json", JSON.stringify(plan, null, 2) + "\n");
await writeFile(".release/VERSION", version + "\n");
await writeFile(".release/CHANGELOG.md", await readFile("CHANGELOG.md"));
await writeFile(".release/release-notes.md", result ? result.nextRelease.notes : "Sem mudancas publicaveis.\n");
if (process.env.GITHUB_OUTPUT) {
  await appendFile(process.env.GITHUB_OUTPUT, `publish=${plan.publish}\nversion=${version}\n`);
}
