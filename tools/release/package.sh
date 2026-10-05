#!/bin/sh
set -eu

cd "$(dirname "$0")/../.."
mkdir -p dist
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT INT TERM
for platform in windows linux; do
    folder="aresta-${platform}-x86_64"
    mkdir -p "$stage/$folder"
    cp builds/"$platform"/* "$stage/$folder/"
    cp docs/playtest-publico.md "$stage/$folder/LEIA-ME.md"
    cp CHANGELOG.md "$stage/$folder/CHANGELOG.md"
done
chmod +x "$stage/aresta-linux-x86_64/aresta.x86_64"
root="$(pwd)"
rm -f dist/aresta-windows-x86_64.zip dist/aresta-linux-x86_64.tar.gz dist/aresta-macos-universal.zip
(cd "$stage" && zip -qr "$root/dist/aresta-windows-x86_64.zip" aresta-windows-x86_64)
tar -czf dist/aresta-linux-x86_64.tar.gz -C "$stage" aresta-linux-x86_64
cp builds/macos/aresta.zip dist/aresta-macos-universal.zip
cp docs/playtest-publico.md "$stage/LEIA-ME.md"
zip -qj dist/aresta-macos-universal.zip "$stage/LEIA-ME.md" builds/macos/source-commit.txt builds/macos/engine-version.txt builds/macos/version.txt CHANGELOG.md
cp docs/playtest-publico.md dist/LEIA-ME.md
cp VERSION dist/version.txt
cp CHANGELOG.md dist/CHANGELOG.md
if [ -f .release/plan.json ]; then
    cp .release/plan.json dist/release-manifest.json
else
    node --input-type=module -e 'import fs from "node:fs"; import {execFileSync} from "node:child_process"; process.stdout.write(JSON.stringify({version: fs.readFileSync("VERSION", "utf8").trim(), sourceCommit: execFileSync("git", ["rev-parse", "HEAD"], {encoding:"utf8"}).trim()}, null, 2) + "\n")' > dist/release-manifest.json
fi
if command -v sha256sum >/dev/null 2>&1; then
    (cd dist && sha256sum aresta-windows-x86_64.zip aresta-linux-x86_64.tar.gz aresta-macos-universal.zip LEIA-ME.md version.txt CHANGELOG.md release-manifest.json > SHA256SUMS.txt)
else
    (cd dist && shasum -a 256 aresta-windows-x86_64.zip aresta-linux-x86_64.tar.gz aresta-macos-universal.zip LEIA-ME.md version.txt CHANGELOG.md release-manifest.json > SHA256SUMS.txt)
fi
