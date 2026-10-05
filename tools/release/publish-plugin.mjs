import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { copyFile, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

export const assets = [
  "aresta-windows-x86_64.zip", "aresta-linux-x86_64.tar.gz", "aresta-macos-universal.zip",
  "LEIA-ME.md", "version.txt", "release-manifest.json", "CHANGELOG.md",
];

export async function verifyRelease(_config, context) {
  const plan = JSON.parse(await readFile(path.join(context.cwd, ".release/plan.json"), "utf8"));
  if (!plan.publish || plan.version !== context.nextRelease.version || plan.sourceCommit !== context.nextRelease.gitHead) {
    throw new Error("Plano divergente dos pacotes testados; publicacao bloqueada.");
  }
  const manifest = JSON.parse(await readFile(path.join(context.cwd, "dist/release-manifest.json"), "utf8"));
  if (manifest.version !== plan.version || manifest.sourceCommit !== plan.sourceCommit) {
    throw new Error("Manifesto nao corresponde ao plano testado.");
  }
  if ((await readFile(path.join(context.cwd, "dist/version.txt"), "utf8")).trim() !== plan.version) {
    throw new Error("Versao dos downloads diverge do runtime testado.");
  }
}

export async function prepare(_config, context) {
  await writeFile(path.join(context.cwd, "VERSION"), context.nextRelease.version + "\n");
  await copyFile(path.join(context.cwd, "CHANGELOG.md"), path.join(context.cwd, "dist/CHANGELOG.md"));
  await writeFile(path.join(context.cwd, ".release/publish-notes.md"),
    context.nextRelease.notes + "\n\n---\n\n" + await readFile(path.join(context.cwd, "docs/playtest-publico.md"), "utf8"));
  const hashes = [];
  for (const file of assets) {
    const bytes = await readFile(path.join(context.cwd, "dist", file));
    hashes.push(`${createHash("sha256").update(bytes).digest("hex")}  ${file}`);
  }
  await writeFile(path.join(context.cwd, "dist/SHA256SUMS.txt"), hashes.join("\n") + "\n");
}

export async function publish(_config, context) {
  const files = [...assets, "SHA256SUMS.txt"].map(file => path.join("dist", file));
  execFileSync("gh", ["release", "create", context.nextRelease.gitTag, ...files,
    "--verify-tag", "--prerelease", "--title", `Aresta ${context.nextRelease.version} - Playtest`,
    "--notes-file", ".release/publish-notes.md"], { cwd: context.cwd, stdio: "inherit" });
  return { name: "GitHub Playtest", url: `https://github.com/matheus013/torre-das-cem-marcas/releases/tag/${context.nextRelease.gitTag}` };
}
